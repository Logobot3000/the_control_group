extends Control;


func _on_host_settings_button_pressed() -> void:
	get_node("AnimationPlayer").play("go_in");
	get_tree().current_scene.get_node("SFX/Go").play();


func _on_back_button_pressed() -> void:
	get_node("AnimationPlayer").play_backwards("go_in");
	get_tree().current_scene.get_node("SFX/Back").play();


func _on_copy_code_button_pressed() -> void:
	DisplayServer.clipboard_set(get_node("HostSettingsUI").get_node("TextureRect").get_node("LobbyCode").text);
	get_tree().current_scene.get_node("SFX/Select").play();


func _on_disable_narrator_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Network.send_p2p_packet(0, {"message": "do_narrator_disabled"});
		MinigameManager.do_narrator_disabled({});
	else:
		Network.send_p2p_packet(0, {"message": "do_narrator_reenabled"});
		MinigameManager.do_narrator_reenabled({});


func _on_text_edit_text_changed() -> void:
	var text: String = get_node("HostSettingsUI/TextureRect/TextEdit").text;
	if text == Constants.SUPER_SECRET_CODE:
		if MinigameManager.narrator_disabled and Main.current_game_state == Enums.GameState.LOBBY:
			get_node("HostSettingsUI/TextureRect/TextEdit").editable = false;
			get_tree().current_scene.get_node("SFX/Select").play();
			MinigameManager.secret_enabled = true;


func _physics_process(delta: float) -> void:
	if MinigameManager.can_disable:
		get_node("HostSettingsUI/TextureRect/DisableNarrator").disabled = false;
	else:
		get_node("HostSettingsUI/TextureRect/DisableNarrator").disabled = true;
