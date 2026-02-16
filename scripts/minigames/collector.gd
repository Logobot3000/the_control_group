extends BaseMinigame;


var ball_id = 0;
var ball_spawn_time = 4;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.collector_active = true;
			
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
						print("E1")
					2:
						print("E2")
					3:
						print("E3")
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						print("C1")
					2:
						print("C2")
					3:
						print("C3")


func on_minigame_started() -> void:
	spawn_ball_timer();


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.collector_active = false;
	for ball in get_tree().current_scene.get_node("Collector").get_node("Balls").get_children():
		ball.queue_free();


func spawn_ball_timer() -> void:
	if minigame_active:
		ball_id += 1;
		ball_spawn_time = ball_spawn_time - 0.01;
		spawn_ball();
		await get_tree().create_timer(ball_spawn_time).timeout;
		spawn_ball_timer();


func spawn_ball() -> void:
	if Network.is_host:
		var tier: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 3];
		var ball_data: Dictionary = {
			"message": "spawn_ball",
			"position": Vector2(1000, 950),
			"tier": tier[randi_range(0, 15)],
			"id": ball_id
		};
		Network.send_p2p_packet(0, ball_data);
		MinigameManager.spawn_ball(ball_data);


func _process(delta: float) -> void:
	update_group_scores();
