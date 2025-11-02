extends Node;

## The LobbyVisibility ItemList.
@onready var lobby_visibility: ItemList = $MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LobbyVisibility;
## The LobbyID LineEdit.
@onready var lobby_id = $MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/LobbyID;
## The animation player for the host button.
@onready var anim_player_host = $MainMenuUI/PanelContainer/Host/AnimationPlayerHost;
## The animation player for the join button.
@onready var anim_player_join = $MainMenuUI/PanelContainer/Join/AnimationPlayerJoin;


func _ready() -> void:
	Network.local_networking_enabled.connect(_on_local_networking_enabled);
	Network.local_networking_disabled.connect(_on_local_networking_disabled);


## Called when the host button is pressed.
func _on_host_button_pressed() -> void:
	if not Network.use_local_networking:
		var selected_visibility: int = -1;
		var selected_visibility_array: Array = lobby_visibility.get_selected_items();
		if selected_visibility_array: selected_visibility = selected_visibility_array[0];
		match selected_visibility:
			0:
				Network.create_lobby(Steam.LOBBY_TYPE_PUBLIC);
			1:
				Network.create_lobby(Steam.LOBBY_TYPE_FRIENDS_ONLY);
			2:
				Network.create_lobby(Steam.LOBBY_TYPE_PRIVATE);
			3: 
				Network.create_lobby(Steam.LOBBY_TYPE_INVISIBLE);
			_:
				print("No lobby visibility selected");
	else:
		Network.create_lobby(0);


## Called when the join button is pressed.
func _on_join_button_pressed() -> void:
	var input_text: String = lobby_id.text.strip_edges();
	if input_text.is_empty() and not Network.use_local_networking: return;
	var id: int = Main.base64_to_lobby_id(input_text);
	Network.join_lobby(id);


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
