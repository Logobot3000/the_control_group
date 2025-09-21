extends Node;

## A component that allows the storage and manipulation of a velocity (Vector2).
class_name VelocityComponent;


## Controls what movement mode the VelocityComponent uses. Additionally safeguards certain functions and attributes from being used in the wrong movement mode. Default [member PLATFORMER].
@export var movement_mode: Enums.MovementMode = Enums.MovementMode.PLATFORMER;

@export_group("General Settings")
## Controls the maximum speed the VelocityComponent can reach. Default 150.0.
@export var max_speed: float = 150;
## Controls the acceleration coefficient in velocity equations (how fast the VelocityComponent can reach [member max_speed]). Default 20.0.
@export var acceleration: float = 20;

@export_group("Platformer-Specific Settings")
## Platformer-specific: controls the velocity that each jump has initially. Default 450.0.
@export var jump_strength: float = 450;
## Platformer-specific: controls the scale of the gravity that is used. Default 1.0. Note: Internally, the gravity value should be multiplied by 100 and the [member GRAV_CONSTANT] to function correctly.
@export var gravity: float = 1;

## The stored velocity value in the VelocityComponent.
var velocity: Vector2 = Vector2.ZERO;
## An override to [member velocity], replaces it if the value is not Vector2.ZERO.
var velocity_override: Vector2 = Vector2.ZERO;
## A multiplier to [member max_speed] in certain equations, used if there is a temporary speed boost or something.
var speed_multiplier: float = 1;
## A multiplier to [member acceleration] in certain equations, most likely to be used in conjunction with [member speed_multiplier].
var acceleration_multiplier: float = 1;


## Sets the internal speed multiplier to [member multiplier].
func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = multiplier;


## Sets the internal acceleration multiplier to [member multiplier].
func set_acceleration_multiplier(multiplier: float) -> void:
	acceleration_multiplier = multiplier;


## Sets the internal velocity override to [member override].
func set_velocity_override(override: Vector2) -> void:
	velocity_override = override;


## Resets the internal speed multiplier.
func reset_speed_multiplier() -> void:
	speed_multiplier = 1;


## Resets the internal acceleration multiplier.
func reset_acceleration_multiplier() -> void:
	acceleration_multiplier = 1;


## Resets the internal velocity override.
func reset_velocity_override() -> void:
	velocity_override = Vector2.ZERO;


## Freeflying-specific: accelerate towards [member direction].
func accelerate_towards(direction: Vector2, delta: float) -> void:
	if movement_mode == Enums.MovementMode.FREEFLYING:
		velocity.lerp(direction * max_speed * speed_multiplier, acceleration * acceleration_multiplier * delta);

## Platformer-specific: accelerate only velocity.x towards [member axis].
func accelerate_towards_x(axis: float, delta: float) -> void:
	if movement_mode == Enums.MovementMode.PLATFORMER:
		velocity.x = lerpf(velocity.x, axis * max_speed * speed_multiplier, acceleration * acceleration_multiplier * delta);


## No restrictions: decelerates velocity to Vector2.ZERO.
func decelerate(delta: float) -> void:
	velocity.lerp(Vector2.ZERO, acceleration * acceleration_multiplier * delta);


## No restrictions: decelerates velocity.x to 0.0.
func decelerate_x(delta: float) -> void:
	velocity.x = lerpf(velocity.x, 0.0, acceleration * acceleration_multiplier * delta);


## No restrictions: immediately sets velocity.x to 0.0.
func halt_x() -> void:
	velocity.x = 0;


## No restrictions: immediately sets velocity.y to 0.0.
func halt_y() -> void:
	velocity.y = 0;


## Platformer-only: tests if [member character_body] is currently falling. Will return false if [member movement_mode] is [member FREEFLYING].
func is_falling(character_body: CharacterBody2D) -> bool:
	return movement_mode == Enums.MovementMode.PLATFORMER and velocity.y > 0 and not character_body.is_on_floor();


## Platformer-only: tests if [member character_body] is currently jumping. Will return false if [member movement_mode] is [member FREEFLYING].
func is_jumping(character_body: CharacterBody2D) -> bool:
	return movement_mode == Enums.MovementMode.PLATFORMER and velocity.y < 0 and not character_body.is_on_floor();


## Platformer-only: Applies gravity if the player is currently not on the floor.
func apply_gravity(character_body: CharacterBody2D, delta: float) -> void:
	if movement_mode == Enums.MovementMode.PLATFORMER and not character_body.is_on_floor():
		velocity.y += (gravity * 100) * delta * acceleration;
		velocity.y = clampf(velocity.y, (gravity * 100) * delta * acceleration * max_speed * speed_multiplier * -1 * Constants.GRAV_CONSTANT, (gravity * 100) * delta * acceleration * max_speed * speed_multiplier * Constants.GRAV_CONSTANT);


## Platformer-only: Performs a jump (by setting the velocity.y value to negative [member jump_strength]
func jump() -> void:
	if movement_mode == Enums.MovementMode.PLATFORMER:
		velocity.y = -jump_strength;


## No restrictions: sets the velocity of [member character_body] to the stored velocity and calls the move_and_slide() function on it.
func move(character_body: CharacterBody2D) -> void:
	character_body.velocity = velocity_override if velocity_override else velocity;
	character_body.move_and_slide();
