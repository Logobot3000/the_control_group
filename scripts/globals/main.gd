extends Node

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
