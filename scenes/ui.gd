extends CanvasLayer

@onready var health: Label = $Health
@onready var user_name: Label = $UserName
@onready var score_label: Label = $Score

func update_health(hp: int) -> void:
	health.text = "Health: %d" % hp

func update_score(score: int) -> void:
	score_label.text = "Score: %d" % score

func update_username(username: String) -> void:
	user_name.text = "Username: %s" % username

func disable_ui() -> void:
	visible = false

func enable_ui() -> void:
	visible = true
