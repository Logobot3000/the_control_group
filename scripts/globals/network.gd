extends Node;

## Emits when local networking is enabled.
signal local_networking_enabled;
## Emits when local networking is disabled.
signal local_networking_disabled;

## The variable that determines whether or not local networking is being used instead of Steam networking. Useful for testing.
var use_local_networking: bool = false;
## Shows whether or not the current player is the host of a server. Josh.
var is_host: bool = false;
## The lobby ID.
var lobby_id: int = 0;
## The members in the current lobby. Each player has a [member steam_id] and a [member steam_name].
var lobby_members: Array = [];
## The max amount of lobby members there can be.
var max_lobby_members: int = 4;
## The ENet multiplayer peer for local networking.
var multiplayer_peer: ENetMultiplayerPeer;
## The server port to use for local networking. Screw you Manogna.
var port: int = 42069;


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("enable_local_networking") and lobby_id == 0:
		print("LOCAL NETWORKING ENABLED");
		use_local_networking = true;
		local_networking_enabled.emit();
	elif event.is_action_pressed("disable_local_networking") and lobby_id == 0:
		print("LCOAL NETWORKING DISABLED");
		use_local_networking = false;
		local_networking_disabled.emit();


func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created);
	Steam.lobby_joined.connect(_on_lobby_joined);
	Steam.p2p_session_request.connect(_on_p2p_session_request);
	Steam.lobby_chat_update.connect(_on_lobby_chat_update);

	multiplayer_peer = ENetMultiplayerPeer.new();
	multiplayer.peer_connected.connect(_on_peer_connected);
	multiplayer.peer_disconnected.connect(_on_peer_disconnected);
	multiplayer.connection_failed.connect(_on_connection_failed);
	multiplayer.connected_to_server.connect(_on_connected_to_server);
	multiplayer.server_disconnected.connect(_on_server_disconnected);


func _process(delta: float) -> void:
	if not use_local_networking:
		if lobby_id > 0:
			read_all_p2p_packets();


## Creates a lobby.
func create_lobby(lobby_type: int) -> void:
	Main.current_game_state = Enums.GameState.LOBBY;
	if not use_local_networking:
		if lobby_id == 0: # If the player is not already in a lobby
			is_host = true;
			Steam.createLobby(lobby_type, max_lobby_members);
	else:
		var error: Error = multiplayer_peer.create_server(port, max_lobby_members);
		if error == OK:
			multiplayer.multiplayer_peer = multiplayer_peer;
			is_host = true;
			lobby_id = port;
			
			lobby_members.append({"steam_id": multiplayer.get_unique_id(), "steam_name": "Host_" + str(randi() % 1000)});
			Main.player_steam_id = multiplayer.get_unique_id();
			
			print("CREATED LOCAL SERVER");
			get_tree().change_scene_to_file("res://scenes/game.tscn");
		else: print("Server could not be created: ", error);


## Is called whenever a lobby is created.
func _on_lobby_created(connected: int, this_lobby_id: int) -> void:
	if connected == 1: # If the player is connected to the lobby
		lobby_id = this_lobby_id;
		Steam.setLobbyJoinable(lobby_id, true);
		Steam.setLobbyData(lobby_id, "name", Main.player_username + "'s Lobby");
		
		print("CREATED LOBBY: ", Main.lobby_id_to_base64(lobby_id));
		var set_relay: bool = Steam.allowP2PPacketRelay(true);
		
		get_tree().change_scene_to_file("res://scenes/game.tscn");


## Joins a lobby.
func join_lobby(this_lobby_id: int) -> void:
	if not use_local_networking: Steam.joinLobby(this_lobby_id);
	else:
		var address: String = "127.0.0.1";
		
		var error = multiplayer_peer.create_client(address, port);
		if error == OK:
			multiplayer.multiplayer_peer = multiplayer_peer;
			print("CONNECTING TO SERVER");
		else:
			print("Failed to connect: ", error);


## Is called whenever a lobby is joined.
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id;
		
		get_lobby_members();
		make_p2p_handshake();
		
		get_tree().change_scene_to_file("res://scenes/game.tscn");


## Updates [member lobby_members] with the current lobby members.
func get_lobby_members() -> void:
	if not use_local_networking:
		lobby_members.clear();
		var num_of_lobby_members: int = Steam.getNumLobbyMembers(lobby_id);
		
		for member in range(0, num_of_lobby_members):
			var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, member);
			var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id);
			
			lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name});


