extends BaseMinigame;

## The time for the next fish to spawn.
var target_spawn_time: float = 2;
## The current target id.
var target_id: int = 0;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.archery_active = true;
			player.can_move = false;
			
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
						print("e1")
					2:
						print("e2")
					3:
						print("e3")
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						print("c1")
					2:
						print("c2")
					3:
						print("c3")


func on_minigame_started() -> void:
	spawn_target_timer();


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.archery_active = false;
			player.can_move = true;
	for target in get_tree().current_scene.get_node("Archery").get_node("SkyTargets"):
		target.queue_free();


func spawn_target_timer() -> void:
	if minigame_active:
		target_id += 1;
		target_spawn_time = target_spawn_time - 0.01;
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
