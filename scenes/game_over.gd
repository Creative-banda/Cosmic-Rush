extends Control


func get_latest_image():
    var folder_path = "C:/Captures"
    var dir = DirAccess.open(folder_path)
    var latest_file = ""
    var latest_time = 0.0

    if dir:
        for file_name in dir.get_files():
            if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
                var full_path = folder_path + "/" + file_name
                var mod_time = FileAccess.get_modified_time(full_path)
                if mod_time > latest_time:
                    latest_time = mod_time
                    latest_file = full_path
    return latest_file

func _ready() -> void:
    var image_path = get_latest_image()
    if image_path != "":
        var texture = ImageTexture.create_from_image(Image.load_from_file(image_path))
        $CapturedImage.texture = texture
    
    $Score.text = "Final Score: %d" % Globals.score

    # Create a timer to change scene after 4 seconds
    var timer = Timer.new()
    add_child(timer)
    timer.wait_time = 4.0
    timer.one_shot = true
    timer.connect("timeout", Callable(self, "_on_timer_timeout"))
    timer.start()


func _on_timer_timeout() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")