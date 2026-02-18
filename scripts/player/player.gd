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
## Whether or not the juggernaut minigame is active.
var juggernaut_active: bool = false;
## Whether or not the archery minigame is active.
var archery_active: bool = false;
## Whether or not the collector minigame is active.
var collector_active: bool = false;

## Whether or not the plaeyer is in the experimental group.
var is_experimental: bool = false;

## Whether or not the player is stunned.
var stunned: bool = false;
## Whether or not the player is dead.
var is_dead: bool = false;

## Whether or not the player has the emp modifier in the fishing minigame.
var emp_enabled: bool = false;

## How fast the player rotates in freeflying mode
var rotate_speed: float = 0.05;
## Maximum amount of shots the player has in the space minigame.
var laser_shot_count_max: int = 3;
## How many shots the player has in the space minigame.
var laser_shot_count: int = 3;
## How many shots the player has in the space minigame.
var laser_reload_time: float = 1.0;
## Whether or not the charge shot midifier is active in the space minigame.
var charge_shot_enabled: bool = false;
## Whether or not the tracking lasers midifier is active in the space minigame.
var tracking_lasers_enabled: bool = false;

## Whether or not the extra life modifier is active in the juggernaut minigame.
var juggernaut_extra_life: bool = false;
## Whether or not the speed boost modifier is active in the juggernaut minigame.
var juggernaut_speed_boost_enabled: bool = false;
## The speed boost cooldown for the modifiers in the juggernaut minigame.
var juggernaut_cooldown: bool = false;
## Whether or not the sketchy teleportation modifier is active in the juggernaut minigame.
var juggernaut_sketchy_tp_enabled: bool = false;
## Whether or not the sketchy teleportation modifier is active in the juggernaut minigame.
var juggernaut_sketchy_tp_uses: int = 3;
## Whether or not the stun mines modifier is active in the juggernaut minigame.
var juggernaut_stun_mines_enabled: bool = false;

## Arrow shot cooldown time in the archery minigame.
var arrow_cooldown_time: float = 1.0;
## Arrow shot cooldown in the archery minigame.
var arrow_cooldown: bool = false;
## Whether or not the mineral deposit modifier is active in the archery minigame.
var archery_mineral_deposit_enabled: bool = false;
## Whether or not the big clicker modifier is active in the archery minigame.
var archery_big_clicker_enabled: bool = false;
## Whether or not the big clicker modifier is active in the archery minigame.
var archery_big_clicker_timer_active: bool = false;
## Big clicker modifier amount in the archery minigame.
var archery_big_clicker_amt: int = 0;
## Whether or not the intentional misfire modifier is active in the archery minigame.
var archery_intentional_misfire_enabled: bool = false;
## Whether or not the intentional misfire modifier is on cooldown in the archery minigame.
var archery_intentional_misfire_cooldown: int = false;
## Whether or not the jackpot modifier is active in the archery minigame.
var archery_jackpot_enabled: bool = false;
## Whether or not the midas touch modifier is active in the archery minigame.
var archery_midas_touch_enabled: bool = false;

