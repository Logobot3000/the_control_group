extends BaseMinigame;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.space_active = true;
			player.velocity_component.movement_mode = Enums.MovementMode.FREEFLYING;
			player.velocity_component.max_speed = 75;
			if player.steam_id == MinigameManager.current_experimental_group:
				player.velocity_component.max_speed = 50;
			player.velocity_component.halt_x();
			player.velocity_component.halt_y();
	experimental_points_container = get_node("BaseMinigame/TV/ExperimentalPoints");
	control_points_container = get_node("BaseMinigame/TV/ControlPoints");


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.space_active = false;
			player.velocity_component.movement_mode = Enums.MovementMode.PLATFORMER;
			player.velocity_component.max_speed = 150;
