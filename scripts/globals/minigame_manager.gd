extends Node;

## The name of the current minigame that is active. If this is an empty string, there is no chosen minigame.
var current_minigame: String = "";
## The players ready for the next minigame. If array is empty, there are none.
var ready_for_minigame: Array = [];
## The steam/local ID of the current experimental group player. -1 means there is none.
var current_experimental_group: int = -1;
## An array of the steam/local IDs of the current control group players. An empty array means there are none.
var current_control_group: Array = [];
## A dictionary of the modifiers applied to the playres. An empty dictionary means there are none.
var current_modifiers: Dictionary = {};
## A dictionary of the current scores for the players. An empty dictionary means there are none.
var current_scores: Dictionary = {};
## Whether or not the minigame door is already open, meant for the host.
var is_door_open: bool = false;
## Whether or not the countdown timer is already running, meant for the host.
var is_timer_running: bool = false;
## The array of the names of all available minigames. UPDATE THIS WHENEVER A MINIGAME IS ADDED.
var available_minigames: Array = [
	"test_minigame",
];
## The modifier definitions for each available minigame. UPDATE THIS WHENEVER A MINIGAME IS ADDED.
var minigame_modifiers: Dictionary = {
	"test_minigame": {
		"experimental": [
			{"name": "Experimental Modifier 1", "description": "Experimental Modifier 1 Description"},
			{"name": "Experimental Modifier 2", "description": "Experimental Modifier 2 Description"},
			{"name": "Experimental Modifier 3", "description": "Experimental Modifier 3 Description"}
		],
		"control": [
			{"name": "Control Modifier 1", "description": "Control Modifier 1 Description"},
			{"name": "Control Modifier 2", "description": "Control Modifier 2 Description"},
			{"name": "Control Modifier 3", "description": "Control Modifier 3 Description"}
		]
	},
};


## Handles updates in game state.
func handle_game_state_update(new_game_state: Enums.GameState) -> void:
	match new_game_state:
		Enums.GameState.LOBBY:
			print("STATE UPDATE: LOBBY");
			current_experimental_group = -1;
			current_control_group.clear();
			current_modifiers.clear();
			current_scores.clear();
			ready_for_minigame.clear();
			
			current_minigame = available_minigames[randi() % (available_minigames.size())];
			
			## Add narrator dialogue and tv logic here
			
			var door: MinigameDoor = get_tree().current_scene.get_node("MinigameDoor");
			if is_door_open == false:
				door.open_door();
				is_door_open = true;
			await get_tree().create_timer(2.5).timeout; ## Wait for door to open
			countdown_timer(10);
		
		Enums.GameState.GROUP_ASSIGNMENT:
			print("STATE UPDATE: GROUP_ASSIGNMENT")
			if ready_for_minigame.has(Main.player_steam_id):
				await get_tree().create_timer(2.5).timeout;
				var group_assignment_ui = get_tree().current_scene.get_node("Selection").get_node("GroupAssignment");
				group_assignment_ui.get_node("AnimationPlayer").play("fade_in");
				
				if Network.is_host:
					current_experimental_group = ready_for_minigame[randi() % ready_for_minigame.size()];
					for id in ready_for_minigame:
						if id != current_experimental_group:
							current_control_group.append(id);
					var group_data: Dictionary = {
						"message": "assign_groups",
						"current_experimental_group": current_experimental_group,
						"current_control_group": current_control_group
					};
					Network.send_p2p_packet(0, group_data);
				
				await get_tree().create_timer(3).timeout;
				
				var group_label: Label = group_assignment_ui.get_node("Panel").get_node("VBoxContainer").get_node("Group");
				if Main.player_steam_id == current_experimental_group:
					group_label.add_theme_color_override("font_color", Color((255.0 / 256.0), (213.0 / 256.0), (25.0 / 256.0), 1.0));
					group_label.text = "Experimental Group";
				else:
					group_label.add_theme_color_override("font_color", Color((25.0 / 256.0), (163.0 / 256.0), (255.0 / 256.0), 1.0));
					group_label.text = "Control Group";


## Readies a player for the next minigame.
func set_ready_for_minigame(readable_data: Dictionary) -> void:
	ready_for_minigame.append(readable_data["steam_id"]);


## Countdown timer for game.
func countdown_timer(time: float) -> void:
	if not is_timer_running and time == 10:
		is_timer_running = true;
	elif is_timer_running and time == 10:
		return;
	
	if Network.is_host:
		time = snapped(time, 0.1);
		var timer_update: Dictionary = {
			"message": "timer_updated",
			"time": time
		};
		Network.send_p2p_packet(0, timer_update);
		update_timer({"time": time});
		
		await get_tree().create_timer(0.1).timeout;
		if time > 0: countdown_timer(time - 0.1);


## Update visual timer for countdown timer.
func update_timer(readable_data: Dictionary) -> void:
	var ready_timer: Label = get_tree().current_scene.get_node("TV").get_node("ReadyTimer");
	var time: float = readable_data["time"];
	if time <= 0: 
		ready_timer.text = "";
		is_timer_running = false;
		_finish_lobby_handling();
	else:
		ready_timer.text = str(time);


## Do the second half of the logic for the lobby game state.
func _finish_lobby_handling() -> void:
	print("yo")
	var door: MinigameDoor = get_tree().current_scene.get_node("MinigameDoor");
	await get_tree().create_timer(2).timeout; ## Wait for door to close
	door.close_door();
	is_door_open = false;
	
	if ready_for_minigame.size() < 2:
		print("Not enough players to start a minigame");
		for player in get_tree().current_scene.get_node("Players").get_children():
			if ready_for_minigame.size() != 0:
				if player.steam_id == ready_for_minigame[0]:
					player.global_position = Vector2.ZERO;
					player.can_move = true;
					break;
		await get_tree().create_timer(5).timeout;
		if Network.is_host:
			Main.update_game_state(Enums.GameState.LOBBY);
	else:
		if Network.is_host:
			Main.update_game_state(Enums.GameState.GROUP_ASSIGNMENT);


## Set groups for the active players.
func assign_groups(readable_data: Dictionary) -> void:
	current_experimental_group = readable_data["current_experimental_group"];
	current_control_group = readable_data["current_control_group"];
