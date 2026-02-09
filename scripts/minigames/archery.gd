extends BaseMinigame;

## The time for the next target to spawn.
var target_spawn_time: float = 1.25;
## The current target id.
var target_id: int = 0;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.archery_active = true;
			player.get_node("VelocityComponent").set_speed_multiplier(0);
			
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
						player.archery_mineral_deposit_enabled = true;
					2:
						player.archery_big_clicker_enabled = true;
					3:
						player.archery_intentional_misfire_enabled = true;
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						player.arrow_cooldown_time = 0.9;
					2:
						player.archery_jackpot_enabled = true;
					3:
						player.archery_midas_touch_enabled = true;


func on_minigame_started() -> void:
	spawn_target_timer();


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.archery_active = false;
			player.get_node("VelocityComponent").set_speed_multiplier(1);
			player.arrow_cooldown_time = 1;
			player.arrow_cooldown = false;
			player.archery_mineral_deposit_enabled = false;
			player.archery_jackpot_enabled = false;
			player.archery_midas_touch_enabled = false;
			player.archery_intentional_misfire_enabled = false;
			player.archery_big_clicker_enabled = false;
	for target in get_tree().current_scene.get_node("Archery").get_node("SkyTargets").get_children():
		target.queue_free();


func spawn_target_timer() -> void:
	if minigame_active:
		target_id += 1;
		target_spawn_time = target_spawn_time - 0.005;
		spawn_target();
		await get_tree().create_timer(target_spawn_time).timeout;
		spawn_target_timer();


func spawn_target() -> void:
	if Network.is_host:
		var height: Array = [1088, 1040, 992, 944];
		var tier: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 3];
		var target_data: Dictionary = {
			"message": "spawn_target",
			"position": Vector2(randi_range(725, 1275), height[randi_range(0, 3)]),
			"tier": tier[randi_range(0, 15)],
			"id": target_id
		};
		Network.send_p2p_packet(0, target_data);
		MinigameManager.spawn_target(target_data);


func _process(delta: float) -> void:
	update_group_scores();
