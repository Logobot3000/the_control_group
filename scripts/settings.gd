extends Control


var toggled: bool = false;


func _on_settings_button_pressed() -> void:
	if not toggled:
		get_node("AnimationPlayer").play("go_in");
		get_parent().get_node("MouseBlocker").visible = true;
		toggled = true;


func _on_back_button_pressed() -> void:
	if toggled:
		get_node("AnimationPlayer").play_backwards("go_in");
		get_parent().get_node("MouseBlocker").visible = false;
		toggled = false;


func _on_narrator_vol_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Narrator"), value);
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), value);


func _on_music_vol_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("GameMusic"), value);
