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
var fish_spawn_time: float = 2.0;
## The side the next fish will spawn at.
var next_fish_spawn_left: bool = true;


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


func on_minigame_started() -> void:
	spawn_fish_timer();


func on_minigame_ended() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		player.can_jump = true;
		player.fishing_active = false;


func spawn_fish(spawn_left: bool) -> void:
	if Network.is_host:
		var fish: FishComponent = fish_component_path.instantiate();
		
		var jellyfish_rand = randi_range(1, 10);
		if jellyfish_rand <= jellyfish_spawn_chance:
			fish.is_jellyfish = true;
		else:
			fish.color = randi_range(0, 5);
		
		if spawn_left:
			fish.spawn_from_right = false;
			get_tree().current_scene.add_child(fish);
			fish.position = fish_door_left.position;
		else:
			get_tree().current_scene.add_child(fish);
			fish.position = fish_door_right.position;


func spawn_fish_timer() -> void:
	fish_spawn_time = fish_spawn_time - 0.005;
	next_fish_spawn_left = not next_fish_spawn_left;
	spawn_fish(next_fish_spawn_left);
	await get_tree().create_timer(fish_spawn_time).timeout;
	spawn_fish_timer();


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("click"):
		for player in get_tree().current_scene.get_node("Players").get_children():
			if player.steam_id == Main.player_steam_id:
				player.get_node("HookComponent").lower_hook(true);
				break;
