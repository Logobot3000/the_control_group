extends Area2D;

## A component that allows for easy interaction with a HealthComponent. Requires a HurtboxCollisionShape2D for use (just a pre-colored CollisionShape2D).
class_name HurtboxComponent;


## Emits when the HurtboxComponent is damaged.
signal damaged(damage: float);


## Controls the node path to a HealthComponent for updating health.
@export_node_path("HealthComponent") var health_component_path: NodePath;
## Controls whether the HurtboxComponent can recieve damage.
@export var invulnerable = false;

## Uses [member health_component_path] to get the actual HealthComponent.
@onready var health_component: HealthComponent = get_node(health_component_path);


## Applies [member damage] amount of damage to the HealthComponent.
func apply_damage(damage: float) -> void:
	if health_component:
		if invulnerable:
			damage = 0;
		health_component.damage(damage);
		damaged.emit(damage);


# Update with actual logic later
func _on_area_entered(area: Area2D) -> void:
	pass;
