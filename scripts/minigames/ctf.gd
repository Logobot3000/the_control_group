extends BaseMinigame;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.ctf_active = true;
			
	experimental_points_container = get_node("BaseMinigame/TV/ExperimentalPoints");
	control_points_container = get_node("BaseMinigame/TV/ControlPoints");


func load_modifiers() -> void:
	var chosen_modifier_id = 0;
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			if player.steam_id == MinigameManager.current_experimental_group:
				chosen_modifier_id = MinigameManager.current_modifiers["experimental"]["id"];
				match chosen_modifier_id:
					1:
						player.ctf_flag_master_enabled = true;
					2:
						player.ctf_dash_enabled = true;
					3:
						player.ctf_stun_blast_enabled = true;
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						player.get_node("VelocityComponent").max_speed = 162;
					2:
						player.get_node("VelocityComponent").jump_strength = 450;
					3:
						player.ctf_flag_hunter_enabled = true;


func on_minigame_started() -> void:
	get_tree().current_scene.get_node("MinigameMusic").get_node("CTF").play();


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.ctf_active = false;
			player.get_node("VelocityComponent").max_speed = 150;
			player.get_node("VelocityComponent").jump_strength = 400;
			player.ctf_flag_hunter_enabled = false;
			player.ctf_flag_master_enabled = false;
			player.ctf_dash_enabled = false;
			player.ctf_stun_blast_enabled = false;


func _physics_process(delta: float) -> void:
	update_group_scores();
