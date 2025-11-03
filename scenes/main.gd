extends Node2D

# Export variable for obstical scene
@export var obstical_scene: PackedScene
@export var enemy_scene: PackedScene
@export var ui_manager: CanvasLayer
@export var item_scene: PackedScene

var screen_width: int
var screen_height: int
var max_obsticals: int = 10  # Maximum number of obstacles allowed on screen

# Obstacle spawning control variables
var spawn_timer: float = 0.0
var min_spawn_interval: float = 1.5  # Minimum time between spawns (seconds)
var max_spawn_interval: float = 3.5  # Maximum time between spawns (seconds)
var next_spawn_time: float = 2.0  # Time until next spawn
var min_obsticals_on_screen: int = 2  # Minimum obstacles to maintain

@onready var background_1: TextureRect = $Background
@onready var background_2: TextureRect = $Background2
 
func _ready() -> void:
	UI.enable_ui()
	# Get screen dimensions
	var viewport_rect = get_viewport_rect()
	screen_width = viewport_rect.size.x
	screen_height = viewport_rect.size.y
	
	# Initialize background positions
	# Background 1 starts at x=0
	background_1.position.x = 0
	# Background 2 starts right after background 1
	var bg_width = background_1.size.x * background_1.scale.x
	background_2.position.x = bg_width
	AudioManager.play_sound("background_music")

	Globals.update_health(100 - 100)
	Globals.update_score(0)
	Globals.game_speed = 1.0

func _process(_delta: float) -> void: 
	# Add parallax effect to backgrounds
	add_parallax_effect(1.0)
	
	# Update spawn timer
	spawn_timer += _delta
	
	# Get current obstacle count
	var current_obstical_count = count_obsticals()
	
	# Improved obstacle spawning logic
	var should_spawn = false
	
	# Force spawn if below minimum and timer allows
	if current_obstical_count < min_obsticals_on_screen and spawn_timer >= min_spawn_interval * 0.5:
		should_spawn = true
	# Normal timed spawn if not at max capacity
	elif current_obstical_count < max_obsticals and spawn_timer >= next_spawn_time:
		should_spawn = true
	
	# Spawn obstacle when conditions are met
	if should_spawn:
		var obstical_instance = obstical_scene.instantiate()
		# Scale the size of the obstical randomly between 50% to 150%
		var scale_factor = randf_range(4.0, 5.0)
		obstical_instance.scale = Vector2(scale_factor, scale_factor)
		obstical_instance.position = Vector2(screen_width + obstical_instance.scale.x * 2 , randf() * screen_height)
		get_parent().add_child(obstical_instance)
		
		# Reset timer and calculate next spawn time
		spawn_timer = 0.0
		# Adjust spawn intervals based on game speed (gets faster as game progresses)
		var speed_factor = 1.0 / Globals.game_speed
		var adjusted_min = max(0.8, min_spawn_interval * speed_factor)
		var adjusted_max = max(1.5, max_spawn_interval * speed_factor)
		next_spawn_time = randf_range(adjusted_min, adjusted_max)
	
	# Increase game speed over time for difficulty scaling
	Globals.game_speed += 0.001

	# # Spawn item on a random interval using random.randi
	# # Appears roughly once every 15-20 seconds (assuming 60 FPS)
	# if randi() % 1200 < 1:  # ~0.083% chance each frame
	# 	var item_instance = item_scene.instantiate()
	# 	item_instance.position = Vector2(screen_width, randf() * screen_height)
	# 	get_parent().add_child(item_instance)


func add_parallax_effect(speed: float) -> void:
	# Move backgrounds leftwards for parallax effect
	background_1.position.x -= speed * Globals.game_speed
	background_2.position.x -= speed * Globals.game_speed
	
	# Get the width of the backgrounds
	var bg_width = background_1.size.x * background_1.scale.x
	
	# Reset position when background moves completely off-screen to the left
	if background_1.position.x + bg_width <= 0:
		background_1.position.x = background_2.position.x + bg_width
	
	if background_2.position.x + bg_width <= 0:
		background_2.position.x = background_1.position.x + bg_width


func count_obsticals() -> int:
	# Count all nodes in the "obstacle" group
	return get_tree().get_nodes_in_group("obstacle").size()


func update_score(amount: int) -> void:
	ui_manager.update_score(amount)

func update_health(amount: int) -> void:
	ui_manager.update_health(amount)

