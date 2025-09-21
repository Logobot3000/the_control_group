extends Node

## Determines whether or not local multiplayer is enabled.
var local_multiplayer = false;
## Shows whether or not the current player is the host of a server.
var is_host: bool = false;
## The lobby ID.
var lobby_id: int = 0;
## The members in the current lobby. Each player has a [member steam_id] and a [member steam_name].
var lobby_members: Array = [];
## The max amount of lobby members there can be.
var max_lobby_members: int = 4;
## For local multiplayer only: allows local multiplayer to work
var peer: MultiplayerPeer = null;
## For local multiplayer only: the port for the server. Screw you Manogna.
var port: int = 42069;


func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created);
	Steam.lobby_joined.connect(_on_lobby_joined);
	Steam.p2p_session_request.connect(_on_p2p_session_request);


func _process(delta: float) -> void:
	if lobby_id > 0:
		read_all_p2p_packets();


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("enable_local_multiplayer", true):
		local_multiplayer = true;
		print("LOCAL MULTIPLAYER ENABLED");
	if event.is_action("disable_local_multiplayer", true):
		local_multiplayer = false;
		print("LOCAL MULTIPLAYER DISABLED");


## Creates a lobby.
func create_lobby(lobby_type: int) -> void:
	if not local_multiplayer:
		if lobby_id == 0: # If the player is not already in a lobby
			is_host = true;
			Steam.createLobby(lobby_type, max_lobby_members);
	else:
		var server : ENetMultiplayerPeer = ENetMultiplayerPeer.new();
		var error : int = server.create_server(port, max_lobby_members, 1);
		print("ENet create_server returned: ", error);
		if error == OK:
			peer = server;
			var sm : SceneMultiplayer = SceneMultiplayer.new();
			sm.multiplayer_peer = peer;
			get_tree().set_multiplayer(sm);
			get_tree().multiplayer.peer_connected.connect(_on_peer_connected);
			get_tree().multiplayer.peer_disconnected.connect(_on_peer_disconnected);
			is_host = true;
			print("Local server started on port ", port);
			get_tree().change_scene_to_file("res://scenes/game.tscn");
		else:
			push_warning("Failed to start local server (error " + str(error) + ")");


## Is called whenever a lobby is created.
func _on_lobby_created(connected: int, this_lobby_id: int) -> void:
	if not local_multiplayer:
		if connected == 1: # If the player is connected to the lobby
			lobby_id = this_lobby_id;
			Steam.setLobbyJoinable(lobby_id, true);
			Steam.setLobbyData(lobby_id, "name", Main.player_username + "'s Lobby");
			
			print("CREATED LOBBY: ", Main.lobby_id_to_base64(lobby_id));
			var set_relay: bool = Steam.allowP2PPacketRelay(true);
		
			get_tree().change_scene_to_file("res://scenes/game.tscn");


## Joins a lobby.
func join_lobby(this_lobby_id: int) -> void:
	if not local_multiplayer:
		Steam.joinLobby(this_lobby_id);
	else:
		var client : ENetMultiplayerPeer = ENetMultiplayerPeer.new();
		var error : int = client.create_client("127.0.0.1", port, 1);
		print("ENet create_client returned: ", error);
		if error == OK:
			peer = client;
			var sm : SceneMultiplayer = SceneMultiplayer.new();
			sm.multiplayer_peer = peer;
			get_tree().set_multiplayer(sm);
			get_tree().multiplayer.peer_connected.connect(_on_peer_connected);
			get_tree().multiplayer.peer_disconnected.connect(_on_peer_disconnected);
			is_host = false;
			print("Local client connected to 127.0.0.1:", port);
			get_tree().change_scene_to_file("res://scenes/game.tscn");
		else:
			push_warning("Failed to join local server (error " + str(error) + ")");


## Local only: Called when a new peer joins (including yourself if you’re the host).
func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: ", peer_id);
	var player_scene: PackedScene = preload("res://scenes/player/player.tscn");
	var player: Node2D = player_scene.instantiate();
	player.set_multiplayer_authority(peer_id);
	player.name = "Player_%s" % str(peer_id);
	get_tree().current_scene.add_child(player);


