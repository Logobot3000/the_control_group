extends Node;

## The node to instantiate the players in
@onready var players_root = $Players;

## The player scene
var player_scene = preload("res://scenes/player/player.tscn");


func _ready() -> void:
	# Spawn in all of the players
	for member in Network.lobby_members:
		var player_instance = player_scene.instantiate();
		player_instance.set_steam_id(member["steam_id"]);
		player_instance.name = member["steam_name"];
		player_instance.add_to_group("players");
		if not Network.use_local_networking: player_instance.set_is_local(member["steam_id"] == Main.player_steam_id);
		else: player_instance.set_is_local(member["steam_id"] == multiplayer.get_unique_id());
		players_root.add_child(player_instance);
	
	if not Network.use_local_networking:
		get_tree().current_scene.get_node("LobbyCode").text = "CODE: " + Main.lobby_id_to_base64(Network.lobby_id);
	
	await get_tree().process_frame;


func _on_ready_for_minigame_entered(body: Node2D) -> void:
	var ready_for_minigame: Dictionary = {
		"message": "ready_for_minigame",
		"steam_id": body.steam_id
	};
	body.can_move = false;
	Network.send_p2p_packet(0, ready_for_minigame);
