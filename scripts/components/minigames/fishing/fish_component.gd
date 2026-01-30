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
## The HookComponent the fish is currently attached to (if it is attached to anything).
var attached_hook: HookComponent = null;
## The HookComponent that the fish is currently attracted to (if it is attracted to anything).
var lured_hook: HookComponent = null;
## The time scaling for the sine wave.
var time_scale: float = 0.1;
## The max velocity for the fish.
var fish_speed: float;


func _ready() -> void:
	get_node("VelocityComponent").max_speed = fish_speed;
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
		if lured_hook:
			if lured_hook.fish_currently_caught > 0:
				lured_hook = null;
				velocity_component.halt_x();
				velocity_component.halt_y();
				velocity_component.set_speed_multiplier(1);
		
		var velocity_h: int = 0;
		if spawn_from_right: velocity_h = -1;
		else: velocity_h = 1;
		
		time_alive += time_scale;
		var direction: Vector2;
		if lured_hook:
			direction = lured_hook.hook_base.global_position - global_position;
			direction = direction.normalized();
			velocity_component.set_speed_multiplier(4);
		else:
			direction = Vector2(velocity_h, sin(time_alive));
		velocity_component.accelerate_towards(direction, delta);
		velocity_component.move(self);
	else:
		if not attached_hook:
			attached_hook = null;
			return;
		global_position = attached_hook.hook_base.global_position;
		if global_position.y <= 1050:
			attached_hook.fish_currently_caught -= 1;
			if attached_hook.get_parent().is_local:
				if is_jellyfish:
					if attached_hook.hook_type == Enums.HookType.ANTIVENOM:
						get_tree().current_scene.get_node("Fishing").score_point(1);
					elif attached_hook.hook_type == Enums.HookType.NET:
						pass;
					else:
						get_tree().current_scene.get_node("Fishing").score_point(-1);
				else:
					get_tree().current_scene.get_node("Fishing").score_point(1);
			queue_free();


func _on_hitbox_area_entered(hook_component) -> void:
	if hooked: return;
	if hook_component.hook_catch_limit > hook_component.fish_currently_caught:
		if not hook_component.raising or hook_component.hook_type == Enums.HookType.NET:
			attached_hook = hook_component;
			hooked = true;
			hook_component.fish_currently_caught += 1;


func _on_lure_area_body_entered(hook_component) -> void:
	if hooked: return;
	if hook_component.hook_type == Enums.HookType.LURE and not is_jellyfish and not hook_component.raising:
		lured_hook = hook_component;


func _on_lure_area_body_exited(hook_component) -> void:
	if lured_hook and hook_component.hook_type == Enums.HookType.LURE:
		var velocity_component: VelocityComponent = $VelocityComponent;
		lured_hook = null;
		velocity_component.halt_x();
		velocity_component.halt_y();
		velocity_component.set_speed_multiplier(1);
