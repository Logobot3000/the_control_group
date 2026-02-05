extends Area2D;


func _on_body_entered(body) -> void:
	if body.get_parent().name == "Players":
		if not body.is_experimental:
			body.stun(2);
			queue_free();
