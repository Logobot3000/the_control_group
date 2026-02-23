extends BaseMinigame;


## The time for the next coin to spawn.
var coin_spawn_time: float = 1.25;
## The current coin id.
var coin_id: int = 0;

func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.kaching_active = true;
			
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
						player.kaching_billionaire_enabled = true;
					2:
						player.kaching_magnet_enabled = true;
					3:
						player.kaching_winning_streak_enabled = true;
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						player.get_node("VelocityComponent").max_speed = 175;
					2:
						player.kaching_millionaire_enabled = true;
					3:
						player.kaching_all_in_enabled = true;


func on_minigame_started() -> void:
	spawn_coin_timer();


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.kaching_active = false;
			player.get_node("VelocityComponent").max_speed = 175;
			player.kaching_billionaire_enabled = false;
			player.kaching_magnet_enabled = false;
			player.kaching_winning_streak_enabled = false;
			player.kaching_millionaire_enabled = false;
			player.kaching_all_in_enabled = false;


func spawn_coin_timer() -> void:
	if minigame_active:
		coin_id += 1;
		coin_spawn_time = coin_spawn_time - 0.005;
		spawn_coin();
		await get_tree().create_timer(coin_spawn_time).timeout;
		spawn_coin_timer();


func spawn_coin() -> void:
	if Network.is_host:
		var tier: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 3];
		var target_data: Dictionary = {
			"message": "spawn_coin",
			"position": Vector2(randi_range(728, 1272), randi_range(920, 1048)),
			"tier": tier[randi_range(0, 15)],
			"id": coin_id
		};
		Network.send_p2p_packet(0, target_data);
		MinigameManager.spawn_coin(target_data);

func _process(delta: float) -> void:
	update_group_scores();


func _on_trampoline_body_entered(body) -> void:
	if body.get_parent().name == "Players":
		body.get_node("VelocityComponent").velocity.y = -1000;
	get_node("Trampoline/AnimatedSprite2D").play('boing');
