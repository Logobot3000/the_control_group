extends Node2D;


func _ready() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		player.can_move = false;
	get_node("AnimationPlayer").play("go");
	await get_tree().create_timer(4).timeout;
	get_node("NarratorComponent").narrator_secret_intro();
	await get_node("NarratorComponent").finished;
	for player in get_tree().current_scene.get_node("Players").get_children():
		player.can_move = true;
	get_node("AnimationPlayer2").play("see_lobby");
