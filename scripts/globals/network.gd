extends Node

## Shows whether or not the current player is the host of a server.
var is_host: bool = false;
## The lobby ID.
var lobby_id: int = 0;
## The members in the current lobby. Each player has a [member steam_id] and a [member steam_name].
var lobby_members: Array = [];
## The max amount of lobby members there can be.
var max_lobby_members: int = 4;


func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created);
	Steam.lobby_joined.connect(_on_lobby_joined);
	Steam.p2p_session_request.connect(_on_p2p_session_request);


func _process(delta: float) -> void:
	if lobby_id > 0:
		read_all_p2p_packets();


## Creates a lobby.
func create_lobby(lobby_type: int) -> void:
	if lobby_id == 0: # If the player is not already in a lobby
		is_host = true;
		Steam.createLobby(lobby_type, max_lobby_members);


## Is called whenever a lobby is created.
func _on_lobby_created(connected: int, this_lobby_id: int) -> void:
	if connected == 1: # If the player is connected to the lobby
		lobby_id = this_lobby_id;
		Steam.setLobbyJoinable(lobby_id, true);
		Steam.setLobbyData(lobby_id, "name", Main.player_username + "'s Lobby");
		
		print("CREATED LOBBY: ", lobby_id);
		var set_relay: bool = Steam.allowP2PPacketRelay(true);
		
		get_tree().change_scene_to_file("res://scenes/game.tscn");


## Joins a lobby.
func join_lobby(this_lobby_id: int) -> void:
	Steam.joinLobby(this_lobby_id);


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
					print("PLAYER: ", readable_data["username"], "HAS JOINED.");
					get_lobby_members();
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


## Updates the position of a remote player.
func _update_remote_player_position(data: Dictionary) -> void:
	var remote_steam_id: int = data["steam_id"];
	var pos: Vector2 = data["pos"];
	
	for player in get_tree().get_first_node_in_group("players").get_parent().get_children():
		if player.get_steam_id() == remote_steam_id and not player.get_is_local():
			player.global_position = pos;
