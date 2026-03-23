extends BaseMinigame;

@onready var rld: Area2D = $RedLightDetector;

var light_status: int = 0;
var can_activate_red: bool = true;
var iptgb_timer_not_done: bool = false;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.rlgl_active = true;
	experimental_points_container = get_node("BaseMinigame/TV/ExperimentalPoints");
	control_points_container = get_node("BaseMinigame/TV/ControlPoints");


func load_modifiers() -> void:
	var chosen_modifier_id = 0;
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			if player.steam_id == MinigameManager.current_experimental_group:
				if player.is_local:
					score_point(MinigameManager.current_control_group.size());
				chosen_modifier_id = MinigameManager.current_modifiers["experimental"]["id"];
				match chosen_modifier_id:
					1:
						player.rlgl_colorblind_enabled = true;
					2:
						player.rlgl_jumpscare_enabled = true;
					3:
						player.rlgl_fair_game_enabled = true;
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						player.get_node("VelocityComponent").max_speed = 162;
					2:
						player.rlgl_iptgb_enabled = true;
					3:
						player.get_node("VelocityComponent").jump_strength = 450;


func on_minigame_started() -> void:
	get_tree().current_scene.get_node("MinigameMusic").get_node("RLGL").play();


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
			player.rlgl_active = false;
			player.get_node("VelocityComponent").max_speed = 150;
			player.get_node("VelocityComponent").jump_strength = 400;
			player.rlgl_iptgb_enabled = false;
			player.rlgl_fair_game_enabled = false;
			player.rlgl_jumpscare_enabled = false;
			player.rlgl_colorblind_enabled = false;


func change_lights(color: Color):
	for light in get_node("Lighting").get_children():
		light.color = color;


func _physics_process(delta: float) -> void:
	update_group_scores();
	var control_group_members_dead: int = 0;
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.is_dead:
			control_group_members_dead += 1;
	if control_group_members_dead + int(control_points_container.text) == MinigameManager.current_control_group.size():
		end_minigame_early()
	match light_status:
		0:
			change_lights(Color("00ff00"));
		1:
			change_lights(Color("ffff00"));
		2:
			change_lights(Color("ff0000"));
	if light_status == 2:
		for body in rld.get_overlapping_bodies():
			if body.get_parent().name == "Players":
				if MinigameManager.current_control_group.has(body.steam_id):
					if snapped(body.velocity.x, 2) != 0 or snapped(body.velocity.y, 2) != 0:
						if body.is_local:
							if not (body.rlgl_iptgb_enabled and iptgb_timer_not_done):
								body.die();


func _on_red_btn_body_entered(body: Node2D) -> void:
	var jumpscare_enabled = false;
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.is_experimental:
			if player.rlgl_jumpscare_enabled:
				jumpscare_enabled = true;
			break;
	if can_activate_red:
		can_activate_red = false;
		get_node("StaticBody2D/AnimatedSprite2D").play("pressed");
		light_status = 1;
		if jumpscare_enabled:
			await get_tree().create_timer(0.4).timeout;
		else:
			await get_tree().create_timer(0.8).timeout;
		light_status = 2;
		iptgb_timer_not_done = true;
		await get_tree().create_timer(0.5).timeout;
		iptgb_timer_not_done = false;
		await get_tree().create_timer(4.5).timeout;
		light_status = 0;
		get_node("StaticBody2D/AnimatedSprite2D").play("unpressed");
		await get_tree().create_timer(5).timeout;
		can_activate_red = true;
		iptgb_timer_not_done = false;


func _on_control_win_detector_body_entered(body) -> void:
	if body.is_local:
		score_point(1);
	else:
		if Main.player_steam_id == MinigameManager.current_experimental_group:
			score_point(-1);
