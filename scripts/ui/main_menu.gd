extends Node;

## The LobbyVisibility ItemList.
@onready var lobby_visibility: ItemList = $MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LobbyVisibility;
## The LobbyID LineEdit.
@onready var lobby_id = $MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/LobbyID;
## The LobbyName LineEdit.
@onready var lobby_name_lineedit = $MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LobbyName;
## The animation player for the host button.
@onready var anim_player_host = $MainMenuUI/PanelContainer/Host/AnimationPlayerHost;
## The animation player for the join button.
@onready var anim_player_join = $MainMenuUI/PanelContainer/Join/AnimationPlayerJoin;
## Main menu music
@onready var bg_music = $"../BackgroundMusic";


func _ready() -> void:
	Network.local_networking_enabled.connect(_on_local_networking_enabled);
	Network.local_networking_disabled.connect(_on_local_networking_disabled);
	Steam.lobby_match_list.connect(on_lobby_match_list);
	
	get_node("MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LobbyVisibility").set_item_tooltip_enabled(0, false);
	get_node("MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LobbyVisibility").set_item_tooltip_enabled(1, false);


func stop_bg_music() -> void:
	if bg_music.playing:
		bg_music.stop();


## Called when the host button is pressed.
func _on_host_button_pressed() -> void:
	get_parent().get_node("SFX/Go").play();
	if not Network.use_local_networking:
		var selected_visibility: int = -1;
		var selected_visibility_array: Array = lobby_visibility.get_selected_items();
		var lobby_name: String = lobby_name_lineedit.text;
		if selected_visibility_array: selected_visibility = selected_visibility_array[0];
		match selected_visibility:
			0:
				get_tree().current_scene.get_node("BlackOverlay/AnimationPlayer").play("fade_in");
				await get_tree().create_timer(1).timeout;
				Network.create_lobby(Steam.LOBBY_TYPE_PUBLIC, lobby_name);
				stop_bg_music();
			1:
				get_tree().current_scene.get_node("BlackOverlay/AnimationPlayer").play("fade_in");
				await get_tree().create_timer(1).timeout;
				Network.create_lobby(Steam.LOBBY_TYPE_PRIVATE, lobby_name);
				stop_bg_music();
			_:
				print("No lobby visibility selected");
	else:
		get_tree().current_scene.get_node("BlackOverlay/AnimationPlayer").play("fade_in");
		await get_tree().create_timer(1).timeout;
		Network.create_lobby(0, "");
		stop_bg_music();


## Called when the join button is pressed.
func _on_join_button_pressed() -> void:
	get_parent().get_node("SFX/Go").play();
	var input_text: String = lobby_id.text.strip_edges();
	if input_text.is_empty() and not Network.use_local_networking: return;
	var id: int = Main.base64_to_lobby_id(input_text);
	get_tree().current_scene.get_node("BlackOverlay/AnimationPlayer").play("fade_in");
	await get_tree().create_timer(1).timeout;
	Network.join_lobby(id);
	stop_bg_music();


## Called when local networking is enabled.
func _on_local_networking_enabled() -> void:
	lobby_visibility.visible = false;
	lobby_id.visible = false;


## Called when local networking is disabled.
func _on_local_networking_disabled() -> void:
	lobby_visibility.visible = true;
	lobby_id.visible = true;


func _on_host_button_hover() -> void:
	if !anim_player_host.is_playing():
		anim_player_host.play("hover_in", -1, 1.5);


func _on_host_button_hover_out() -> void:
	if !anim_player_host.is_playing():
		anim_player_host.play("hover_out", -1, 1.5);


func _on_join_button_hover() -> void:
	if !anim_player_join.is_playing():
		anim_player_join.play("hover_in", -1, 1.5);


func _on_join_button_hover_out() -> void:
	if !anim_player_join.is_playing():
		anim_player_join.play("hover_out", -1, 1.5);


func open_lobby_list() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE);
	Steam.requestLobbyList();


func on_lobby_match_list(lobbies) -> void:
	for past_lobby in get_node("MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/LobbyContainer/Lobbies").get_children():
		past_lobby.queue_free();
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name");
		var mem_count = Steam.getNumLobbyMembers(lobby);
		
		var lobby_button = load("res://scenes/components/lobby_button.tscn").instantiate();
		lobby_button.lobby_name = lobby_name;
		lobby_button.count = mem_count;
		lobby_button.connect("pressed", func(): get_tree().current_scene.get_node("BlackOverlay/AnimationPlayer").play("fade_in"); await get_tree().create_timer(1).timeout; Network.join_lobby(lobby));
		
		get_node("MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/LobbyContainer/Lobbies").add_child(lobby_button);


func _on_reload_pressed() -> void:
	get_parent().get_node("SFX/Select").play();
	open_lobby_list();


func _on_lobby_visibility_item_selected(index: int) -> void:
	get_parent().get_node("SFX/Select").play();