## Whether or not the ball master modifier is active in the collector minigame.
var collector_ball_master_enabled: bool = false;
## Whether or not the ball bomb modifier is active in the collector minigame.
var collector_ball_bomb_enabled: bool = false;
## Whether or not the ball bomb modifier cooldown is active in the collector minigame.
var collector_ball_bomb_cooldown: bool = false;
## Whether or not the baller modifier is active in the collector minigame.
var collector_baller_enabled: bool = false;
## Whether or not the baller modifier cooldown is active in the collector minigame.
var collector_baller_cooldown: bool = false;
## Whether or not the ball connoisseur modifier is active in the collector minigame.
var collector_ball_connoisseur_enabled: bool = false;
## Whether or not the novelty balls modifier is active in the collector minigame.
var collector_novelty_balls_enabled: bool = false;

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
	
	if fishing_active and is_experimental: set_sprite_direction(-velocity.x);
	else: set_sprite_direction(velocity.x);
	
	if is_local: 
		if not super_cool_crouching:
			if not space_active:
				if snapped(velocity.x, 100) == 0 and velocity.y == 0:
					if fishing_active: 
						if is_experimental: animation_state = 6;
						else: animation_state = 4;
					elif juggernaut_active and is_experimental:
						animation_state = 12;
					else: animation_state = 0;
				elif not is_on_floor() and !fishing_active:
					if juggernaut_active and is_experimental:
						animation_state = 13;
					else:
						animation_state = 1;
				elif snapped(velocity.x, 100) != 0 and velocity.y == 0:
					if fishing_active: 
						if is_experimental: animation_state = 7;
						else: animation_state = 5;
					elif juggernaut_active and is_experimental:
						animation_state = 14;
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
	
	collision_shape_update();
	
	if space_active and is_local:
		if Input.is_action_just_pressed("jump"):
			if not charge_shot_enabled:
				if laser_shot_count > 0:
					var laser_data: Dictionary = {
						"message": "laser_fired",
						"steam_id": steam_id,
						"laser_type": 0,
						"shot_rotation": rotation,
						"position": global_position,
						"tracking": tracking_lasers_enabled
					};
					Network.send_p2p_packet(0, laser_data);
					MinigameManager.laser_fired(laser_data);
					get_node("Overlay/LaserShotGUI/Laser" + str(laser_shot_count)).play("empty");
					laser_shot_count -= 1;
			else:
				if laser_shot_count == 3:
					var laser_data: Dictionary = {
						"message": "laser_fired",
						"steam_id": steam_id,
						"laser_type": 3,
						"shot_rotation": rotation,
						"position": global_position,
						"tracking": tracking_lasers_enabled
					};
					Network.send_p2p_packet(0, laser_data);
					MinigameManager.laser_fired(laser_data);
					get_node("Overlay/LaserShotGUI/Laser1").play("empty");
					get_node("Overlay/LaserShotGUI/Laser2").play("empty");
					get_node("Overlay/LaserShotGUI/Laser3").play("empty");
					laser_shot_count -= 3;
		if Input.is_action_just_pressed("use_ability"):
			if laser_shot_count > 0:
				pass
			else:
				for sprite in get_node("Overlay/LaserShotGUI").get_children():
					if laser_reload_time != 1.0:
						sprite.play("charging", 2.0);
					else:
						sprite.play("charging");
				await get_tree().create_timer(laser_reload_time).timeout;
				for sprite in get_node("Overlay/LaserShotGUI").get_children():
					sprite.play("full");
				laser_shot_count = laser_shot_count_max;
	
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
		12:
			match player_color_index:
				-1:
					pass;
				0:
					sprite.play("still_juggernaut_yellow");
				1:
					sprite.play("still_juggernaut_green");
				2:
					sprite.play("still_juggernaut_purple");
				3:
					sprite.play("still_juggernaut_orange");
		13:
			match player_color_index:
				-1:
					pass;
				0:
					sprite.play("falling_juggernaut_yellow");
				1:
					sprite.play("falling_juggernaut_green");
				2:
					sprite.play("falling_juggernaut_purple");
				3:
					sprite.play("falling_juggernaut_orange");
		14:
			match player_color_index:
				-1:
					pass;
				0:
					sprite.play("moving_juggernaut_yellow");
				1:
					sprite.play("moving_juggernaut_green");
				2:
					sprite.play("moving_juggernaut_purple");
				3:
					sprite.play("moving_juggernaut_orange");


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
		elif juggernaut_active and is_experimental and is_local:
			if juggernaut_speed_boost_enabled and not juggernaut_cooldown:
				velocity_component.max_speed = 200;
				juggernaut_cooldown = true;
				await get_tree().create_timer(4).timeout;
				velocity_component.max_speed = 150;
				await get_tree().create_timer(6).timeout;
				juggernaut_cooldown = false;
			elif juggernaut_stun_mines_enabled and not juggernaut_cooldown:
				var mine_data: Dictionary = {
					"message": "add_mine",
					"pos": global_position
				};
				Network.send_p2p_packet(0, mine_data);
				MinigameManager.add_mine(mine_data);
				juggernaut_cooldown = true;
				await get_tree().create_timer(10).timeout;
				juggernaut_cooldown = false;
			elif juggernaut_sketchy_tp_enabled and juggernaut_sketchy_tp_uses > 0 and not juggernaut_cooldown:
				var tp_data: Dictionary = {
					"message": "sketchy_tp"
				};
				Network.send_p2p_packet(0, tp_data);
				MinigameManager.sketchy_tp(tp_data);
				juggernaut_sketchy_tp_uses -= 1;
				juggernaut_cooldown = true;
				await get_tree().create_timer(2).timeout;
				juggernaut_cooldown = false;
		elif archery_active and is_experimental and is_local and archery_intentional_misfire_enabled and not archery_intentional_misfire_cooldown:
			Network.send_p2p_packet(0, { "message": "stun", "time": 5 });
			archery_intentional_misfire_cooldown = true;
			await get_tree().create_timer(20).timeout;
			archery_intentional_misfire_cooldown = false;
		elif collector_active and is_experimental and is_local and collector_baller_enabled and not collector_baller_cooldown:
			Network.send_p2p_packet(0, { "message": "stun", "time": 5 });
			collector_baller_cooldown = true;
			await get_tree().create_timer(20).timeout;
			collector_baller_cooldown = false;
		elif collector_active and is_experimental and is_local and collector_ball_bomb_enabled and not collector_ball_bomb_cooldown:
			for ball in emp_area.get_overlapping_bodies():
				if ball.get_parent().name == "Balls":
					ball.global_position = Vector2(1000, 1000);
			collector_ball_bomb_cooldown = true;
			await get_tree().create_timer(20).timeout;
			collector_ball_bomb_cooldown = false;
			


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


