extends BaseMinigame;


## The path to the LaserComponent scene to be instanced when a laser is shot.
@export var laser_component_path: PackedScene;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.space_active = true;
			player.velocity_component.movement_mode = Enums.MovementMode.FREEFLYING;
			player.velocity_component.max_speed = 75;
			if player.steam_id == MinigameManager.current_experimental_group:
				player.velocity_component.max_speed = 65;
			player.velocity_component.halt_x();
			player.velocity_component.halt_y();
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
						print("shield")
					2:
						print("charging laser")
					3:
						print("tracking lasers")
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						player.velocity_component.max_speed = 85;
					2:
						print("extra lasers")
					3:
						print("faster reload")


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.space_active = false;
			player.velocity_component.movement_mode = Enums.MovementMode.PLATFORMER;
			player.velocity_component.max_speed = 150;
			player.rotation = 0;


func _process(delta: float) -> void:
	update_group_scores();
