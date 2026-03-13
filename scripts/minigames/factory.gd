extends BaseMinigame;


var button_1_pressed: bool = false;
var button_2_pressed: bool = false;
var button_3_pressed: bool = false;
var button_4_pressed: bool = false;
var warning_time: float = 1.0;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.factory_active = true;
			if player.steam_id in MinigameManager.current_control_group:
				player.can_jump = false;
				if player.is_local:
					get_node("ExperimentalHider").visible = true;
					for pls in get_tree().current_scene.get_node("Players").get_children():
						if pls.steam_id == MinigameManager.current_experimental_group:
							pls.get_node("AnimatedSprite2D").visible = false;
	
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
						player.factory_double_trouble_enabled = true;
					2:
						warning_time = 0.5;
					3:
						player.factory_sticky_floors_enabled = true;
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						player.get_node("VelocityComponent").max_speed = 162;
					2:
						player.factory_hard_hat_enabled = true;
					3:
						player.factory_enhanced_eyesight_enabled = true;


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			if not player.is_dead and MinigameManager.current_control_group.has(player.steam_id):
				if get_tree().current_scene.get_node("Factory") and player.is_local:
					score_point(5);
			for pls in get_tree().current_scene.get_node("Players").get_children():
					if pls.steam_id == MinigameManager.current_experimental_group:
						pls.get_node("AnimatedSprite2D").visible = true;
			get_node("ExperimentalHider").visible = false;
			player.get_node("VelocityComponent").max_speed = 150;
			warning_time = 1.0;
			player.factory_active = false;
			player.can_jump = true;
			player.factory_hard_hat_enabled = false;
			player.factory_enhanced_eyesight_enabled = false;
			player.factory_double_trouble_enabled = false;
			player.factory_sticky_floors_enabled = false;


func _physics_process(delta: float) -> void:
	update_group_scores();
	if MinigameManager.ready_for_minigame.size() == 4 and experimental_points_container.text == "3":
		end_minigame_early();
	if MinigameManager.ready_for_minigame.size() == 3 and experimental_points_container.text == "2":
		end_minigame_early();
	if MinigameManager.ready_for_minigame.size() == 2 and experimental_points_container.text == "1":
		end_minigame_early();
	if button_1_pressed:
		get_tree().current_scene.get_node("Factory").get_node("Buttons").get_node("Button1").get_node("AnimatedSprite2D").play("pressed");
	else:
		get_tree().current_scene.get_node("Factory").get_node("Buttons").get_node("Button1").get_node("AnimatedSprite2D").play("unpressed");
	if button_2_pressed:
		get_tree().current_scene.get_node("Factory").get_node("Buttons").get_node("Button2").get_node("AnimatedSprite2D").play("pressed");
	else:
		get_tree().current_scene.get_node("Factory").get_node("Buttons").get_node("Button2").get_node("AnimatedSprite2D").play("unpressed");
	if button_3_pressed:
		get_tree().current_scene.get_node("Factory").get_node("Buttons").get_node("Button3").get_node("AnimatedSprite2D").play("pressed");
	else:
		get_tree().current_scene.get_node("Factory").get_node("Buttons").get_node("Button3").get_node("AnimatedSprite2D").play("unpressed");
	if button_4_pressed:
		get_tree().current_scene.get_node("Factory").get_node("Buttons").get_node("Button4").get_node("AnimatedSprite2D").play("pressed");
	else:
		get_tree().current_scene.get_node("Factory").get_node("Buttons").get_node("Button4").get_node("AnimatedSprite2D").play("unpressed");


func _on_button_collision_detector_body_entered(body, btn_name: String) -> void:
	if body.get_parent().name == "Players":
		match btn_name:
			"Button1":
				fire_piston(1);
			"Button2":
				fire_piston(2);
			"Button3":
				fire_piston(3);
			"Button4":
				fire_piston(4);


func fire_piston(id: int) -> void:
	if button_1_pressed or button_2_pressed or button_3_pressed or button_4_pressed:
		return;
	var piston;
	match id:
		1:
			piston = get_tree().current_scene.get_node("Factory").get_node("Pistons").get_node("Piston1");
			button_1_pressed = true;
		2:
			piston = get_tree().current_scene.get_node("Factory").get_node("Pistons").get_node("Piston2");
			button_2_pressed = true;
		3:
			piston = get_tree().current_scene.get_node("Factory").get_node("Pistons").get_node("Piston3");
			button_3_pressed = true;
		4:
			piston = get_tree().current_scene.get_node("Factory").get_node("Pistons").get_node("Piston4");
			button_4_pressed = true;
	var sprite = piston.get_node("AnimatedSprite2D");
	sprite.play("warning");
	await get_tree().create_timer(warning_time).timeout;
	sprite.play("press_down");
	await get_tree().create_timer(0.4).timeout;
	sprite.play("pressed");
	
	for player in piston.get_node("Area2D").get_overlapping_bodies():
		if player.get_parent().name == "Players":
			if player.factory_hard_hat_enabled:
				player.factory_hard_hat_enabled = false;
				player.can_move = false;
			else:
				player.die();
				for exp in get_tree().current_scene.get_node("Players").get_children():
					if exp.steam_id == MinigameManager.current_experimental_group and exp.is_local:
						score_point(1);

	piston.get_node("StaticBody2D").get_node("CollisionPolygon2D").disabled = false;
	await get_tree().create_timer(3).timeout;
	piston.get_node("StaticBody2D").get_node("CollisionPolygon2D").disabled = true;
	
	for player in piston.get_node("Area2D").get_overlapping_bodies():
		if player.get_parent().name == "Players":
			player.can_move = true;
	
	sprite.play_backwards("press_down");
	await get_tree().create_timer(0.4).timeout;
	sprite.play("no_press");
	match id:
		1:
			button_1_pressed = false;
		2:
			button_2_pressed = false;
		3:
			button_3_pressed = false;
		4:
			button_4_pressed = false;
	
