extends Control;

## The UI for selecting a modifier.
class_name ModifierSelectionUI;

## The role label reference.
@onready var role_label: Label = $VBox/RoleLabel;
## The instruction label reference.
@onready var instruction_label: Label = $VBox/InstructionLabel;
## The modifer container reference.
@onready var modifier_container: VBoxContainer = $VBox/ModifierContainer;
## The selected modifiers label reference.
@onready var selected_modifiers_label: Label = $VBox/SelectedModifiersLabel;
## The waiting label reference.
@onready var waiting_label: Label = $VBox/WaitingLabel;

## The current role.
var current_role: Enums.PlayerGroup;
## The available modifiers to pick from.
var available_modifiers: Array = [];
## The selected modifier.
var selected_modifier: String = "";
## Determines if the selection of the modifier is complete or not.
var is_selection_complete: bool = false;
## The button references.
var modifier_buttons: Array = [];


func _ready() -> void:
	if MinigameManager:
		MinigameManager.connect("modifier_selection_start", _on_modifier_selection_start);
		MinigameManager.connect("modifier_selected", _on_modifier_selected);
	
	waiting_label.visible = false;


## Called when the [member Enums.GameState.MODIFIER_SELECTION] phase begins.
func _on_modifier_selection_start(minigame: String, control_mods: Array, experimental_mods: Array) -> void:
	print("STARTING MODIFIER SELECTION FOR: ", minigame);
	
	var local_id = Main.player_steam_id if not Network.use_local_networking else multiplayer.get_unique_id();
	current_role = MinigameManager.get_player_role(local_id);
	
	if current_role == MinigameManager.PlayerGroup.EXPERIMENTAL:
		role_label.text = "You are: EXPERIMENTAL GROUP";
		role_label.modulate = Color.ORANGE;
		instruction_label.text = "Choose your modifier:";
		available_modifiers = experimental_mods;
	else:
		role_label.text = "You are: CONTROL GROUP";
		role_label.modulate = Color.CYAN;
		instruction_label.text = "Choose your modifier (no duplicates allowed):";
		available_modifiers = control_mods;
	
	_create_modifier_buttons();
	_update_selected_modifiers_display();


## Create buttons for available modifiers.
func _create_modifier_buttons() -> void:
	for button in modifier_buttons:
		button.queue_free();
	modifier_buttons.clear();
	
	for modifier in available_modifiers:
		var button = Button.new();
		button.text = modifier.name + "\n" + modifier.description;
		button.custom_minimum_size = Vector2(300, 80);
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;
		
		# Connect button press
		button.pressed.connect(_on_modifier_button_pressed.bind(modifier.name));
		
		modifier_container.add_child(button);
		modifier_buttons.append(button);


## Called when a modifier button is pressed.
func _on_modifier_button_pressed(modifier_name: String) -> void:
	if is_selection_complete:
		return;
	
	print("SELECTED MODIFIER: ", modifier_name);
	selected_modifier = modifier_name;
	
	var local_id = Main.player_steam_id if not Network.use_local_networking else multiplayer.get_unique_id();
	MinigameManager.select_modifier(local_id, modifier_name);
	
	for button in modifier_buttons:
		button.disabled = true;
	
	waiting_label.text = "Waiting for other players to select...";
	waiting_label.visible = true;


## Called when any player selects a modifier.
func _on_modifier_selected(player_id: int, modifier_name: String, current_modifiers: Dictionary) -> void:
	_update_selected_modifiers_display(current_modifiers);

	if current_role == MinigameManager.PlayerGroup.CONTROL:
		_update_button_availability(current_modifiers);


## Update the display of selected modifiers.
func _update_selected_modifiers_display(current_modifiers: Dictionary = {}) -> void:
	var display_text = "Selected Modifiers:\n";
	
	if current_modifiers.has("experimental"):
		display_text += "Experimental: " + current_modifiers["experimental"] + "\n";
	
	if current_modifiers.has("control"):
		display_text += "Control Group:\n";
		for player_id in current_modifiers["control"]:
			display_text += "  Player " + str(player_id) + ": " + current_modifiers["control"][player_id] + "\n";
	
	selected_modifiers_label.text = display_text;


## Update button availability for control group (disable taken modifiers).
func _update_button_availability(current_modifiers: Dictionary) -> void:
	if current_role != MinigameManager.PlayerGroup.CONTROL:
		return;
	
	var taken_modifiers: Array = [];
	if current_modifiers.has("control"):
		for player_id in current_modifiers["control"]:
			taken_modifiers.append(current_modifiers["control"][player_id]);
	
	for i in range(modifier_buttons.size()):
		var button = modifier_buttons[i];
		var modifier_name = available_modifiers[i].name;
		
		if modifier_name in taken_modifiers and selected_modifier != modifier_name:
			button.disabled = true;
			button.modulate = Color.GRAY;
			button.text = modifier_name + " (TAKEN)";
		elif not button.disabled:  # Don't re-enable if already selected
			button.disabled = false;
			button.modulate = Color.WHITE;
			button.text = available_modifiers[i].name + "\n" + available_modifiers[i].description;
