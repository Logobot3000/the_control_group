extends Node;

## A component for the hook in the fishing minigame.
class_name HookComponent;

## Emits whenever a fish is caught on the hook.
signal fish_caught;

## The hook's base.
@onready var hook_base: Node = $HookBase;
## The hook's CollisionShape2D/
@onready var collision_shape: CollisionShape2D = $CollisionShape2D;

## The type of hook for the hook component.
@export var hook_type: Enums.HookType = Enums.HookType.DEFAULT;