## Sends a P2P packet.
func send_p2p_packet(this_target: int, packet_data: Dictionary, send_type: int = 0) -> void:
	if not use_local_networking:
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
	else:
		if this_target == 0:
			_send_packet_rpc.rpc(packet_data);
		else:
			_send_packet_rpc.rpc_id(this_target, packet_data);


## Sends a packet through RPC, for local networking.
@rpc("any_peer", "call_remote", "reliable")
func _send_packet_rpc(data: Dictionary) -> void:
	var sender_id = multiplayer.get_remote_sender_id();
	_handle_recieved_packet(sender_id, data);


## Reads a P2P packet.
func read_p2p_packet() -> void:
	if not use_local_networking:
		var packet_size: int = Steam.getAvailableP2PPacketSize(0);
		if packet_size > 0:
			var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0);
			var packet_sender: int = this_packet['remote_steam_id'];
			var packet_code: PackedByteArray = this_packet['data'];
			var readable_data: Dictionary = bytes_to_var(packet_code);
			
			_handle_recieved_packet(packet_sender, readable_data);


## Handles packets based on message
func _handle_recieved_packet(sender_id: int, readable_data: Dictionary) -> void:
	if readable_data.has("message"):
		match readable_data["message"]:
			"handshake":
				_on_p2p_handshake(readable_data);
			"player_position":
				_update_remote_player_position(readable_data);
			"update_game_state":
				Main.set_game_state(readable_data);
			"minigame_chosen":
				MinigameManager.set_current_minigame(readable_data);
			"ready_for_minigame":
				MinigameManager.set_ready_for_minigame(readable_data);
			"timer_updated":
				MinigameManager.update_timer(readable_data);
			"assign_groups":
				MinigameManager.assign_groups(readable_data);
			"control_group_modifier_update":
				MinigameManager.set_control_group_modifiers(readable_data);
			"experimental_group_modifier_update":
				MinigameManager.set_experimental_group_modifier(readable_data);
			"spawn_pos_update":
				MinigameManager.spawn_pos_update(readable_data);
			"score_update":
				MinigameManager.update_scores(readable_data);
			"minigame_timer_updated":
				MinigameManager.update_minigame_timer(readable_data);
			"hook_update":
				MinigameManager.hook_update(readable_data);
			"fish_spawn":
				MinigameManager.fish_spawn(readable_data);
			"stun":
				MinigameManager.stun(readable_data);
			"emp_particles":
				MinigameManager.emp_particles(readable_data);
			"laser_fired":
				MinigameManager.laser_fired(readable_data);
			"add_mine":
				MinigameManager.add_mine(readable_data);
			"sketchy_tp":
				MinigameManager.sketchy_tp(readable_data);
			"player_died":
				MinigameManager.player_died(readable_data);
			"player_undied":
				MinigameManager.player_undied(readable_data);


## Reads up to [member Constants.PACKET_READ_LIMIT] packets.
func read_all_p2p_packets(read_count: int = 0) -> void:
	if not use_local_networking:
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
	if not use_local_networking: send_p2p_packet(0, {"message": "handshake", "steam_id": Main.player_steam_id, "username": Main.player_username});
	else: send_p2p_packet(0, {"message": "handshake", "steam_id": multiplayer.get_unique_id(), "username": "Player_" + str(multiplayer.get_unique_id())});


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
	
	if not use_local_networking: get_lobby_members();
	
	var game = get_tree().current_scene;
	if not game: return;
	
	for player in game.get_node("Players").get_children():
		if player.get_steam_id() == data["steam_id"]: 
			_refresh_all_player_sprites();
			return;
	
	var player_instance = game.player_scene.instantiate();
	player_instance.set_steam_id(data["steam_id"]);
	player_instance.name = data["username"];
	player_instance.add_to_group("players");
	if not use_local_networking: player_instance.set_is_local(data["steam_id"] == Main.player_steam_id);
	else: player_instance.set_is_local(data["steam_id"] == multiplayer.get_unique_id());
	game.players_root.add_child(player_instance);
	
	if is_host and Main.current_game_state:
		Main.update_game_state(Main.current_game_state);
	
	call_deferred("_refresh_all_player_sprites");


## Refresh sprite colors for all players in the game
func _refresh_all_player_sprites() -> void:
	var game = get_tree().current_scene;
	if not game: return;
	
	# Wait a frame to ensure all players are properly added
	await get_tree().process_frame;
	
	for player in game.get_node("Players").get_children():
		if player.has_method("update_sprite_colors"):
			player.update_sprite_colors();


