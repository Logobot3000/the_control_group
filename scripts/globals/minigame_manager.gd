extends Node;

## Emits when a minigame starts.
signal minigame_started(game_name: String);
## Emits when a minigame ended.
signal minigame_ended(winner_group: String, scores: Dictionary);
## Emits when the roles are assigned to the players.
signal roles_assigned(experimental_player: int, control_players: Array);
## Emits when the modifiers are selected.
signal modifiers_selected(experimental_modifier: String, control_modifiers: Dictionary);

## The current game state.
var current_state: Enums.GameState = Enums.GameState.LOBBY;
## The current minigame being played. Empty string means no current minigame.
var current_minigame: String = "";
## The current experimental group player. -1 means no current experimental group.
var current_experimental_group: int = -1;
## The current control group players. Empty array means no current control group.
var current_control_group: Array = [];
## The current modifiers applied to the players. Empty dictionary means no modifiers.
var current_modifiers: Dictionary = {};
## The current scores of the minigame. Empty dictionary means no scores.
var current_scores: Dictionary = {};
## The available minigames. Update this when you add a minigame.
var available_minigames: Array = [
	"test_minigame",
];
## The modifier definitions for each minigame. Update this when you add a minigame.
var minigame_modifiers: Dictionary = {
	"test_minigame": {
		"experimental": [
			{"name": "Experimental Modifier 1", "description": "Experimental Modifier 1 Description"},
			{"name": "Experimental Modifier 2", "description": "Experimental Modifier 2 Description"},
			{"name": "Experimental Modifier 3", "description": "Experimental Modifier 3 Description"}
		],
		"control": [
			{"name": "Control Modifier 1", "description": "Control Modifier 1 Description"},
			{"name": "Control Modifier 2", "description": "Control Modifier 2 Description"},
			{"name": "Control Modifier 3", "description": "Control Modifier 3 Description"}
		]
	},
};


## Start a new minigame round. Called during the very end of [member Enums.GameState.LOBBY].
func start_minigame_round() -> void:
	if Network.lobby_members.size() < 2:
		print("Not enough players to start a minigame!");
		return;
	
	current_minigame = available_minigames[randi() % available_minigames.size()];
	print("STARTING MINIGAME: ", current_minigame);
	
	_assign_roles();
	
	current_state = Enums.GameState.MODIFIER_SELECTION;
	_start_modifier_selection();


## Assigns the player their experimental or control group roles.
func _assign_roles() -> void:
	var all_players: Array = [];
	for member in Network.lobby_members:
		all_players.append(member["steam_id"]);
	
	all_players.shuffle();
	current_experimental_group = all_players[0];
	current_control_group.clear();
	for i in range(1, all_players.size()):
		current_control_group.append(all_players[i]);
	
	print("EXPERIMENTAL GROUP: ", current_experimental_group);
	print("CONTROL GROUP: ", current_control_group);
	
	roles_assigned.emit(current_experimental_group, current_control_group);
	
	var role_data: Dictionary = {
		"message": "roles_assigned",
		"experimental_group": current_experimental_group,
		"control_group": current_control_group,
		"minigame": current_minigame
	};
	Network.send_p2p_packet(0, role_data);


## Begin the modifier selection phase. Changes the game state to [member Enums.GameState.MODIFIER_SELECTION].
func _start_modifier_selection() -> void:
	current_state = Enums.GameState.MODIFIER_SELECTION;
	print("STARTING MODIFIER SELECTION: ", current_minigame);
	
	var modifier_data: Dictionary = {
		"message": "modifier_selection_start",
		"minigame": current_minigame,
		"experimental_modifiers": minigame_modifiers[current_minigame]["experimental"],
		"control_modifiers": minigame_modifiers[current_minigame]["control"]
	};
	Network.send_p2p_packet(0, modifier_data);


