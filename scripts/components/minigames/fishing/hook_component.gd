extends Node;

## A component for the hook in the fishing minigame.
class_name HookComponent;

## The hook's base.
@onready var hook_base: AnimatedSprite2D = $AnimatedSprite2D;
## The hook's string.
@onready var hook_string: Sprite2D = $Sprite2D;
## The hook's CollisionShape2D.
@onready var collision_shape: CollisionShape2D = $CollisionShape2D;

## The type of hook for the hook component.
@export var hook_type: Enums.HookType = Enums.HookType.DEFAULT;

## The weight for how fast the hook is lowered.
var lower_weight: float = 0.05
## The weight for how fast the hook is raised.
var raise_weight: float = 0.025
## The current weight used.
var current_weight: float;
## Determines whether the player can lower the hook.
var can_lower: bool = true;
## The position the hook needs to move to when it is being lowered.
var temp_pos: float = 0.0;
## The position the hook string needs to move to when it is being lowered.
var temp_pos_2: float = -8.0;
## The scale the hook needs to scale to when it is being lowered.
var temp_scale: float = 0.0;
## The emergy of the light indicator on the hook that should be correct when it is being lowered.
var light_energy: float = 0.0;
## The depth of the hook.
var hook_depth: int = 0;
## How many fish this hook can catch at once.
var hook_catch_limit: int = 1;
## How many fish is already attached to this hook.
var fish_currently_caught: int = 0;
## If the hook is currently being raised
var raising: bool = false;


## Lowers the hook.
func lower_hook(local: bool) -> void:
	if can_lower:
		current_weight = lower_weight;
		if hook_type == Enums.HookType.NET:
			temp_pos += (8 * 20);
			temp_pos_2 += (4 * 20);
			temp_scale += (0.5 * 20);
			hook_depth += (1 * 20);
		else:
			temp_pos += 8;
			temp_pos_2 += 4;
			temp_scale += 0.5;
			hook_depth += 1;
		if local: 
			update_hook_p2p(0);
			hook_base.get_node("PointLight2D").color = "#ffefa1";
			light_energy += 0.2;
			light_energy = clampf(light_energy, 0.0, 0.6);
		else:
			hook_base.get_node("PointLight2D").color = "#ff2112";
			light_energy += 0.1;
			light_energy = clampf(light_energy, 0.0, 0.3);
		
		if hook_depth > 20:
			raise_hook(local);


## Raises the hook.
func raise_hook(local: bool) -> void:
	current_weight = raise_weight;
	if local: can_lower = false;
	temp_pos = 0;
	temp_pos_2 = -8;
	temp_scale = 0;
	light_energy = 0;
	hook_depth = 0;
	if local: update_hook_p2p(1);
	raising = true;


## Send hook update through P2P system.
func update_hook_p2p(direction: int) -> void:
	var update_hook: Dictionary = {
		"message": "hook_update",
		"steam_id": get_parent().steam_id,
		"direction": direction
	};
	Network.send_p2p_packet(0, update_hook);


## Changes the hook type.
func change_type(type: Enums.HookType) -> void:
	match type:
		Enums.HookType.DEFAULT:
			hook_base.play("default");
		Enums.HookType.DOUBLE:
			hook_base.play("double");
		Enums.HookType.LURE:
			hook_base.play("lure");
		Enums.HookType.ANTIVENOM:
			hook_base.play("antivenom");
		Enums.HookType.NET:
			if raising: hook_base.play("net_raise")
			else: hook_base.play("net_lower");
	hook_type = type;


func _ready() -> void:
	hook_string.position.y = temp_pos_2;
	hook_string.scale.y = temp_scale;
	hook_base.position.y = temp_pos;
	collision_shape.position.y = temp_pos;
	hook_base.get_node("PointLight2D").energy = 0;
	self.position = Vector2(4, 4);


func _process(delta: float) -> void:
	change_type(hook_type);
	hook_string.position.y = lerp(hook_string.position.y, temp_pos_2 + 4, current_weight);
	hook_string.scale.y = lerp(hook_string.scale.y, temp_scale + 0.5, current_weight);
	hook_base.position.y = lerp(hook_base.position.y, temp_pos + 8, current_weight);
	collision_shape.position.y = lerp(collision_shape.position.y, temp_pos + 8, current_weight);
	hook_base.get_node("PointLight2D").energy = lerp(hook_base.get_node("PointLight2D").energy, light_energy, current_weight);
	if snapped(hook_string.position.y, 2) == 2:
		raising = false;
		if not get_parent().stunned:
			can_lower = true;
	if fish_currently_caught == hook_catch_limit:
		raise_hook(true);
