extends BaseMinigame;

## The path to the HookComponent scene to be added to every player.
@export var hook_component_path: PackedScene;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.fishing_active = true;
			player.can_jump = false;
			player.add_child(hook_component_path.instantiate());


func load_modifiers() -> void:
	var chosen_modifier_id = 0;
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			if player.steam_id == MinigameManager.current_experimental_group:
				chosen_modifier_id = MinigameManager.current_modifiers["experimental"]["id"];
				match chosen_modifier_id:
					1:
						print("net harpoon")
					2:
						print("antivenom hook")
					3:
						print("emp")
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						player.get_node("HookComponent").raise_weight = 0.2;
					2:
						player.get_node("HookComponent").change_type(Enums.HookType.LURE);
					3:
						player.get_node("HookComponent").change_type(Enums.HookType.DOUBLE);


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
