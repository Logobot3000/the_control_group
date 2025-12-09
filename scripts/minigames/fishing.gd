extends BaseMinigame;

## The path to the HookComponent scene to be added to every player.
@export var hook_component_path: PackedScene;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.fishing_active = true;
			player.can_jump = false;
			player.add_child(hook_component_path.instantiate());


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		player.can_jump = true;
		player.fishing_active = false;


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("click"):
		for player in get_tree().current_scene.get_node("Players").get_children():
			if player.steam_id == Main.player_steam_id:
				player.get_node("HookComponent").lower_hook(true);
				break;
