extends StaticBody2D

## The AnimationPlayer that opens and closes the door.
@onready var anim: AnimationPlayer = $AnimationPlayer;
## The sprite for the door.
@onready var spr: AnimatedSprite2D = $AnimatedSprite2D;


func _ready() -> void:
	spr.play("run");


## Opens the door.
func open_door() -> void:
	anim.play("open");


## Closes the door.
func close_door() -> void:
	anim.play("close");
