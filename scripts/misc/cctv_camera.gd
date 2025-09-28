extends Node2D;

## The camera part of the camera.
@onready var camera = $SpriteCamera;
## The timer for the animation.
@onready var timer1 = $Timer;
## The timer for the animation to finish.
@onready var timer2 = $Timer2;
## The animation player.
@onready var anim = $AnimationPlayer;

func _ready() -> void:
	_end_anim();
	timer1.start(20);
	timer1.timeout.connect(_play_anim);
	timer2.timeout.connect(_end_anim);


## Plays the scanning animation.
func _play_anim() -> void:
	anim.play("scan");
	timer2.start(4);
	timer1.start(24);


## Ends the scanning animation.
func _end_anim() -> void:
	anim.play("default");
