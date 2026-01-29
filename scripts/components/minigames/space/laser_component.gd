extends CharacterBody2D


@export var laser_type: int = 0;

@onready var sprite = $AnimatedSprite2D;
@onready var collision_shape = $CollisionShape2D;
@onready var collision_shape_2 = $Area2D/CollisionShape2D;

var damage = 5;
var shot_rotation: float = 0;
var steam_id = 0;
var tracking_active: bool = true;
var closest_player: Player = null;


func _process(delta: float) -> void:
	change_laser_type(laser_type);
	if tracking_active:
		var closest_distance: float = 10000000000;
		for player in get_tree().current_scene.get_node("Players").get_children():
			if player.steam_id != steam_id:
				var distance = global_position.distance_to(player.global_position);
				if distance < closest_distance:
					closest_distance = distance;
					closest_player = player;
				if distance < 20:
					tracking_active = false;
	if tracking_active:
		get_node("VelocityComponent").accelerate_towards((closest_player.global_position - global_position).normalized(), delta);
	else:
		get_node("VelocityComponent").accelerate_towards(Vector2.UP.rotated(shot_rotation), delta);
	get_node("VelocityComponent").move(self);


## Change the type of the laser
func change_laser_type(type: int) -> void:
	match type:
		1: 
			sprite.play("default");
			collision_shape_2.shape.radius = 2;
			damage = 5;
		2:
			sprite.play("charge_shot_medium");
			collision_shape_2.shape.radius = 4;
			damage = 10;
		3:
			sprite.play("charge_shot_large");
			collision_shape_2.shape.radius = 6;
			damage = 15;


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.get_parent().name == "Players":
		if body.steam_id != steam_id:
			if not (MinigameManager.current_control_group.has(body.steam_id) and MinigameManager.current_control_group.has(steam_id)):
				if not body.get_node("HealthComponent").is_dead():
					body.get_node("HealthComponent").damage(damage);
					if body.steam_id == Main.player_steam_id:
						body.get_node("Overlay/HurtOverlay/AnimationPlayer").stop()
						body.get_node("Overlay/HurtOverlay/AnimationPlayer").play("go");
				if Main.player_steam_id == steam_id:
					if body.get_node("HealthComponent").is_dead():
						if body.steam_id == MinigameManager.current_experimental_group:
							get_tree().current_scene.get_node("Space").score_point(5);
						else:
							get_tree().current_scene.get_node("Space").score_point(1);
				queue_free();
	elif body == self:
		pass;
	else:
		queue_free();
