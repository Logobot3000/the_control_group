extends BaseMinigame;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.juggernaut_active = true;
			
	experimental_points_container = get_node("BaseMinigame/TV/ExperimentalPoints");
	control_points_container = get_node("BaseMinigame/TV/ControlPoints");


func load_modifiers() -> void:
	var chosen_modifier_id = 0;
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.get_node("VelocityComponent").jump_strength = 425;
			if player.steam_id == MinigameManager.current_experimental_group:
				chosen_modifier_id = MinigameManager.current_modifiers["experimental"]["id"];
				match chosen_modifier_id:
					1:
						player.juggernaut_speed_boost_enabled = true;
					2:
						player.juggernaut_sketchy_tp_enabled = true;
					3:
						player.juggernaut_stun_mines_enabled = true;
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						player.get_node("VelocityComponent").max_speed = 175;
					2:
						player.juggernaut_extra_life = true;
					3:
						player.get_node("VelocityComponent").jump_strength = 500;


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			if not player.is_dead and MinigameManager.current_control_group.has(player.steam_id):
				if get_tree().current_scene.get_node("Juggernaut") and player.is_local:
					get_tree().current_scene.get_node("Juggernaut").score_point(1);
			player.get_node("VelocityComponent").max_speed = 150;
			player.get_node("VelocityComponent").jump_strength = 400;
			for mine in get_tree().current_scene.get_node("Juggernaut").get_node("Mines").get_children():
				mine.queue_free();
			player.juggernaut_active = false;
			player.juggernaut_extra_life = false;
			player.juggernaut_speed_boost_enabled = false;
			player.juggernaut_stun_mines_enabled = false;
			player.juggernaut_sketchy_tp_enabled = false;
			player.juggernaut_sketchy_tp_uses = 3;


func _on_portal_hitbox_body_entered(body) -> void:
	print(body, " ", body.get_parent().name)
	if body.get_parent().name == "Players":
		body.global_position = Vector2(720, 880);


func _on_portal_hitbox_2_body_entered(body) -> void:
	if body.get_parent().name == "Players":
		body.global_position = Vector2(1280, 897);


func _process(delta: float) -> void:
	update_group_scores();
	if MinigameManager.ready_for_minigame.size() == 4 and experimental_points_container.text == "3":
		end_minigame_early();
	if MinigameManager.ready_for_minigame.size() == 3 and experimental_points_container.text == "2":
		end_minigame_early();
	if MinigameManager.ready_for_minigame.size() == 2 and experimental_points_container.text == "1":
		end_minigame_early();
