extends CharacterBody2D


@export var laser_type: int = 0;

@onready var sprite = $AnimatedSprite2D;
@onready var collision_shape = $CollisionShape2D;

var damage = 5;


func _process(delta: float) -> void:
	change_laser_type(laser_type);


## Change the type of the laser
func change_laser_type(type: int) -> void:
	match type:
		1: 
			sprite.play("default");
			collision_shape.shape.radius = 1;
			damage = 5;
		2:
			sprite.play("charge_shot_medium");
			collision_shape.shape.radius = 3;
			damage = 10;
		3:
			sprite.play("charge_shot_large");
			collision_shape.shape.radius = 5;
			damage = 15;
