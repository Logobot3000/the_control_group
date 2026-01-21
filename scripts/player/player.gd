class_name Player;
extends CharacterBody2D;

## The path to the player's VelocityComponent.
@export_node_path("VelocityComponent") var velocity_component_path: NodePath;

## The actual VelocityComponent for the player found through [member velocity_component_path].
@onready var velocity_component: VelocityComponent = get_node(velocity_component_path);
## The sprite for the player.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D;
## The default CollisionShape2D for the player.
@onready var collision_shape: CollisionShape2D = $CollisionShape2D;
## The EMP stun area for the fishing minigame with the EMP modifier.
@onready var emp_area: Area2D = $EMPArea;
## The overlay CanvasLayer.
@onready var overlay: CanvasLayer = $Overlay;

## Determines if the player is currently being controlled by the client. Some functions may be restricted to a local or remote player.
var is_local: bool = false;
## The player's Steam ID.
var steam_id: int = 0;
## Determines whether or not the player is allowed to move. Affects jumping as well.
var can_move: bool = true;
## Determines whether or not the player is allowed to jump.
var can_jump: bool = true;
## The player's color index. -1 means no color index.
var player_color_index: int = -1;
## The current animation state of the player.
var animation_state: int = 0;
## Whether or not the fishing minigame is active.
var fishing_active: bool = false;
## Whether or not the space minigame is active.
var space_active: bool = false;
## Whether or not the plaeyer is in the experimental group.
var is_experimental: bool = false;
## Whether or not the player has the emp modifier in the fishing minigame.
var emp_enabled: bool = false;
## Whether or not the player is stunned.
var stunned: bool = false;
## Whether or not the player is dead.
var is_dead: bool = false;
## How fast the player rotates in freeflying mode
var rotate_speed: float = 0.05;
## Maximum amount of shots the player has in the space minigame.
var laser_shot_count_max: int = 3;
## How many shots the player has in the space minigame.
var laser_shot_count: int = 3;
## Whether or not the charge shot midifier is active in the space minigame.
var charge_shot_enabled: bool = false;
## super cool crouch super cool crouch super cool crouch super cool crouch super cool crouch super cool crouch
var super_cool_crouching: bool = false; 


func _ready() -> void:
	call_deferred("_set_sprite_color");
	get_node("HealthComponent").died.connect(die);


