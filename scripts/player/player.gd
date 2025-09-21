class_name Player;
extends CharacterBody2D;

## The path to the player's VelocityComponent.
@export_node_path("VelocityComponent") var velocity_component_path: NodePath;

## The actual VelocityComponent for the player found through [member velocity_component_path].
@onready var velocity_component: VelocityComponent = get_node(velocity_component_path);

## Determines if the player is currently being controlled by the client. Some functions may be restricted to a local or remote player.
var is_local: bool = false;
## The player's Steam ID.
var steam_id: int = 0;


func _physics_process(delta: float) -> void:
	if is_local:
		# Apply gravity
		velocity_component.apply_gravity(self, delta);
		
		if is_on_floor():
			velocity_component.halt_y();
		
		# Handle input
		var horizontal_input = Input.get_axis("move_left", "move_right");
		var vertical_input = Input.is_action_pressed("jump");
		
		if horizontal_input:
			velocity_component.accelerate_towards_x(horizontal_input, delta);
		else:
			velocity_component.decelerate_x(delta);
		
		if vertical_input and is_on_floor():
			velocity_component.jump();
		
		# Apply velocity changes
		velocity_component.move(self);


## Local-only: Sends a P2P packet containing the position of the player.
func _send_position_p2p() -> void:
	var packet: Dictionary = {"message": "player_position", "steam_id": steam_id, "position": global_position};
	Network.send_p2p_packet(0, packet);


## Gets [member steam_id].
func get_steam_id() -> int:
	return steam_id;


## Gets [member is_local].
func get_is_local() -> bool:
	return is_local;


## Sets [member steam_id].
func set_steam_id(id: int) -> void:
	steam_id = id;


## Sets [member is_local].
func set_is_local(local: bool) -> void:
	is_local = local;
