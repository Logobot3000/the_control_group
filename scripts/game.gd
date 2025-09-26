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
	
	# Connect to network messages for minigame coordination
	Network.connect("packet_received", _on_network_packet_received);


## Called when host presses the start minigame button.
func _on_start_minigame_pressed() -> void:
	if Network.lobby_members.size() < 2:
		print("Need at least 2 players to start a minigame!");
		return;
	
	# Start minigame through MinigameManager
	var minigame_manager = get_node("/root/MinigameManager");
	if minigame_manager:
		minigame_manager.start_minigame_round();


## Handle network packets related to minigames.
func _on_network_packet_received(sender_id: int, data: Dictionary) -> void:
	if not data.has("message"):
		return;
	
	match data.message:
		"roles_assigned":
			_handle_roles_assigned(data);
		"modifier_selection_start":
			_handle_modifier_selection_start(data);
		"modifier_selected":
			_handle_modifier_selected(data);
		"minigame_start":
			_handle_minigame_start(data);
		"minigame_results":
			_handle_minigame_results(data);
		"score_update":
			_handle_score_update(data);


## Handle role assignment message
func _handle_roles_assigned(data: Dictionary) -> void:
	print("ROLES ASSIGNED - EXPERIMENTAL: ", data.experimental_player, ", CONTROL: ", data.control_players);
	
	if not Network.is_host:
		var minigame_manager = get_node_or_null("/root/MinigameManager");
		if minigame_manager:
			minigame_manager.current_experimental_player = data.experimental_player;
			minigame_manager.current_control_players = data.control_players;
			minigame_manager.current_minigame = data.minigame;


## Handle modifier selection start
func _handle_modifier_selection_start(data: Dictionary) -> void:
	get_tree().change_scene_to_file("res://scenes/ui/modifier_selection.tscn");


## Handle modifier selection
func _handle_modifier_selected(data: Dictionary) -> void:
	print("Player ", data.player_id, " selected modifier: ", data.modifier_name);


## Handle minigame start
func _handle_minigame_start(data: Dictionary) -> void:
	print("Starting minigame: ", data.minigame);
	
	# This will be handled by MinigameManager changing the scene but we can do any additional setup here if needed


## Handle minigame results
func _handle_minigame_results(data: Dictionary) -> void:
	print("Minigame results - Winner: ", data.winner_group, ", Scores: ", data.scores);


## Handle score updates during minigame
func _handle_score_update(data: Dictionary) -> void:
	print("Player ", data.player_id, " scored ", data.points, " points (Total: ", data.total_score, ")");
