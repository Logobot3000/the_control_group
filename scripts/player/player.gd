class_name Player;
extends CharacterBody2D;

## The path to the player's VelocityComponent.
@export_node_path("VelocityComponent") var velocity_component_path: NodePath;

## The actual VelocityComponent for the player found through [member velocity_component_path].
@onready var velocity_component: VelocityComponent = get_node(velocity_component_path);
## The sprite for the player.
@onready var sprite: Sprite2D = $Sprite2D;

## Determines if the player is currently being controlled by the client. Some functions may be restricted to a local or remote player.
var is_local: bool = false;
## The player's Steam ID.
var steam_id: int = 0;


func _ready() -> void:
	call_deferred("_set_sprite_color");


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
		
		_send_position_p2p();
	else: velocity_component.move(self);


## Local-only: Sends a P2P packet containing the position of the player.
func _send_position_p2p() -> void:
	var packet: Dictionary = {"message": "player_position", "steam_id": steam_id, "position": global_position, "velocity": velocity};
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


## _set_sprite_color(), bot to be called by network.gd.
func update_sprite_colors() -> void:
	_set_sprite_color();


## Set's the player's sprite color based on join order.
func _set_sprite_color() -> void:
	var sorted_players: Array = [];
	
	if not Network.use_local_networking:
		for member in Network.lobby_members:
			sorted_players.append(member["steam_id"]);
	else:
		if Network.lobby_members.size() > 0:
			for member in Network.lobby_members:
				if member["steam_id"] == 1:
					sorted_players.append(1);
					break;
			var other_players: Array = [];
			for member in Network.lobby_members:
				if member["steam_id"] != 1:
					other_players.append(member["steam_id"]);
			other_players.sort();
			sorted_players.append_array(other_players);
	
	var player_index = 0;
	for i in range(sorted_players.size()):
		if sorted_players[i] == steam_id:
			player_index = i;
			break;
	player_index = player_index % 4;
	
	var atlas_texture = AtlasTexture.new();
	atlas_texture.atlas = sprite.texture.atlas if sprite.texture is AtlasTexture else sprite.texture;
	atlas_texture.region = Rect2(player_index * 16, 0, 16, 16);
	
	sprite.texture = atlas_texture;
