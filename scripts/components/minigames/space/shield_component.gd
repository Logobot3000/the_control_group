extends Area2D;


var connected_player: Player;


func _process(delta: float) -> void:
	global_position = connected_player.global_position;
	rotation = connected_player.rotation;

func _on_health_component_died() -> void:
	queue_free();


func _on_health_component_health_updated(updated_health: float, updated_max_health: float) -> void:
	if updated_health == 10:
		get_node("AnimatedSprite2D").animation = "two_hit";
	if updated_health == 5:
		get_node("AnimatedSprite2D").animation = "one_hit";


func _on_body_entered(body: Node2D) -> void:
	if body.name == "LaserComponent":
		if body.steam_id != connected_player.steam_id:
			body.queue_free();
			get_node("HealthComponent").damage(5);
