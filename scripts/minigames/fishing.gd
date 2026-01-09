extends BaseMinigame;

## The path to the HookComponent scene to be added to every player.
@export var hook_component_path: PackedScene;
## The path to the FishComponent scene to be added in the minigame.
@export var fish_component_path: PackedScene;

## The left fish door.
@onready var fish_door_left: Sprite2D = $FishDoor;
## The right fish door.
@onready var fish_door_right: Sprite2D = $FishDoor2;

## The probability for a jellyfish to spawn (out of 10).
var jellyfish_spawn_chance: int = 2;
## The time for the next fish to spawn.
var fish_spawn_time: float = 1.5;
## The side the next fish will spawn at.
var next_fish_spawn_left: bool = true;


func minigame_setup() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			player.fishing_active = true;
			player.can_jump = false;
			player.add_child(hook_component_path.instantiate());
			
	experimental_points_container = get_node("BaseMinigame/TV/ExperimentalPoints");
	control_points_container = get_node("BaseMinigame/TV/ControlPoints");


func load_modifiers() -> void:
	var chosen_modifier_id = 0;
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id in MinigameManager.ready_for_minigame:
			if player.steam_id == MinigameManager.current_experimental_group:
				chosen_modifier_id = MinigameManager.current_modifiers["experimental"]["id"];
				match chosen_modifier_id:
					1:
						player.get_node("HookComponent").change_type(Enums.HookType.NET);
						player.get_node("HookComponent").hook_catch_limit = 1000000;
						player.get_node("HookComponent").lower_weight = 0.1;
						player.get_node("HookComponent").raise_weight = 0.01;
						
					2:
						player.get_node("HookComponent").change_type(Enums.HookType.ANTIVENOM);
						jellyfish_spawn_chance = 3;
					3:
						print("emp")
			else:
				chosen_modifier_id = MinigameManager.current_modifiers["control"][player.steam_id]["id"];
				match chosen_modifier_id:
					1:
						player.get_node("HookComponent").raise_weight = 0.15;
					2:
						player.get_node("HookComponent").change_type(Enums.HookType.LURE);
					3:
						player.get_node("HookComponent").change_type(Enums.HookType.DOUBLE);
						player.get_node("HookComponent").hook_catch_limit = 2;


func on_minigame_started() -> void:
	spawn_fish_timer();


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		player.can_jump = true;
		player.fishing_active = false;
		player.get_node("HookComponent").queue_free();


func spawn_fish(spawn_left: bool) -> void:
	if Network.is_host:
		var is_jellyfish: bool = false;
		var color: int = -1;
		var jellyfish_rand: int = randi_range(1, 10);
		if jellyfish_rand <= jellyfish_spawn_chance:
			is_jellyfish = true;
		else:
			color = randi_range(0, 5);
		var height_modifier: int = randi_range(-20, 20);
		var time_scale: float = randf_range(0.05, 0.2);
		
		var data: Dictionary = {
			"message": "fish_spawn",
			"is_jellyfish": is_jellyfish,
			"color": color,
			"spawn_from_right": not spawn_left,
			"fish_door_left_pos": fish_door_left.position,
			"fish_door_right_pos": fish_door_right.position,
			"height_modifier": height_modifier,
			"time_scale": time_scale
		}
		Network.send_p2p_packet(0, data);
		
		MinigameManager.fish_spawn(data);


func spawn_fish_timer() -> void:
	fish_spawn_time = fish_spawn_time - 0.01;
	next_fish_spawn_left = not next_fish_spawn_left;
	spawn_fish(next_fish_spawn_left);
	await get_tree().create_timer(fish_spawn_time).timeout;
	spawn_fish_timer();


func _process(delta: float) -> void:
	update_group_scores();
	if Input.is_action_just_pressed("click"):
		for player in get_tree().current_scene.get_node("Players").get_children():
			if player.steam_id == Main.player_steam_id:
				if player.get_node("HookComponent"):
					player.get_node("HookComponent").lower_hook(true);
				break;
