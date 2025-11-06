extends Node2D


var health := 100
var score := 0
var bullet_count := 50
var game_speed := 1.0
var player_name := "Player"

func update_health(amount: int) -> void:
	health += amount
	if health < 0:
		health = 0
	UI.update_health(health)

func update_score(amount: int) -> void:
	score += amount
	UI.update_score(score)

func update_username(username: String) -> void:
	player_name = username
	UI.update_username(player_name)


func game_over() -> void:
	bullet_count = 50
	print("Game Over! Final Score: %d" % score)
	save_highscore(player_name, score)
	# wait a moment before changing scene
	await get_tree().create_timer(1.0).timeout
	
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")


func save_highscore(username: String, current_score: int) -> void:
	var file_path = "user://highscores.json"
	var highscores = []

	# --- Step 1: Load file if it exists
	if FileAccess.file_exists(file_path):
		var file_read = FileAccess.open(file_path, FileAccess.READ)
		var data = file_read.get_as_text()
		if data != "":
			highscores = JSON.parse_string(data)
		file_read.close()

	# If invalid or empty file, reset
	if typeof(highscores) != TYPE_ARRAY:
		highscores = []

	# --- Step 2: Add new score entry
	highscores.append({
		"Name": username,
		"Score": current_score,
	})

	# --- Step 3: Sort by score (descending)
	highscores.sort_custom(func(a, b): return a["Score"] > b["Score"])

	# --- Step 4: Trim to top 5 only
	if highscores.size() > 5:
		highscores = highscores.slice(0, 5)

	# --- Step 5: Reassign ranks (1-based)
	for i in range(highscores.size()):
		highscores[i]["Rank"] = i + 1

	# --- Step 6: Save back to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(highscores, "\t"))  # tab formatted
	file.close()

