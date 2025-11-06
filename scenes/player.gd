extends CharacterBody2D

const UDP_PORT = 5006  # Godot listens on 5006, Python sends to this port
const PYTHON_RESPONSE_PORT = 5005  # Port to send responses back to Python
const LERP_SPEED = 10.0  # How smoothly the player moves to target position

var udp := PacketPeerUDP.new()
var target_position_percent := 50.0  # Default to middle of screen (vertical)
var target_horizontal_percent := 10.0  # Default to starting of screen (horizontal)
var screen_height := 0.0
var screen_width := 0.0

# Store remote connection details for sending data back
var remote_address := ""
var remote_port := 0

@export var bullet_scene: PackedScene
@onready var shoot_position: Marker2D = $Shoot_Position

var is_player_shooting := false
func _ready():
	var err = udp.bind(UDP_PORT, "127.0.0.1")
	if err != OK:
		print("ERROR: Could not bind UDP socket on port ", UDP_PORT)
	else:
		print("SUCCESS: Listening for UDP packets on port ", UDP_PORT)
	
	# Get the screen dimensions
	var viewport_rect = get_viewport_rect()
	screen_height = viewport_rect.size.y
	screen_width = viewport_rect.size.x

func _physics_process(delta):
	# Poll for incoming UDP data
	read_udp_input()
	
	# Calculate target Y position based on percentage (0% = top, 100% = bottom)
	var target_y = (target_position_percent / 100.0) * screen_height
	
	# Calculate target X position based on percentage (0% = left, 100% = right)
	var target_x = (target_horizontal_percent / 100.0) * screen_width
	
	# Smoothly move player to target position
	position.y = lerp(position.y, target_y, LERP_SPEED * delta)
	position.x = lerp(position.x, target_x, LERP_SPEED * delta)
	
	# Optional: Keep player within screen bounds
	position.y = clamp(position.y, 0, screen_height)
	position.x = clamp(position.x, 0, screen_width)
	

func read_udp_input():  
	while udp.get_available_packet_count() > 0:
		var packet = udp.get_packet().get_string_from_utf8()
		
		# Store the remote address and port for sending data back
		remote_address = udp.get_packet_ip()
		remote_port = udp.get_packet_port()
		
		# Parse JSON data from Python
		if packet.begins_with("{"):
			var json = JSON.new()
			var parse_result = json.parse(packet)
			
			if parse_result == OK:
				var data = json.data
				
				# Handle vertical_position (0-100%)
				if data.has("vertical_position"):
					target_position_percent = clamp(data["vertical_position"], 0.0, 100.0)
				
				# Handle horizontal_position (0-100%)
				if data.has("horizontal_position"):
					target_horizontal_percent = clamp(data["horizontal_position"], 0.0, 100.0)
			else:
				print("ERROR: Failed to parse JSON: ", packet)


func send_udp_message(message: String) -> void:
	if remote_address == "":
		print("WARNING: No remote address to send UDP message to")
		return
	
	# Create JSON message
	var json_data = {"message": message}
	var json_string = JSON.stringify(json_data)
	
	# Send the packet to the remote address on the Python listening port (5005)
	udp.set_dest_address(remote_address, PYTHON_RESPONSE_PORT)
	var packet = json_string.to_utf8_buffer()
	var err = udp.put_packet(packet)
	
	if err == OK:
		print("SUCCESS: Sent UDP message '", message, "' to ", remote_address, ":", PYTHON_RESPONSE_PORT)
	else:
		print("ERROR: Failed to send UDP message: ", err)


func take_damage(amount: int) -> void:
	if Globals.health <= 0:
		return  # Already dead
	Globals.update_health(-amount)
	$AnimationPlayer.play("hit_blink")
	if Globals.health <= 0:
		# Send CAPTURE message via UDP when player dies
		send_udp_message("CAPTURE")
		$player_animation.play("blast")
		AudioManager.play_sound("ship_blast")
		AudioManager.stop_music()

func _on_player_animation_animation_finished() -> void:
	if $player_animation.animation == "blast":
		queue_free()  # Remove player from scene on blast animation finish
		Globals.game_over()

