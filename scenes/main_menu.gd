extends Control

var screen_width: int
var screen_height: int
@onready var background_1: TextureRect = $Background
@onready var background_2: TextureRect = $Background2
@onready var lineEdit: LineEdit = $LineEdit

# All User HBox Container
@onready var user1 : HBoxContainer = $Panel/VBoxContainer/User1
@onready var user2 : HBoxContainer = $Panel/VBoxContainer/User2
@onready var user3 : HBoxContainer = $Panel/VBoxContainer/User3
@onready var user4 : HBoxContainer = $Panel/VBoxContainer/User4
@onready var user5 : HBoxContainer = $Panel/VBoxContainer/User5

var json_path = "user://highscores.json"

func _ready() -> void:
	UI.disable_ui()
	Globals.health = 100
	Globals.score = 0
	# Get screen dimensions
	var viewport_rect = get_viewport_rect()
	screen_width = viewport_rect.size.x
	screen_height = viewport_rect.size.y
	Globals.game_speed = 1.0
	
	# Initialize background positions
	# Background 1 starts at x=0
	background_1.position.x = 0
	# Background 2 starts right after background 1
	var bg_width = background_1.size.x * background_1.scale.x
	background_2.position.x = bg_width
	AudioManager.play_sound("main_menu")
	display_high_scores()


func _process(_delta: float) -> void: 
	# Add parallax effect to backgrounds
	add_parallax_effect(1.0)

func add_parallax_effect(speed: float) -> void:
	# Move backgrounds leftwards for parallax effect
	background_1.position.x -= speed * Globals.game_speed 
	background_2.position.x -= speed * Globals.game_speed
	
	# Reset position when background moves completely off-screen to the left
	if background_1.position.x + background_1.size.x * background_1.scale.x <= 0:
		background_1.position.x = background_2.position.x + background_1.size.x * background_1.scale.x

	if background_2.position.x + background_2.size.x * background_2.scale.x <= 0:
		background_2.position.x = background_1.position.x + background_2.size.x * background_2.scale.x


func _on_play_pressed() -> void:
	var username = lineEdit.text.strip_edges()
	if username == "":
		$Warning.visible = true

		AudioManager.play_sound("wrong")
		# Create a 2 second timer to hide the warning
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 2.0
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "_on_warning_timer_timeout"))
		timer.start()
		return

	Globals.player_name = username
	Globals.update_username(username)
	# Change to main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_warning_timer_timeout() -> void:
	$Warning.visible = false

func display_high_scores():

	var highscores = load_highscores()
	var user_index = 1
	for entry in highscores:
		if user_index > 5:
			break  # Only display top 5
		var user_container : HBoxContainer = get_node("Panel/VBoxContainer/User%d" % user_index)
		user_container.visible = true
		var name_label : Label = user_container.get_node("Name")
		name_label.custom_minimum_size = Vector2(100, 0)
		var score_label : Label = user_container.get_node("Score")
		score_label.custom_minimum_size = Vector2(20, 0)
		var rank_label : Label = user_container.get_node("Rank")
		rank_label.custom_minimum_size = Vector2(50, 0)
		name_label.text = entry["Name"]
		score_label.text = str(entry["Score"])
		rank_label.text = str(entry["Rank"]) if entry.has("Rank") else str(user_index)
		user_index += 1

func load_highscores():
	if not FileAccess.file_exists(json_path):
		return []
	var file = FileAccess.open(json_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_ARRAY:
		return data
	return []


func _on_button_pressed() -> void:
	# Remove highscores file
	var file_path = "user://highscores.json"
	if FileAccess.file_exists(file_path):
		# Change it to an empty array
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		file.store_string("[]")
		file.close()
	# Refresh high score display
	for i in range(1, 6):
		var user_container : HBoxContainer = get_node("Panel/VBoxContainer/User%d" % i)
		user_container.visible = false
	display_high_scores()
