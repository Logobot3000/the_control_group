extends RigidBody2D;




func _on_area_2d_body_entered(body) -> void:
	print(body.get_parent().name)
	if body.get_parent().name == "Players":
		print("enter")
		collision_layer = 3;
		collision_mask = 3;


func _on_area_2d_body_exited(body) -> void:
	if body.get_parent().name == "Players":
		print("exit")
		collision_layer = 2;
		collision_mask == 1;
