extends CharacterBody2D


@export var laser_type: int = 0;

@onready var sprite = $AnimatedSprite2D;
@onready var collision_shape = $CollisionShape2D;
@onready var collision_shape_2 = $Area2D/CollisionShape2D;

var damage = 5;
var shot_rotation: float = 0;
var steam_id = 0;


func _process(delta: float) -> void:
	change_laser_type(laser_type);
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
			if MinigameManager.current_control_group.has(body.steam_id) and MinigameManager.current_control_group.has(steam_id):
				pass;
			else:
				body.get_node("HealthComponent").damage(damage);
				print(body.get_node("HealthComponent").health, body.get_node("HealthComponent").is_dead());
				if body.steam_id == Main.player_steam_id:
					body.get_node("Overlay/HurtOverlay/AnimationPlayer").stop()
					body.get_node("Overlay/HurtOverlay/AnimationPlayer").play("go");
				if Main.player_steam_id == steam_id and body.get_node("HealthComponent").is_dead():
					print(":3333 :33 :33333333")
					if body.is_experimental == true:
						get_tree().current_scene.get_node("Space").score_point(5);
					else:
						get_tree().current_scene.get_node("Space").score_point(1);
				queue_free();
	elif body == self:
		pass;
	else:
		queue_free();
