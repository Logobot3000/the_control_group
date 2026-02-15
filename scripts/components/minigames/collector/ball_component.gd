extends RigidBody2D;
## mmm balls

var id: int = 0;
var ball_tier: int = 0;


func _ready() -> void:
	match ball_tier:
		0:
			get_node("AnimatedSprite2D").play("default");
		1:
			get_node("AnimatedSprite2D").play("bronze");
		2:
			get_node("AnimatedSprite2D").play("silver");
		3:
			get_node("AnimatedSprite2D").play("gold");
	
	if not Network.is_host:
		sleeping = true;
		freeze = true;
		set_physics_process(false);


func _physics_process(delta: float) -> void:
	
	
	if Network.is_host:
		var ball_data: Dictionary = {
			"message": "ball_update",
			"id": id,
			"pos": global_position,
			"rot": rotation,
			"vel": linear_velocity
		};
		Network.send_p2p_packet(0, ball_data);
