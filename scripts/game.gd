extends Node

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
		player_instance.set_is_local(member["steam_id"] == Main.player_steam_id);
		players_root.add_child(player_instance);
