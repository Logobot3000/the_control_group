extends Node;

## A component that allows the storage and manipulation of a health value (float).
class_name HealthComponent;


## Emits when health reaches 0.
signal died;
## Emits whenever health is updated.
signal health_updated(updated_health: float, updated_max_health: float);


## Controls the maximum amount of health the HealthComponent can store.
@export var max_health: float = 3;

## The stored health value in the HealthComponent.
var health: float = max_health;


## Clamps health between 0 and [member max_health], and dies if health < 0.
func _clamp_health() -> void:
	health = clamp(health, 0, max_health);
	if health == 0:
		died.emit();


## Deals [member damage] amount damage to health.
func damage(damage: float) -> void:
	health -= damage;
	_clamp_health();
	health_updated.emit(health, max_health);


## Heals [member heal] amount of health.
func heal(heal: float) -> void:
	damage(-heal);


## Returns whether or not health is equal to 0.
func is_dead() -> bool:
	return health == 0;


## Returns the current value of health.
func get_health() -> float:
	return health;
	

## Immediately updates health to [member val].
func set_health(val: float) -> void:
	health = val;
	_clamp_health();
	health_updated.emit(health, max_health);
