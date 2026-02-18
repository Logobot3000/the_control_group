extends RigidBody2D;
## mmm balls

var id: int = 0;
var ball_tier: int = 0;
var ball_score_amt: int = 0;
var inside_coll;
var last_touched;


func _ready() -> void:
	inside_coll = $Area2D/CollisionShape2D;
	match ball_tier:
		0:
			get_node("AnimatedSprite2D").play("default");
			ball_score_amt = 1;
		1:
			get_node("AnimatedSprite2D").play("bronze");
			ball_score_amt = 2;
		2:
			get_node("AnimatedSprite2D").play("silver");
			ball_score_amt = 3;
		3:
			get_node("AnimatedSprite2D").play("gold");
			ball_score_amt = 5;
	
	if not Network.is_host:
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC;
		sleeping = true;
		freeze = true;
		set_physics_process(false);


func _physics_process(delta: float) -> void:
	if Network.is_host:
		var ball_data: Dictionary = {
			"message": "ball_update",
			"id": id,
			"pos": global_position,
			"rot": rotation,
			"vel": linear_velocity
		};
		Network.send_p2p_packet(0, ball_data);


func _process(delta: float) -> void:
	inside_coll.rotation = -rotation;
	
	if global_position.y >= 1250:
		if last_touched:
			if MinigameManager.current_control_group.has(last_touched) and global_position.x >= 1000:
				if Main.player_steam_id == last_touched:
					_score(Main.player_steam_id);
			elif last_touched == MinigameManager.current_experimental_group and global_position.x <= 1000:
				if Main.player_steam_id == last_touched:
					_score(Main.player_steam_id);
			elif global_position.x >= 1000:
				_score_random_control();
			else:
				if Main.player_steam_id == MinigameManager.current_experimental_group:
					_score(Main.player_steam_id);
		else:
			if global_position.x >= 1000:
				_score_random_control();
			else:
				if Main.player_steam_id == MinigameManager.current_experimental_group:
						_score(Main.player_steam_id);
		
		queue_free();


func _on_area_2d_2_body_entered(body) -> void:
	if body.get_parent().name == "Players":
		last_touched = body.steam_id;


func _score_random_control() -> void:
	var id = MinigameManager.current_control_group[randi_range(0, MinigameManager.current_control_group.size() - 1)];
	if MinigameManager.current_control_group.has(Main.player_steam_id) and Main.player_steam_id == id:
		_score(Main.player_steam_id);


func _score(id: int) -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id == id:
			if player.collector_ball_master_enabled and ball_score_amt > 1:
				get_tree().current_scene.get_node("Collector").score_point(ball_score_amt * 2);
			elif player.collector_ball_connoisseur_enabled and ball_score_amt > 1:
				get_tree().current_scene.get_node("Collector").score_point(ball_score_amt + 1);
			elif player.collector_novelty_balls_enabled and randi_range(1, 20) == 20:
				get_tree().current_scene.get_node("Collector").score_point(5);
			else: get_tree().current_scene.get_node("Collector").score_point(ball_score_amt);
