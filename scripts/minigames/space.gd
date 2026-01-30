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
						var shield_component = load("res://scenes/components/minigames/space/shield_component.tscn").instantiate();
						shield_component.connected_player = player;
						get_tree().current_scene.add_child(shield_component);
					2:
						player.charge_shot_enabled = true;
					3:
						player.tracking_lasers_enabled = true;
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
	if get_tree().current_scene.get_node("ShieldComponent"):
		get_tree().current_scene.get_node("ShieldComponent").queue_free();
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.get_node("HealthComponent").max_health = 15;
			player.get_node("HealthComponent").health = 15;
			player.space_active = false;
			player.velocity_component.movement_mode = Enums.MovementMode.PLATFORMER;
			player.velocity_component.max_speed = 150;
			player.rotation = 0;
			player.laser_reload_time = 1;
			player.laser_shot_count_max = 3;
			player.laser_shot_count = 3;
			player.charge_shot_enabled = false;
			player.tracking_lasers_enabled = false;
			if player.steam_id == Main.player_steam_id:
				player.get_node("Overlay/LaserShotGUI").visible = false;
				player.get_node("Overlay/LaserShotGUI/Laser1").play("full");
				player.get_node("Overlay/LaserShotGUI/Laser2").play("full");
				player.get_node("Overlay/LaserShotGUI/Laser3").play("full");
				player.get_node("Overlay/LaserShotGUI/Laser4").visible = false;
				player.get_node("Overlay/LaserShotGUI/Laser5").visible = false;
				player.get_node("Overlay/LaserShotGUI/Laser4").play("full");
				player.get_node("Overlay/LaserShotGUI/Laser5").play("full");


func _process(delta: float) -> void:
	update_group_scores();
	if control_points_container.text == "5":
		end_minigame_early();
	if MinigameManager.ready_for_minigame.size() == 4 and experimental_points_container.text == "3":
		end_minigame_early();
	if MinigameManager.ready_for_minigame.size() == 3 and experimental_points_container.text == "2":
		end_minigame_early();
	if MinigameManager.ready_for_minigame.size() == 2 and experimental_points_container.text == "1":
		end_minigame_early();
