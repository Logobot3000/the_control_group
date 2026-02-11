extends BaseMinigame;


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


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.collector_active = false;


func _process(delta: float) -> void:
	update_group_scores();
