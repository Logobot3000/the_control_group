extends Control;


func _on_host_settings_button_pressed() -> void:
	get_node("AnimationPlayer").play("go_in");


func _on_back_button_pressed() -> void:
	get_node("AnimationPlayer").play_backwards("go_in");


func _on_copy_code_button_pressed() -> void:
	DisplayServer.clipboard_set(get_node("HostSettingsUI").get_node("TextureRect").get_node("LobbyCode").text);


func _on_disable_narrator_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Network.send_p2p_packet(0, {"message": "do_narrator_disabled"});
		MinigameManager.do_narrator_disabled({});
	else:
		Network.send_p2p_packet(0, {"message": "do_narrator_reenabled"});
		MinigameManager.do_narrator_reenabled({});
