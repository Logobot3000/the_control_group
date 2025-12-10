class_name FishComponent;
extends CharacterBody2D;

## Determines whether the fish is a jellyfish or not.
@export var is_jellyfish: bool = false;
## The color of the fish.
@export var color: int = 0;
## Determines which side the fish spawns on.
@export var spawn_from_right: bool = true;

## The AnimatedSprite2D for animations.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D;

## The time alive for the fish (in frames)
var time_alive: float = 0.0;
## Determines whether the fish is attached to a hook.
var hooked: bool = false;
## The HookComponent the fish is currently attached to (if it is attached to anything)
var attached_hook: HookComponent = null;


func _ready() -> void:
	if is_jellyfish:
		sprite.play("jellyfish");
		sprite.rotation_degrees = 90;
		sprite.flip_v = spawn_from_right;
	else:
		match color:
			0:
				sprite.play("black");
			1:
				sprite.play("blue");
			2:
				sprite.play("green");
			3:
				sprite.play("purple");
			4:
				sprite.play("red");
			5:
				sprite.play("yellow");
		sprite.flip_h = spawn_from_right;


func _physics_process(delta: float) -> void:
	var velocity_component: VelocityComponent = $VelocityComponent;
	if not hooked:
		var velocity_h: int = 0;
		if spawn_from_right: velocity_h = -1;
		else: velocity_h = 1;
		
		time_alive += 0.1;
		var direction: Vector2 = Vector2(velocity_h, sin(time_alive));
		velocity_component.accelerate_towards(direction, delta);
		velocity_component.move(self);
	else:
		global_position = attached_hook.global_position;


func _on_hitbox_area_entered(hook_component) -> void:
	if hook_component.hook_catch_limit > hook_component.fish_currently_caught:
		attached_hook = hook_component;
		hooked = true;
		hook_component.fish_currently_caught += 1;
