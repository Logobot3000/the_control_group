extends Control


var toggled: bool = false;


func _on_back_button_pressed() -> void:
	if toggled:
		get_node("AnimationPlayer").play_backwards("go_in");
		get_parent().get_node("SFX/Back").play();
		get_parent().get_node("MouseBlocker").visible = false;
		toggled = false;


func _on_credits_button_pressed() -> void:
	if not toggled:
		get_node("AnimationPlayer").play("go_in");
		get_parent().get_node("SFX/Go").play();
		get_parent().get_node("MouseBlocker").visible = true;
		toggled = true;
