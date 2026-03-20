extends Node2D;


@export var type: int = -1;
var enemy: CharacterBody2D;
var move_right: bool = true;
var humpher_health: int = 10;


func _ready() -> void:
	match type:
		0:
			get_node("Enemy1").visible = true;
			enemy = get_node("Enemy1");
		1:
			get_node("Enemy2").visible = true;
			enemy = get_node("Enemy2");
		2:
			get_node("Enemy3").visible = true;
			enemy = get_node("Enemy3");
		3:
			get_node("TheHumpher").visible = true;
			enemy = get_node("TheHumpher");


func _physics_process(delta: float) -> void:
	if type != 3:
		var vel: VelocityComponent = enemy.get_node("VelocityComponent");
		
		match type:
			0:
				if enemy.velocity.x == 0:
					move_right = not move_right;
				
				if move_right:
					vel.accelerate_towards_x(1, delta);
				else:
					vel.accelerate_towards_x(-1, delta);
		
				vel.apply_gravity(enemy, delta);
			1:
				var closest_player;
				var closest_distance: float = 10000000000;
				
				for player in get_tree().current_scene.get_node("Players").get_children():
					var distance = enemy.global_position.distance_to(player.global_position);
					if distance < closest_distance:
						closest_distance = distance;
						closest_player = player;
				
				if closest_player.global_position.x > enemy.global_position.x:
					vel.accelerate_towards_x(1, delta);
				else:
					vel.accelerate_towards_x(-1, delta);
				if enemy.is_on_floor():
					await get_tree().create_timer(1).timeout;
					vel.jump()
				vel.apply_gravity(enemy, delta);
			2:
				var closest_player;
				var closest_distance: float = 10000000000;
				
				for player in get_tree().current_scene.get_node("Players").get_children():
					var distance = enemy.global_position.distance_to(player.global_position);
					if distance < closest_distance:
						closest_distance = distance;
						closest_player = player;
				
				var shot_direction = (closest_player.global_position - enemy.global_position).normalized();
				vel.accelerate_towards(shot_direction, delta);
		vel.move(enemy);
	else:
		if humpher_health < 1:
			var mango = load("res://scenes/components/minigames/secret/mango_lassi.tscn").instantiate();
			mango.global_position = Vector2(1000, 1400);
			get_tree().current_scene.get_node("MrTannersWrath").get_node("SecretEnemies").add_child(mango);
			queue_free();
