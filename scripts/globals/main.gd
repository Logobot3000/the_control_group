extends Node;

## The player's Steam ID.
var player_steam_id: int = 0;
## The player's Steam username.
var player_username: String = "";
## The game state for the entire game.
var current_game_state: Enums.GameState = Enums.GameState.MAIN_MENU;


func _init() -> void:
	# Set up Steam environment
	OS.set_environment("SteamAppID", Constants.APP_ID);
	OS.set_environment("SteamGameID", Constants.APP_ID);


func _ready() -> void:
	# Actually initialize Steam
	Steam.steamInit();
	var is_running: bool = Steam.isSteamRunning();
	if not is_running: return;
	player_steam_id = Steam.getSteamID();
	player_username = Steam.getPersonaName();


func _process(delta: float) -> void:
	# Let Steam do its thing I guess
	Steam.run_callbacks();


## Changes the long [member lobby_id] to base64.
func lobby_id_to_base64(lobby_id: int) -> String:
	var arr: PackedByteArray = PackedByteArray();
	for i in range(8): arr.append((lobby_id >> (i * 8)) & 0xFF);
	return Marshalls.raw_to_base64(arr);


## Changes the short [member b64] to a lobby ID.
func base64_to_lobby_id(b64: String) -> int:
	var arr: PackedByteArray = Marshalls.base64_to_raw(b64);
	var value: int = 0;
	for i in range(arr.size()): value |= int(arr[i]) << (i * 8);
	return value;


## Updates the active game state for all players.
func update_game_state(new_game_state: Enums.GameState) -> void:
	if Network.is_host:
		current_game_state = new_game_state;
		var update_game_state: Dictionary = {
			"message": "update_game_state",
			"state": current_game_state
		};
		Network.send_p2p_packet(0, update_game_state);
		set_game_state({"state": current_game_state});
	else:
		print("Non-host tried to update the game state.");


## Called for every peer when the game state is updated.
func set_game_state(readable_data: Dictionary) -> void:
	var new_game_state: Enums.GameState = readable_data["state"];
	current_game_state = new_game_state;
	MinigameManager.handle_game_state_update(new_game_state);