func _physics_process(delta: float) -> void:
	if is_local and can_move:
		if velocity_component.movement_mode == Enums.MovementMode.PLATFORMER:
			# Apply gravity
			velocity_component.apply_gravity(self, delta);
		
		if is_on_floor():
			velocity_component.halt_y();
		
		# Handle input
		var horizontal_input = Input.get_axis("move_left", "move_right");
		var vertical_input_freeflying = Input.get_axis("move_up", "move_down");
		var jump_input = Input.is_action_pressed("jump");
		var toggle_super_cool_crouch = Input.is_action_just_pressed("toggle_super_cool_crouch");
		
		if toggle_super_cool_crouch: super_cool_crouching = not super_cool_crouching;
		
		if velocity_component.movement_mode == Enums.MovementMode.PLATFORMER:
			if horizontal_input and not super_cool_crouching:
				velocity_component.accelerate_towards_x(horizontal_input, delta);
			else:
				velocity_component.decelerate_x(delta)
			if jump_input and is_on_floor() and not super_cool_crouching and can_jump:
				velocity_component.jump();
		else:
			if vertical_input_freeflying < 0 and not super_cool_crouching:
				velocity_component.accelerate_towards(Vector2.UP.rotated(rotation), delta);
			else:
				velocity_component.decelerate(delta * 0.1);
			if horizontal_input:
				rotate(horizontal_input * rotate_speed);
		
		# Apply velocity changes
		velocity_component.move(self);
	
	if fishing_active: 
		if is_experimental and is_local:
			collision_shape.shape.size.x = 27;
			collision_shape.shape.size.y = 23;
			collision_shape.position.x = -0.5;
			collision_shape.position.y = 4.5;
		else:
			collision_shape.shape.size.x = 10;
			collision_shape.shape.size.y = 15;
			collision_shape.position.x = 0;
			collision_shape.position.y = 0.5;
		super_cool_crouching = false;
	elif space_active:
		if is_experimental:
			if is_local:
				collision_shape.shape.size.x = 42;
				collision_shape.shape.size.y = 16;
				collision_shape.position.x = 0;
				collision_shape.position.y = 0;
		else:
			if not is_experimental and is_local:
				collision_shape.shape.size.x = 8;
				collision_shape.shape.size.y = 12;
				collision_shape.position.x = 1;
				collision_shape.position.y = -2;
	else:
		collision_shape.shape.size.x = 10;
		collision_shape.shape.size.y = 15;
		collision_shape.position.x = 0;
		collision_shape.position.y = 0.5;
	
	if fishing_active and is_experimental: set_sprite_direction(-velocity.x);
	else: set_sprite_direction(velocity.x);
	
	if is_local: 
		if not super_cool_crouching:
			if not space_active:
				if snapped(velocity.x, 100) == 0 and velocity.y == 0:
					if fishing_active: 
						if is_experimental: animation_state = 6;
						else: animation_state = 4;
					else: animation_state = 0;
				elif not is_on_floor() and !fishing_active:
					animation_state = 1;
				elif snapped(velocity.x, 100) != 0 and velocity.y == 0:
					if fishing_active: 
						if is_experimental: animation_state = 7;
						else: animation_state = 5;
					else: animation_state = 2;
			else:
				if is_experimental:
					if snapped(velocity.x, 35) == 0 and snapped(velocity.y, 35) == 0:
						animation_state = 8;
					else:
						animation_state = 9;
				else:
					if snapped(velocity.x, 35) == 0 and snapped(velocity.y, 35) == 0:
						animation_state = 10;
					else:
						animation_state = 11;
		else:
			animation_state = 3;
		_send_position_p2p();
	
	if space_active and is_local:
		if Input.is_action_just_pressed("jump"):
			var laser_data: Dictionary = {
				"message": "laser_fired",
				"steam_id": steam_id,
				"laser_type": 0,
				"shot_rotation": rotation,
				"position": global_position
			};
			Network.send_p2p_packet(0, laser_data);
			MinigameManager.laser_fired(laser_data);
	
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
		4:
			match player_color_index:
				-1:
					pass;
				0:
					sprite.play("still_control_boat_yellow");
				1:
					sprite.play("still_control_boat_green");
				2:
					sprite.play("still_control_boat_purple");
				3:
					sprite.play("still_control_boat_orange");
		5:
			match player_color_index:
				-1:
					pass;
				0:
					sprite.play("moving_control_boat_yellow");
				1:
					sprite.play("moving_control_boat_green");
				2:
					sprite.play("moving_control_boat_purple");
				3:
					sprite.play("moving_control_boat_orange");
		6:
			match player_color_index:
				-1:
					pass;
				0:
					sprite.play("still_experimental_boat_yellow");
				1:
					sprite.play("still_experimental_boat_green");
				2:
					sprite.play("still_experimental_boat_purple");
				3:
					sprite.play("still_experimental_boat_orange");
		7:
			match player_color_index:
				-1:
					pass;
				0:
					sprite.play("moving_experimental_boat_yellow");
				1:
					sprite.play("moving_experimental_boat_green");
				2:
					sprite.play("moving_experimental_boat_purple");
				3:
					sprite.play("moving_experimental_boat_orange");
		8:
			match player_color_index:
				-1:
					pass;
				0:
					if sprite.animation != "still_experimental_ship_yellow":
						sprite.play_backwards("transition_experimental_ship_yellow");
						await sprite.animation_finished;
						sprite.play("still_experimental_ship_yellow");
					else:
						sprite.play("still_experimental_ship_yellow");
				1:
					if sprite.animation != "still_experimental_ship_green":
						sprite.play_backwards("transition_experimental_ship_green");
						await sprite.animation_finished;
						sprite.play("still_experimental_ship_green");
					else:
						sprite.play("still_experimental_ship_green");
				2:
					if sprite.animation != "still_experimental_ship_purple":
						sprite.play_backwards("transition_experimental_ship_purple");
						await sprite.animation_finished;
						sprite.play("still_experimental_ship_purple");
					else:
						sprite.play("still_experimental_ship_purple");
				3:
					if sprite.animation != "still_experimental_ship_orange":
						sprite.play_backwards("transition_experimental_ship_orange");
						await sprite.animation_finished;
						sprite.play("still_experimental_ship_orange");
					else:
						sprite.play("still_experimental_ship_orange");
		9:
			match player_color_index:
				-1:
					pass;
				0:
					if sprite.animation != "moving_experimental_ship_yellow":
						sprite.play("transition_experimental_ship_yellow");
						await sprite.animation_finished;
						sprite.play("moving_experimental_ship_yellow");
					else:
						sprite.play("moving_experimental_ship_yellow");
				1:
					if sprite.animation != "moving_experimental_ship_green":
						sprite.play("transition_experimental_ship_green");
						await sprite.animation_finished;
						sprite.play("moving_experimental_ship_green");
					else:
						sprite.play("moving_experimental_ship_green");
				2:
					if sprite.animation != "moving_experimental_ship_purple":
						sprite.play("transition_experimental_ship_purple");
						await sprite.animation_finished;
						sprite.play("moving_experimental_ship_purple");
					else:
						sprite.play("moving_experimental_ship_purple");
				3:
					if sprite.animation != "moving_experimental_ship_orange":
						sprite.play("transition_experimental_ship_orange");
						await sprite.animation_finished;
						sprite.play("moving_experimental_ship_orange");
					else:
						sprite.play("moving_experimental_ship_orange");
		10:
			match player_color_index:
				-1:
					pass;
				0:
					if sprite.animation != "still_control_ship_yellow":
						sprite.play_backwards("transition_control_ship_yellow");
						await sprite.animation_finished;
						sprite.play("still_control_ship_yellow");
					else:
						sprite.play("still_control_ship_yellow");
				1:
					if sprite.animation != "still_control_ship_green":
						sprite.play_backwards("transition_control_ship_green");
						await sprite.animation_finished;
						sprite.play("still_control_ship_green");
					else:
						sprite.play("still_control_ship_green");
				2:
					if sprite.animation != "still_control_ship_purple":
						sprite.play_backwards("transition_control_ship_purple");
						await sprite.animation_finished;
						sprite.play("still_control_ship_purple");
					else:
						sprite.play("still_control_ship_purple");
				3:
					if sprite.animation != "still_control_ship_orange":
						sprite.play_backwards("transition_control_ship_orange");
						await sprite.animation_finished;
						sprite.play("still_control_ship_orange");
					else:
						sprite.play("still_control_ship_orange");
		11:
			match player_color_index:
				-1:
					pass;
				0:
					if sprite.animation != "moving_control_ship_yellow":
						sprite.play("transition_control_ship_yellow");
						await sprite.animation_finished;
						sprite.play("moving_control_ship_yellow");
					else:
						sprite.play("moving_control_ship_yellow");
				1:
					if sprite.animation != "moving_control_ship_green":
						sprite.play("transition_control_ship_green");
						await sprite.animation_finished;
						sprite.play("moving_control_ship_green");
					else:
						sprite.play("moving_control_ship_green");
				2:
					if sprite.animation != "moving_control_ship_purple":
						sprite.play("transition_control_ship_purple");
						await sprite.animation_finished;
						sprite.play("moving_control_ship_purple");
					else:
						sprite.play("moving_control_ship_purple");
				3:
					if sprite.animation != "moving_control_ship_orange":
						sprite.play("transition_control_ship_orange");
						await sprite.animation_finished;
						sprite.play("moving_control_ship_orange");
					else:
						sprite.play("moving_control_ship_orange");


