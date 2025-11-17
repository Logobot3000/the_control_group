extends BaseMinigame;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		player.can_jump = false;


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		player.can_jump = true;
