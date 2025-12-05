extends Node;

## A component for the hook in the fishing minigame.
class_name HookComponent;

## Emits whenever a fish is caught on the hook.
signal fish_caught;

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


## Lowers the hook.
func lower_hook() -> void:
	temp_pos += 8;
	temp_pos_2 += 4;
	temp_scale += 0.5;
	light_energy += 0.2;
	light_energy = clampf(light_energy, 0.0, 0.6);
	hook_depth += 1;
	
	if hook_depth > 20:
		temp_pos = 0;
		temp_pos_2 = -8;
		temp_scale = 0;
		light_energy = 0;
		hook_depth = 0;


func _ready() -> void:
	hook_string.position.y = temp_pos_2;
	hook_string.scale.y = temp_scale;
	hook_base.position.y = temp_pos;
	collision_shape.position.y = temp_pos;
	hook_base.get_node("PointLight2D").energy = 0;
	self.position = Vector2(4, 4);


func _process(delta: float) -> void:
	hook_string.position.y = lerp(hook_string.position.y, temp_pos_2 + 4, lower_weight);
	hook_string.scale.y = lerp(hook_string.scale.y, temp_scale + 0.5, lower_weight);
	hook_base.position.y = lerp(hook_base.position.y, temp_pos + 8, lower_weight);
	collision_shape.position.y = lerp(collision_shape.position.y, temp_pos + 8, lower_weight);
	hook_base.get_node("PointLight2D").energy = lerp(hook_base.get_node("PointLight2D").energy, light_energy, lower_weight);