## Local only: Called when a peer disconnects (or quits the game).
func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected: ", peer_id);
	var player_node := get_tree().current_scene.get_node_or_null("Player_%s" % str(peer_id));
	if player_node:
		player_node.queue_free();


## Is called whenever a lobby is joined.
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id;
		
		get_lobby_members();
		make_p2p_handshake();
		
		get_tree().change_scene_to_file("res://scenes/game.tscn");


## Updates [member lobby_members] with the current lobby members.
func get_lobby_members() -> void:
	lobby_members.clear();
	var num_of_lobby_members: int = Steam.getNumLobbyMembers(lobby_id);
	
	for member in range(0, num_of_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, member);
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id);
		
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name});


## Sends a P2P packet.
func send_p2p_packet(this_target: int, packet_data: Dictionary, send_type: int = 0) -> void:
	var channel: int = 0;
	var this_data: PackedByteArray;
	this_data.append_array(var_to_bytes(packet_data));
	
	if this_target == 0: # Packet being sent to everyone
		if lobby_members.size() > 1:
			for member in lobby_members:
				if member['steam_id'] != Main.player_steam_id: # So we aren't sending data to ourselves
					Steam.sendP2PPacket(member["steam_id"], this_data, send_type, channel);
	else:
		Steam.sendP2PPacket(this_target, this_data, send_type, channel);


## Reads a P2P packet.
func read_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0);
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0);
		var packet_sender: int = this_packet['remote_steam_id'];
		var packet_code: PackedByteArray = this_packet['data'];
		var readable_data: Dictionary = bytes_to_var(packet_code);
		
		if readable_data.has("message"):
			match readable_data["message"]:
				"handshake":
					_on_p2p_handshake(readable_data);
				"player_position":
					_update_remote_player_position(readable_data);


## Reads up to [member Constants.PACKET_READ_LIMIT] packets.
func read_all_p2p_packets(read_count: int = 0) -> void:
	if read_count >= Constants.PACKET_READ_LIMIT:
		return
	
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet();
		read_all_p2p_packets(read_count + 1);


## Called when a player wants to request joining the session.
func _on_p2p_session_request(remote_id: int):
	var this_requester: String = Steam.getFriendPersonaName(remote_id);
	Steam.acceptP2PSessionWithUser(remote_id)


## Makes a P2P handshake.
func make_p2p_handshake() -> void:
	send_p2p_packet(0, {"message": "handshake", "steam_id": Main.player_steam_id, "username": Main.player_username});


## Called whenever the lobby gains or loses a player
func _on_lobby_chat_update(plobby_id: int, changed_id: int, making_change_id: int, chat_state: int) -> void:
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT or chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
		remove_player(changed_id);


## Removes a player from the game
func remove_player(steam_id: int) -> void:
	var game = get_tree().current_scene;
	if not game: return;
	
	for player in game.get_node("Players").get_children():
		if player.get_steam_id() == steam_id:
			player.queue_free();
			break;


## Called whenever a P2P handshake happens.
func _on_p2p_handshake(data: Dictionary) -> void:
	print("PLAYER: ", data["username"], " HAS JOINED.");
	
	get_lobby_members();
	
	var game = get_tree().current_scene;
	if not game: return;
	
	for player in game.get_node("Players").get_children():
		if player.get_steam_id() == data["steam_id"]: return;
	
	var player_instance = game.player_scene.instantiate();
	player_instance.set_steam_id(data["steam_id"]);
	player_instance.name = data["steam_name"];
	player_instance.add_to_group("players");
	player_instance.set_is_local(data["steam_id"] == Main.player_steam_id);
	game.players_root.add_child(player_instance);


## Updates the position of a remote player.
func _update_remote_player_position(data: Dictionary) -> void:
	var remote_steam_id: int = data["steam_id"];
	var pos: Vector2 = data["position"];
	var vel: Vector2 = data["velocity"];
	
	var game = get_tree().current_scene;
	if not game: return;
	
	for player in game.get_node("Players").get_children():
		if player.get_steam_id() == remote_steam_id and not player.get_is_local():
			player.global_position = pos;
			player.velocity = vel;
