extends Area2D;

@export var coin_tier: int = 0;
var id: int = 0;


func _ready() -> void:
	match coin_tier:
		0:
			get_node("AppearParticlesDefault").emitting = true;
		1:
			get_node("AppearParticlesBronze").emitting = true;
		2:
			get_node("AppearParticlesSilver").emitting = true;
		3:
			get_node("AppearParticlesGold").emitting = true;
	get_node("AnimationPlayer").play("appear");


func _process(delta: float) -> void:
	match coin_tier:
		0:
			get_node("AnimatedSprite2D").play("default");
		1:
			get_node("AnimatedSprite2D").play("bronze");
		2:
			get_node("AnimatedSprite2D").play("silver");
		3:
			get_node("AnimatedSprite2D").play("gold");
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.kaching_magnet_enabled:
			var direction = player.global_position - global_position;
			if sqrt((direction.x * direction.x) + (direction.y * direction.y)) <= 40:
				direction = direction.normalized();
				global_position += direction * 10;


func _on_body_entered(body) -> void:
	if body.get_parent().name == "Players":
		if body.steam_id == Main.player_steam_id:
			if body.kaching_all_in_enabled and randi_range(1, 20) == 20:
				get_tree().current_scene.get_node("Kaching").score_point(5);
			if body.kaching_winning_streak_enabled:
				body.do_winning_streak_timer();
				body.kaching_winning_streak_amt += 1;
				print(body.kaching_winning_streak_amt)
			match coin_tier:
				0:
					get_tree().current_scene.get_node("Kaching").score_point(1);
				1:
					if body.kaching_billionaire_enabled:
						get_tree().current_scene.get_node("Kaching").score_point(4);
					elif body.kaching_millionaire_enabled:
						get_tree().current_scene.get_node("Kaching").score_point(3);
					else: get_tree().current_scene.get_node("Kaching").score_point(2);
				2:
					if body.kaching_billionaire_enabled:
						get_tree().current_scene.get_node("Kaching").score_point(6);
					elif body.kaching_millionaire_enabled:
						get_tree().current_scene.get_node("Kaching").score_point(4);
					else: get_tree().current_scene.get_node("Kaching").score_point(3);
				3:
					if body.kaching_billionaire_enabled:
						get_tree().current_scene.get_node("Kaching").score_point(10);
					elif body.kaching_millionaire_enabled:
						get_tree().current_scene.get_node("Kaching").score_point(6);
					else: get_tree().current_scene.get_node("Kaching").score_point(5);
		queue_free();
