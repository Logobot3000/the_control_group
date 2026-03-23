extends BaseMinigame;


var bomb_explosion_time: int = 28;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.bombtag_active = true;
	
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
						player.bombtag_salt_spray_enabled = true;
					2:
						bomb_explosion_time /= 2;
						player.get_node("VelocityComponent").max_speed = 182;
					3:
						player.bombtag_hot_potato_enabled = true;
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						player.get_node("VelocityComponent").max_speed = 162;
					2:
						player.get_node("VelocityComponent").jump_strength = 450;
					3:
						player.bombtag_sick_dodge_enabled = true;


func on_minigame_ended() -> void:
	var currently_dead: int = 0;
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.is_dead:
			if player.is_experimental:
				for pl in get_tree().current_scene.get_node("Players").get_children():
					if MinigameManager.ready_for_minigame.has(pl.steam_id) and not pl.is_dead:
						score(pl.steam_id);
	if currently_dead == MinigameManager.current_control_group.size():
		score(MinigameManager.current_experimental_group);
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.bombtag_active = false;
			player.bombtag_bomb_active = false;
			player.bombtag_just_passed = false
			player.get_node("VelocityComponent").max_speed = 150;
			player.get_node("VelocityComponent").jump_strength = 400;
			bomb_explosion_time = 28;
			player.bombtag_salt_spray_enabled = false;
			player.bombtag_hot_potato_enabled = false;
			player.bombtag_sick_dodge_enabled = false;
			player.bombtag_ability_uses = 2;


func select_bombed_player() -> void:
	if Network.is_host:
		var bomb_id;
		while true:
			var players = get_tree().current_scene.get_node("Players").get_children();
			players.shuffle();
			var selected = players[0];
			if not selected.is_dead:
				bomb_id = selected.steam_id;
				break;
		Network.send_p2p_packet(0, { "message": "select_bomb", "steam_id": bomb_id, "bomb": true });
		MinigameManager.select_bomb({ "message": "select_bomb", "steam_id": bomb_id, "bomb": true });


func on_minigame_started() -> void:
	get_tree().current_scene.get_node("MinigameMusic").get_node("BombTag").play();
	await get_tree().create_timer(1).timeout;
	var i = 0;
	while i < 3:
		var txt: RichTextLabel = get_node("RichTextLabel");
		txt.text = "BOMB IS SAFE";
		txt.add_theme_color_override("default_color", Color("#ffffff"));
		select_bombed_player();
		await get_tree().create_timer(bomb_explosion_time - 10).timeout;
		txt.text = "BOMB IS UNSAFE";
		txt.add_theme_color_override("default_color", Color("#ff4646"));
		await get_tree().create_timer(7).timeout;
		txt.text = "BOMB WILL EXPLODE";
		txt.add_theme_color_override("default_color", Color("#ff0000"));
		await get_tree().create_timer(1).timeout;
		txt.add_theme_color_override("default_color", Color("#ff5500"));
		await get_tree().create_timer(1).timeout;
		txt.add_theme_color_override("default_color", Color("#ffff00"));
		await get_tree().create_timer(1).timeout;
		txt.text = "BOMB HAS EXPLODED";
		txt.add_theme_color_override("default_color", Color("#ffff6e"));
		for player in get_tree().current_scene.get_node("Players").get_children():
			player.bombtag_bomb_explode();
		i += 1;
		await get_tree().create_timer(1).timeout;


func score(id):
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id == id and player.is_local:
			score_point(5);


func _physics_process(delta: float) -> void:
	update_group_scores();
	var currently_dead: int = 0;
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.is_dead:
			if player.is_experimental:
				end_minigame_early();
			else:
				currently_dead += 1;
	if currently_dead == MinigameManager.current_control_group.size():
		end_minigame_early();