## Updates the position of a remote player.
func _update_remote_player_position(data: Dictionary) -> void:
	var remote_steam_id: int = data["steam_id"];
	var pos: Vector2 = data["position"];
	var vel: Vector2 = data["velocity"];
	var super_cool_crouching: bool = data["super_cool_crouching"];
	var is_on_floor: bool = data["is_on_floor"];
	
	var game = get_tree().current_scene;
	if not game: return;
	
	for player in game.get_node("Players").get_children():
		if player.get_steam_id() == remote_steam_id and not player.get_is_local():
			player.global_position = pos;
			player.velocity = vel;
			player.rotation = data["rotation"];
			player.super_cool_crouching = super_cool_crouching;
			
			if player.fishing_active and player.is_experimental: player.set_sprite_direction(-player.velocity.x);
			else: player.set_sprite_direction(player.velocity.x);

			if not player.super_cool_crouching:
				if not player.space_active:
					if snapped(player.velocity.x, 100) == 0 and player.velocity.y == 0:
						if player.fishing_active: 
							if player.is_experimental: player.animation_state = 6;
							else: player.animation_state = 4;
						elif player.juggernaut_active and player.is_experimental:
							player.animation_state = 12;
						else: player.animation_state = 0;
					elif not is_on_floor and !player.fishing_active:
						if player.juggernaut_active and player.is_experimental:
							player.animation_state = 13;
						else: player.animation_state = 1;
					elif snapped(player.velocity.x, 100) != 0 and player.velocity.y == 0:
						if player.fishing_active: 
							if player.is_experimental: player.animation_state = 7;
							else: player.animation_state = 5;
						elif player.juggernaut_active and player.is_experimental:
							player.animation_state = 14;
						else: player.animation_state = 2;
				else:
					if player.is_experimental:
						if snapped(player.velocity.x, 50) == 0 and snapped(player.velocity.y, 50) == 0:
							player.animation_state = 8;
						else:
							player.animation_state = 9;
					else:
						if snapped(player.velocity.x, 50) == 0 and snapped(player.velocity.y, 50) == 0:
							player.animation_state = 10;
						else:
							player.animation_state = 11;
			else:
				player.animation_state = 3;


## Called whenever a peer connects for local networking.
func _on_peer_connected(id: int) -> void:
	print("PEER CONNECTED: ", id);
	
	var player_name = "Player_" + str(id)
	lobby_members.append({
		"steam_id": id,
		"steam_name": player_name
	});
	
	if is_host:
		var handshake_data = {
			"message": "handshake",
			"steam_id": 1,
			"username": "Host_1"
		};
		_send_packet_rpc.rpc_id(id, handshake_data);
	
	for member in lobby_members:
		if member["steam_id"] != id and member["steam_id"] != 1: # Don't send to new player or host
			var existing_player_data: Dictionary = {
				"message": "handshake",
				"steam_id": member["steam_id"],
				"username": member["steam_name"]
			};
			_send_packet_rpc.rpc_id(id, existing_player_data);
		
	var new_player_data: Dictionary = {
		"message": "handshake",
		"steam_id": id,
		"username": player_name
	};
	for member in lobby_members:
		if member["steam_id"] != id and member["steam_id"] != 1:
			_send_packet_rpc.rpc_id(member["steam_id"], new_player_data);


## Called whenever a peer disconnects for local networking.
func _on_peer_disconnected(id: int) -> void:
	print("PEER DISCONNECTED: ", id);
	remove_player(id);
	
	# Remove from lobby members
	for i in range(lobby_members.size()):
		if lobby_members[i]["steam_id"] == id:
			lobby_members.remove_at(i);
			break;


## Called whenever a peer connection failed for local networking.
func _on_connection_failed() -> void:
	print("Connection to server failed");


## Called whenever a peer connects to a server for local networking.
func _on_connected_to_server() -> void:
	print("Connected to server");
	lobby_id = port;
	
	# Add self to lobby members
	lobby_members.append({
		"steam_id": multiplayer.get_unique_id(),
		"steam_name": "Player_" + str(multiplayer.get_unique_id())
	});
	Main.player_steam_id = multiplayer.get_unique_id();
	
	
	# Send handshake
	make_p2p_handshake();
	
	get_tree().change_scene_to_file("res://scenes/game.tscn"); 


## Called whenever the server is disconnected for local networking.
func _on_server_disconnected() -> void:
	print("Server disconnected");
	lobby_members.clear();
	is_host = false;
	lobby_id = 0;