## Updates the collision shape of the player.
func collision_shape_update() -> void:
	if fishing_active: 
		if steam_id == MinigameManager.current_experimental_group:
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
		if steam_id == MinigameManager.current_experimental_group:
			collision_shape.shape.size.x = 42;
			collision_shape.shape.size.y = 16;
			collision_shape.position.x = 0;
			collision_shape.position.y = 0;
		else:
			collision_shape.shape.size.x = 8;
			collision_shape.shape.size.y = 12;
			collision_shape.position.x = 1;
			collision_shape.position.y = -2;
		super_cool_crouching = false;
	elif juggernaut_active:
		if steam_id == MinigameManager.current_experimental_group:
			collision_shape.shape.size.x = 16;
			collision_shape.shape.size.y = 29.5;
			collision_shape.position.x = 0;
			collision_shape.position.y = 0.25;
			super_cool_crouching = false;
	else:
		collision_shape.shape.size.x = 10;
		collision_shape.shape.size.y = 15;
		collision_shape.position.x = 0;
		collision_shape.position.y = 0.5;


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
		var die_data: Dictionary = {
			"message": "player_died",
			"steam_id": steam_id
		};
		set_grayscale_overlay(0);
		Network.send_p2p_packet(0, die_data);
		MinigameManager.player_died(die_data);


## Un-dies
func revive():
	if is_local:
		var die_data: Dictionary = {
			"message": "player_undied",
			"steam_id": steam_id
		};
		Network.send_p2p_packet(0, die_data);
		MinigameManager.player_undied(die_data);
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


func _on_juggernaut_hitbox_body_entered(body) -> void:
	if juggernaut_active and is_experimental and body.steam_id != steam_id and body.get_parent().name == "Players":
		print(body, " ", body.get_parent().name)
		if not body.juggernaut_extra_life:
			body.die();
			if is_local:
				if get_tree().current_scene.get_node("Juggernaut"):
					get_tree().current_scene.get_node("Juggernaut").score_point(1);
		else:
			body.juggernaut_extra_life = false;


## Does the big clicker timer for the archery minigame.
func do_big_clicker_timer():
	if is_local and archery_big_clicker_enabled and not archery_big_clicker_timer_active:
		archery_big_clicker_timer_active = true;
		archery_big_clicker_amt = 0;
		await get_tree().create_timer(4).timeout;
		archery_big_clicker_timer_active = false;
		if archery_big_clicker_amt >= 4:
			get_tree().current_scene.get_node("Archery").score_point(5);
