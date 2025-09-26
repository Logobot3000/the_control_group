extends Node;

## The player's Steam ID.
var player_steam_id: int = 0;
## The player's Steam username.
var player_username: String = ""


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
