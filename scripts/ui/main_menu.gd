extends Node;

## The LobbyVisibility ItemList.
@onready var lobby_visibility: ItemList = $MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LobbyVisibility;
## The LobbyID LineEdit.
@onready var lobby_id = $MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/LobbyID;
## The animation player for the host button.
@onready var anim_player_host = $MainMenuUI/PanelContainer/Host/AnimationPlayerHost;
## The animation player for the join button.
@onready var anim_player_join = $MainMenuUI/PanelContainer/Join/AnimationPlayerJoin;
## Main menu music
@onready var bg_music = $"../BackgroundMusic";


func _ready() -> void:
	Network.local_networking_enabled.connect(_on_local_networking_enabled);
	Network.local_networking_disabled.connect(_on_local_networking_disabled);


func stop_bg_music() -> void:
	if bg_music.playing:
		bg_music.stop();


## Called when the host button is pressed.
func _on_host_button_pressed() -> void:
	if not Network.use_local_networking:
		var selected_visibility: int = -1;
		var selected_visibility_array: Array = lobby_visibility.get_selected_items();
		if selected_visibility_array: selected_visibility = selected_visibility_array[0];
		match selected_visibility:
			0:
				get_tree().current_scene.get_node("BlackOverlay/AnimationPlayer").play("fade_in");
				await get_tree().create_timer(1).timeout;
				Network.create_lobby(Steam.LOBBY_TYPE_PUBLIC);
				stop_bg_music();
			1:
				get_tree().current_scene.get_node("BlackOverlay/AnimationPlayer").play("fade_in");
				await get_tree().create_timer(1).timeout;
				Network.create_lobby(Steam.LOBBY_TYPE_FRIENDS_ONLY);
				stop_bg_music();
			2:
				get_tree().current_scene.get_node("BlackOverlay/AnimationPlayer").play("fade_in");
				await get_tree().create_timer(1).timeout;
				Network.create_lobby(Steam.LOBBY_TYPE_PRIVATE);
				stop_bg_music();
			3: 
				get_tree().current_scene.get_node("BlackOverlay/AnimationPlayer").play("fade_in");
				await get_tree().create_timer(1).timeout;
				Network.create_lobby(Steam.LOBBY_TYPE_INVISIBLE);
				stop_bg_music();
			_:
				print("No lobby visibility selected");
	else:
		get_tree().current_scene.get_node("BlackOverlay/AnimationPlayer").play("fade_in");
		await get_tree().create_timer(1).timeout;
		Network.create_lobby(0);
		stop_bg_music();


## Called when the join button is pressed.
func _on_join_button_pressed() -> void:
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
