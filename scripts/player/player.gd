class_name Player;
extends CharacterBody2D;

## The path to the player's VelocityComponent.
@export_node_path("VelocityComponent") var velocity_component_path: NodePath;

## The actual VelocityComponent for the player found through [member velocity_component_path].
@onready var velocity_component: VelocityComponent = get_node(velocity_component_path);
## The sprite for the player.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D;

## Determines if the player is currently being controlled by the client. Some functions may be restricted to a local or remote player.
var is_local: bool = false;
## The player's Steam ID.
var steam_id: int = 0;
## Determines whether or not the player is allowed to move.
var can_move: bool = true;
## The player's color index. -1 means no color index.
var player_color_index: int = -1;
## The current animation state of the player.
var animation_state: int = 0;
## super cool crouch super cool crouch super cool crouch super cool crouch super cool crouch super cool crouch
var super_cool_crouching: bool = false; 


func _ready() -> void:
	call_deferred("_set_sprite_color");


func _physics_process(delta: float) -> void:
	if is_local and can_move:
		# Apply gravity
		velocity_component.apply_gravity(self, delta);
		
		if is_on_floor():
			velocity_component.halt_y();
		
		# Handle input
		var horizontal_input = Input.get_axis("move_left", "move_right");
		var vertical_input = Input.is_action_pressed("jump");
		var toggle_super_cool_crouch = Input.is_action_just_pressed("toggle_super_cool_crouch");
		
		if toggle_super_cool_crouch: super_cool_crouching = not super_cool_crouching;
		
		if horizontal_input and not super_cool_crouching:
			velocity_component.accelerate_towards_x(horizontal_input, delta);
		else:
			velocity_component.decelerate_x(delta);
		
		if vertical_input and is_on_floor() and not super_cool_crouching:
			velocity_component.jump();
		
		# Apply velocity changes
		velocity_component.move(self);
		
	else: 
		velocity_component.apply_gravity(self, delta);
		if is_on_floor():
			velocity_component.halt_y();
		velocity_component.decelerate_x(delta);
		velocity_component.move(self);
	
	if is_local: 
		_send_position_p2p();
		set_sprite_direction(velocity.x);
		
		if not super_cool_crouching:
			if snapped(velocity.x, 100) == 0 and velocity.y == 0:
				animation_state = 0;
			elif not is_on_floor():
				animation_state = 1;
			elif snapped(velocity.x, 100) != 0 and velocity.y == 0:
				animation_state = 2;
		else:
			animation_state = 3;
		
	match animation_state:
		0:
			match player_color_index:
				-1:
					pass;
				0:
					sprite.play("still_character_yellow");
				1:
					sprite.play("still_character_green");
				2:
					sprite.play("still_character_purple");
				3:
					sprite.play("still_character_orange");
		1:
			match player_color_index:
				-1:
					pass;
				0:
					sprite.play("jump_character_yellow");
				1:
					sprite.play("jump_character_green");
				2:
					sprite.play("jump_character_purple");
				3:
					sprite.play("jump_character_orange");
		2:
			match player_color_index:
				-1:
					pass;
				0:
					sprite.play("walking_character_yellow");
				1:
					sprite.play("walking_character_green");
				2:
					sprite.play("walking_character_purple");
				3:
					sprite.play("walking_character_orange");
		3:
			match player_color_index:
				-1:
					pass;
				0:
					sprite.play("super_cool_crouch_character_yellow");
				1:
					sprite.play("super_cool_crouch_character_green");
				2:
					sprite.play("super_cool_crouch_character_purple");
				3:
					sprite.play("super_cool_crouch_character_orange");


## Local-only: Sends a P2P packet containing the position of the player.
func _send_position_p2p() -> void:
	var packet: Dictionary = {
		"message": "player_position",
		"steam_id": steam_id, 
		"position": global_position, 
		"velocity": velocity,
		"super_cool_crouching": super_cool_crouching
	};
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
	player_color_index = player_index;


func set_sprite_direction(vel_x: float):
	if snapped(vel_x, 50) != 0:
		sprite.flip_h = sign(vel_x) <= 0;
