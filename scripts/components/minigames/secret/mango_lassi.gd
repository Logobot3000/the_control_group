extends Area2D


func _on_body_entered(body) -> void:
	get_node("AnimationPlayer").play("go");
	await get_node("AnimationPlayer").animation_finished;
	queue_free();