## Local-only: Sends a P2P packet containing the position of the player.
func _send_position_p2p() -> void:
	var packet: Dictionary = {
		"message": "player_position",
		"steam_id": steam_id, 
		"position": global_position, 
		"velocity": velocity,
		"rotation": rotation,
		"super_cool_crouching": super_cool_crouching,
		"is_on_floor": is_on_floor()
	};
	Network.send_p2p_packet(0, packet);


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("use_ability"):
		if emp_enabled and fishing_active and is_experimental and is_local:
			use_emp_ability();


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


## Sets the sprite direciton.
func set_sprite_direction(vel_x: float):
	if snapped(vel_x, 50) != 0:
		sprite.flip_h = sign(vel_x) <= 0;


## Sets the saturation level of the grayscale overlay.
func set_grayscale_overlay(saturation: float):
	overlay.get_node("GrayscaleOverlay").material.set_shader_parameter("saturation", saturation);


## Sets whether or not a player is stunned.
func stun(time: int):
	stunned = true;
	can_move = false;
	set_grayscale_overlay(0.5);
	if fishing_active:
		get_node("HookComponent").raise_hook(false);
		get_node("HookComponent").can_lower = false;
	
	await get_tree().create_timer(time).timeout;
	
	unstun();


## Undoes a stun
func unstun():
	stunned = false;
	can_move = true;
	set_grayscale_overlay(1);
	if fishing_active:
		get_node("HookComponent").can_lower = true;


## Dies
func die():
	if is_local:
		is_dead = true;
		can_move = false;
		visible = false;
		set_grayscale_overlay(0);


## Un-dies
func revive():
	if is_local:
		is_dead = false;
		can_move = true;
		visible = true;
		set_grayscale_overlay(1);


## Uses the EMP ability in the fishing minigame.
func use_emp_ability():
	if emp_enabled and fishing_active and is_experimental:
		emp_enabled = false;
		var ships = emp_area.get_overlapping_bodies();
		var ship_count: int = 0;
		for player in ships:
			ship_count += 1;
			if player.steam_id != steam_id:
				Network.send_p2p_packet(player.steam_id, { "message": "stun", "time": 6 });
				player.get_node("HookComponent").raise_hook(false);
		do_emp_particles();
		emp_rod_upgrade(ship_count);
		await get_tree().create_timer(20).timeout;
		emp_enabled = true;


## The temporary rod upgrade for the player using the EMP ability.
func emp_rod_upgrade(ships: int):
	if get_node("HookComponent"):
		get_node("HookComponent").lower_weight += 0.025 * ships;
		get_node("HookComponent").raise_weight += 0.025 * ships;
	await get_tree().create_timer(6).timeout;
	if get_node("HookComponent"):
		get_node("HookComponent").lower_weight -= 0.025 * ships;
		get_node("HookComponent").raise_weight -= 0.025 * ships;


## Does the EMP particle effect for the fishing minigame.
func do_emp_particles():
	var emp_particle_msg: Dictionary = {
		"message": "emp_particles",
		"steam_id": Main.player_steam_id
	};
	Network.send_p2p_packet(0, emp_particle_msg);
	emp_area.get_node("Particles").emitting = true;
