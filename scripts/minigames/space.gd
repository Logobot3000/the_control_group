extends BaseMinigame;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.space_active = true;
			player.can_jump = false;
			player.velocity_component.movement_mode = Enums.MovementMode.FREEFLYING;
			
	experimental_points_container = get_node("BaseMinigame/TV/ExperimentalPoints");
	control_points_container = get_node("BaseMinigame/TV/ControlPoints");