## Handle modifier selection from a player. Called during [member Enums.GameState.MODIFIER_SELECTION].
func select_modifier(player_id: int, modifier_name: String) -> void:
	if current_state != Enums.GameState.MODIFIER_SELECTION:
		return;
	
	if player_id == current_experimental_group:
		current_modifiers["experimental"] = modifier_name;
		print("EXPERIMENTAL PLAYER SELECTED: ", modifier_name);
	elif player_id in current_control_group:
		if not current_modifiers.has("control"):
			current_modifiers["control"] = {};
		
		var already_taken: bool = false;
		for existing_modifier in current_modifiers["control"].values():
			if existing_modifier == modifier_name:
				already_taken = true;
				break;
		
		if not already_taken:
			current_modifiers["control"][player_id] = modifier_name;
			print("CONTROL PLAYER: ", player_id, " SELECTED: ", modifier_name);
		else:
			print("Modifier already selected by another control player!");
			return;
	
	var modifier_update: Dictionary = {
		"message": "modifier_selected",
		"player_id": player_id,
		"modifier_name": modifier_name,
		"current_modifiers": current_modifiers
	};
	Network.send_p2p_packet(0, modifier_update);
	
	_check_modifier_selection_complete();


## Checks if all players have their selected modifiers. Called during [member Enums.GameState.MODIFIER_SELECTION].
func _check_modifier_selection_complete() -> bool:
	var experimental_ready: bool = current_modifiers.has("experimental");
	var control_ready: bool = current_modifiers.has("control") and current_modifiers["control"].size() == current_control_group.size();
	
	if experimental_ready and control_ready:
		print("ALL MODIFIERS SELECTED");
		_start_actual_minigame();
		return true;
	else:
		return false;


## Starts the actual minigame with assigned roles and modifiers. Changes the game state to [member Enums.GameState.MINIGAME_ACTIVE].
func _start_actual_minigame() -> void:
	current_state = Enums.GameState.MINIGAME_ACTIVE;
	modifiers_selected.emit(current_modifiers.get("experimental", ""), current_modifiers.get("control", {}));
	
	var minigame_scene_path: String = "res://scenes/minigames/" + current_minigame + ".tscn";
	
	var start_data = {
		"message": "minigame_start",
		"minigame": current_minigame,
		"experimental_group": current_experimental_group,
		"control_group": current_control_group,
		"modifiers": current_modifiers
	};
	Network.send_p2p_packet(0, start_data);
	
	minigame_started.emit(current_minigame);
	get_tree().change_scene_to_file(minigame_scene_path);


## Ends the minigame and returns to lobby. Changes the game state to [member Enums.GameState.RESULTS].
func end_minigame(winner_group: String, scores: Dictionary = {}) -> void:
	current_state = Enums.GameState.RESULTS;
	current_scores = scores;
	
	print("MINIGAME ENDED. WINNER: ", winner_group);
	print("SCORES: ", scores);
	
	minigame_ended.emit(winner_group, scores);
	
	var results_data = {
		"message": "minigame_results",
		"winner_group": winner_group,
		"scores": scores
	};
	Network.send_p2p_packet(0, results_data);
	
	await get_tree().create_timer(3.0).timeout; # Show the results for a little bit, can change this later
	return_to_lobby();


## Return to the lobby. Changes the game state to [member Enums.GameState.LOBBY].
func return_to_lobby() -> void:
	current_state = Enums.GameState.LOBBY;
	current_minigame = "";
	current_experimental_group = -1;
	current_control_group.clear();
	current_modifiers.clear();
	current_scores.clear();
	
	get_tree().change_scene_to_file("res://scenes/game.tscn");


## Get a player's role.
func get_player_role(player_id: int) -> Enums.PlayerGroup:
	if player_id == current_experimental_group: return Enums.PlayerGroup.EXPERIMENTAL;
	else: return Enums.PlayerGroup.CONTROL;


## Get a player's modifier. Returns an empty string if the player does not have one.
func get_player_modifier(player_id: int) -> String:
	if player_id == current_experimental_group:
		return current_modifiers.get("experimental", "");
	elif player_id in current_control_group and current_modifiers.has("control"):
		return current_modifiers["control"].get(player_id, "");
	else: return "";
