extends TextureButton

@onready var anim_player: AnimationPlayer = $AnimationPlayerQuit;


func _on_mouse_entered() -> void:
	if !anim_player.is_playing():
		anim_player.play("hover_in");


func _on_mouse_exited() -> void:
	if !anim_player.is_playing():
		anim_player.play("hover_out");


func _on_pressed() -> void:
	get_tree().quit();
