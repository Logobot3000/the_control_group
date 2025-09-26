extends Node;

## The node to instantiate the players in.
@onready var players_root = $Players;
## The minigame UI system.
@onready var minigame_ui = $MinigameUI;
## The start minigame button.
@onready var start_minigame_button: Button = $MinigameUI/StartMinigameButton;

## The player scene.
var player_scene = preload("res://scenes/player/player.tscn");


func _ready() -> void:
	# Spawn in all of the players.
	for member in Network.lobby_members:
		var player_instance = player_scene.instantiate();
		player_instance.set_steam_id(member["steam_id"]);
		player_instance.name = member["steam_name"];
		player_instance.add_to_group("players");
		if not Network.use_local_networking: player_instance.set_is_local(member["steam_id"] == Main.player_steam_id);
		else: player_instance.set_is_local(member["steam_id"] == multiplayer.get_unique_id());
		players_root.add_child(player_instance);
	
	call_deferred("_refresh_all_sprites");
	_setup_minigame_system();


## Refreshes all sprites.
func _refresh_all_sprites() -> void:
	await get_tree().process_frame;
	
	for player in players_root.get_children():
		if player.has_method("update_sprite_colors"):
			player.update_sprite_colors();


## Set up the minigame system.
func _setup_minigame_system() -> void:
	if not get_node_or_null("/root/MinigameManager"):
		var minigame_manager = preload("res://scripts/globals/minigame_manager.gd").new();
		minigame_manager.name = "MinigameManager";
		get_tree().root.add_child(minigame_manager);
	
	# Connect start button (only show for host)
	if Network.is_host and start_minigame_button:
		start_minigame_button.visible = true;
		start_minigame_button.pressed.connect(_on_start_minigame_pressed);
	elif start_minigame_button:
		start_minigame_button.visible = false;


## Called when host presses the start minigame button.
func _on_start_minigame_pressed() -> void:
	if Network.lobby_members.size() < 2:
		print("Need at least 2 players to start a minigame!");
		return;
	
	# Start minigame through MinigameManager
	var minigame_manager = get_node("/root/MinigameManager");
	if minigame_manager:
		minigame_manager.start_minigame_round();
