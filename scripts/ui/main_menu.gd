extends Node

## The LobbyVisibility ItemList.
@onready var lobby_visibility: ItemList = $MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LobbyVisibility;
## The LobbyID LineEdit.
@onready var lobby_id = $MainMenuUI/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/LobbyID;

## Called when the host button is pressed.
func _on_host_button_pressed() -> void:
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


## Called when the join button is pressed.
func _on_join_button_pressed() -> void:
	var id: int = Main.base64_to_lobby_id(lobby_id.text);
	Network.join_lobby(id);
