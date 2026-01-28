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
				player.get_node("HealthComponent").max_health = 45;
				player.get_node("HealthComponent").health = 45;
			player.velocity_component.halt_x();
			player.velocity_component.halt_y();
			if player.steam_id == Main.player_steam_id:
				player.get_node("Overlay/LaserShotGUI").visible = true;
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
						player.laser_shot_count_max = 5;
						player.laser_shot_count = 5;
						if player.steam_id == Main.player_steam_id:
							player.get_node("Overlay/LaserShotGUI/Laser4").visible = true;
							player.get_node("Overlay/LaserShotGUI/Laser5").visible = true;
					3:
						player.laser_reload_time = 0.5;


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.space_active = false;
			player.velocity_component.movement_mode = Enums.MovementMode.PLATFORMER;
			player.velocity_component.max_speed = 150;
			player.rotation = 0;
			player.laser_reload_time = 1;
			player.laser_shot_count_max = 3;
			player.laser_shot_count = 3;
			if player.steam_id == Main.player_steam_id:
				player.get_node("Overlay/LaserShotGUI").visible = false;
				player.get_node("Overlay/LaserShotGUI/Laser4").visible = false;
				player.get_node("Overlay/LaserShotGUI/Laser5").visible = false;


func _process(delta: float) -> void:
	update_group_scores();
