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
## Whether or not the experimental group has chosen their modifiers, meant for the host.
var has_experimental_chosen: bool = false;
## The current minigame instance.
var current_minigame_instance: BaseMinigame = null;
## The path for the fish component for the fishing minigame.
var fish_component_path: PackedScene = preload("res://scenes/components/minigames/fishing/fish_component.tscn");
## The path for the laser component for the space minigame.
var laser_component_path: PackedScene = preload("res://scenes/components/minigames/space/laser_component.tscn");
## The array of the names of all available minigames. UPDATE THIS WHENEVER A MINIGAME IS ADDED.
var available_minigames: Array = [
	"fishing",
	"space",
	"juggernaut",
];
## The array of the display names of all available minigames. UPDATE THIS WHENEVER A MINIGAME IS ADDED. This shouldn't be necessary but it is.
var available_minigame_names: Dictionary = {
	"fishing": "Fishing",
	"space": "Space",
	"juggernaut": "Juggernaut",
};
## The modifier definitions for each available minigame. UPDATE THIS WHENEVER A MINIGAME IS ADDED.
var minigame_modifiers: Dictionary = {
	"fishing": {
		"experimental": [
			{"id": 1, "name": "Net Harpoon", "description": "Catches multiple fish, but has a slow reel speed. Ignores jellyfish."},
			{"id": 2, "name": "Antivenom Hook", "description": "Allows reeling in jellyfish, also adds more jellyfish."},
			{"id": 3, "name": "EMP", "description": "Stuns ships around you (20s cooldown). Gives a temporary rod upgrade per player stunned."}
		],
		"control": [
			{"id": 1, "name": "Upgraded Rod", "description": "Reels in fish faster."},
			{"id": 2, "name": "Upgraded Lure", "description": "Fish become attracted to your rod."},
			{"id": 3, "name": "Upgraded Hook", "description": "Catches two fish instead of one."}
		]
	},
	"space": {
		"experimental": [
			{"id": 1, "name": "Shield", "description": "Provides a shield that breaks after 3 hits."},
			{"id": 2, "name": "Charging Laser", "description": "Allows for a charge shot that deals more damage, but uses all charges."},
			{"id": 3, "name": "Tracking Lasers", "description": "Lasers track the nearest player. May track through walls."}
		],
		"control": [
			{"id": 1, "name": "Faster Ship", "description": "Increases the speed of the ship."},
			{"id": 2, "name": "Extra Lasers", "description": "Grants 2 extra laser charges."},
			{"id": 3, "name": "Faster Reload", "description": "Reloads twice as fast."}
		]
	},
	"juggernaut": {
		"experimental": [
			{"id": 1, "name": "Speed Boost", "description": "Allows you to move faster (10s cooldown, 4s duration)."},
			{"id": 2, "name": "Sketchy Teleportation", "description": "Teleport to a random position on the map (3x a game)."},
			{"id": 3, "name": "Stun Mines", "description": "Place mines down that stun Control Group players."}
		],
		"control": [
			{"id": 1, "name": "Faster Movement", "description": "Allows you to move faster."},
			{"id": 2, "name": "Extra Life", "description": "Allows you to survive the Juggernaut one extra time."},
			{"id": 3, "name": "Jump Boost", "description": "Allows you to jump higher."}
		]
	},
};

## The spawn positions for each available minigame. UPDATE THIS WHENEVER A MINIGAME IS ADDED.
var spawn_positions: Dictionary = {
	"fishing": {
		"experimental": Vector2(150, 10),
		"control": [
			Vector2(-150, 0), Vector2(-100, 0), Vector2(-50, 0)
		]
	},
	"space": {
		"experimental": Vector2(-240, 112),
		"control": [
			Vector2(-272, -128), Vector2(272, -128), Vector2(272, 144)
		]
	},
	"juggernaut": {
		"experimental": Vector2(150, 10),
		"control": [
			Vector2(-150, 0), Vector2(-100, 0), Vector2(-50, 0)
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
			has_experimental_chosen = false;
			current_minigame = "";
			
			if Network.is_host:
				current_minigame = available_minigames[randi() % (available_minigames.size())];
				
				current_minigame = "juggernaut" # for if one needs to be selected
				
				var minigame_chosen_data: Dictionary = {
					"message": "minigame_chosen",
					"minigame": current_minigame
				};
				Network.send_p2p_packet(0, minigame_chosen_data);
			
			## Add narrator dialogue and tv logic here
			
			var door: MinigameDoor = get_tree().current_scene.get_node("MinigameDoor");
			if is_door_open == false:
				door.open_door();
				is_door_open = true;
			await get_tree().create_timer(2.5).timeout; ## Wait for door to open
			countdown_timer(10);
		
		Enums.GameState.GROUP_ASSIGNMENT:
			print("STATE UPDATE: GROUP_ASSIGNMENT")
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
			
			await get_tree().create_timer(2.5).timeout;
			var group_assignment_ui = get_tree().current_scene.get_node("Selection").get_node("GroupAssignment");
			
			if ready_for_minigame.has(Main.player_steam_id): group_assignment_ui.get_node("AnimationPlayer").play("fade_in");
			var control_group_label: Sprite2D = group_assignment_ui.get_node("Panel").get_node("VBoxContainer").get_node("ControlGroup");
			var experimental_group_label: Sprite2D = group_assignment_ui.get_node("Panel").get_node("VBoxContainer").get_node("ExperimentalGroup");
			control_group_label.visible = false;
			experimental_group_label.visible = false;
			
			await get_tree().create_timer(3).timeout;
			
			if Main.player_steam_id == current_experimental_group:
				experimental_group_label.visible = true;
			else:
				control_group_label.visible = true;
			
			await get_tree().create_timer(3).timeout;
			
			if Network.is_host:
				Main.update_game_state(Enums.GameState.MODIFIER_SELECTION);
		
		Enums.GameState.MODIFIER_SELECTION:
			print("STATE UPDATE: MODIFIER_SELECTION");
			if ready_for_minigame.has(Main.player_steam_id):
				var modifier_selection_ui: Control = get_tree().current_scene.get_node("Selection").get_node("ModifierSelection");
				if Main.player_steam_id == current_experimental_group:
					modifier_selection_ui.get_node("Experimental").visible = true;
					modifier_selection_ui.get_node("Experimental").get_node("VBoxContainer").get_node("Modifier").get_node("Modifier1").get_node("Pick").pressed.connect(_update_experimental_group_modifier);
					modifier_selection_ui.get_node("Experimental").get_node("VBoxContainer").get_node("Modifier").get_node("Modifier2").get_node("Pick").pressed.connect(_update_experimental_group_modifier);
					modifier_selection_ui.get_node("Experimental").get_node("VBoxContainer").get_node("Modifier").get_node("Modifier3").get_node("Pick").pressed.connect(_update_experimental_group_modifier);
					for modifier in minigame_modifiers[current_minigame]["experimental"]:
						var modifier_ui_container: VBoxContainer = modifier_selection_ui.get_node("Experimental").get_node("VBoxContainer").get_node("Modifier").get_node("Modifier" + str(modifier["id"]));
						modifier_ui_container.get_node("Title").text = modifier["name"];
						modifier_ui_container.get_node("Description").add_theme_color_override("font_color", Constants.GAME_COLORS["gray"]);
						modifier_ui_container.get_node("Description").text = modifier["description"];
				else:
					modifier_selection_ui.get_node("Control").visible = true;
				modifier_selection_ui.get_node("AnimationPlayer").play("fade_in");
				
			if Network.is_host:
				var control_group_modifier_update: Dictionary = {
					"message": "control_group_modifier_update",
					"modifiers": {}
				};
				var i: int = 0;
				var ids: Array = [];
				for member in current_control_group:
					ids.append(i);
					i += 1;
				ids.shuffle();
				if current_control_group.size() == 1:
					control_group_modifier_update["modifiers"] = {
						current_control_group[0]: minigame_modifiers[current_minigame]["control"][randi_range(0, 2)]
					};
				elif current_control_group.size() == 2:
					var rand_one: int = randi_range(0, 2);
					var rand_two: int;
					if rand_one == 0:
						rand_two = randi_range(1, 2);
					elif rand_one == 1:
						rand_two = randi_range(0, 2);
						if rand_two == 1: rand_two = 0;
					else:
						rand_two = randi_range(0, 1);
					control_group_modifier_update["modifiers"] = {
						current_control_group[0]: minigame_modifiers[current_minigame]["control"][rand_one],
						current_control_group[1]: minigame_modifiers[current_minigame]["control"][rand_two]
					};
				else:
					control_group_modifier_update["modifiers"] = {
						current_control_group[0]: minigame_modifiers[current_minigame]["control"][ids[0]],
						current_control_group[1]: minigame_modifiers[current_minigame]["control"][ids[1]],
						current_control_group[2]: minigame_modifiers[current_minigame]["control"][ids[2]]
					};
				Network.send_p2p_packet(0, control_group_modifier_update);
				current_modifiers["control"] = control_group_modifier_update["modifiers"];
			
			if Main.player_steam_id == current_experimental_group:
				await get_tree().create_timer(10).timeout;
				if not has_experimental_chosen:
					var experimental_group_modifier_update: Dictionary = {
						"message": "experimental_group_modifier_update",
						"modifier": minigame_modifiers[current_minigame]["experimental"][randi() % 3]
					};
					Network.send_p2p_packet(0, experimental_group_modifier_update);
					set_experimental_group_modifier(experimental_group_modifier_update);
		
		Enums.GameState.MINIGAME_START:
			print("STATE UPDATE: MINIGAME_START");
			
			var chosen_minigame_instance_path: String = "res://scenes/minigames/" + current_minigame + ".tscn";
			current_minigame_instance = load(chosen_minigame_instance_path).instantiate();
			get_tree().current_scene.add_child(current_minigame_instance);
			
			if ready_for_minigame.has(Main.player_steam_id):
				get_tree().current_scene.get_node("Camera2D").enabled = false;
			if Network.is_host:
				var control_group_spawn_pos_incrementer = 0;
				var spawn_pos_update_dict: Dictionary = {
					"message": "spawn_pos_update",
					"experimental": [0, Vector2.ZERO],
					"control": {
						0: [0, Vector2.ZERO],
						1: [0, Vector2.ZERO],
						2: [0, Vector2.ZERO]
					}
				};
				for player in get_tree().current_scene.get_node("Players").get_children():
					if current_experimental_group == player.steam_id:
						player.global_position = Vector2(1000 + spawn_positions[current_minigame]["experimental"].x, 1000 + spawn_positions[current_minigame]["experimental"].y);
						spawn_pos_update_dict["experimental"][0] = player.steam_id;
						spawn_pos_update_dict["experimental"][1] = player.global_position;
					elif ready_for_minigame.has(player.steam_id):
						player.global_position = Vector2(1000 + spawn_positions[current_minigame]["control"][control_group_spawn_pos_incrementer].x, 1000 + spawn_positions[current_minigame]["control"][control_group_spawn_pos_incrementer].y);
						spawn_pos_update_dict["control"][control_group_spawn_pos_incrementer][0] = player.steam_id;
						spawn_pos_update_dict["control"][control_group_spawn_pos_incrementer][1] = player.global_position;
						control_group_spawn_pos_incrementer += 1;
				Network.send_p2p_packet(0, spawn_pos_update_dict);
			
		Enums.GameState.MINIGAME_END:
			print("STATE UPDATE: MINIGAME_END");
			
			var group_assignment_ui = get_tree().current_scene.get_node("Selection").get_node("GroupAssignment");
			group_assignment_ui.get_node("AnimationPlayer").play("RESET");
			var control_group_label: Sprite2D = group_assignment_ui.get_node("Panel").get_node("VBoxContainer").get_node("ControlGroup");
			var experimental_group_label: Sprite2D = group_assignment_ui.get_node("Panel").get_node("VBoxContainer").get_node("ExperimentalGroup");
			control_group_label.visible = false;
			experimental_group_label.visible = false;
			
			var modifier_selection_ui: Control = get_tree().current_scene.get_node("Selection").get_node("ModifierSelection");
			modifier_selection_ui.get_node("Experimental").visible = false;
			modifier_selection_ui.get_node("Control").visible = false;
			modifier_selection_ui.get_node("AnimationPlayer").play("RESET");
			for node in modifier_selection_ui.get_node("Experimental").get_node("VBoxContainer").get_node("Modifier").get_children():
				if node is VBoxContainer:
					node.visible = true;
					node.alignment = 1;
					node.get_node("Pick").visible = true;
					node.get_node("Gradient").visible = true;
					node.get_node("Title").add_theme_font_size_override("font_size", 8);
					node.get_parent().get_parent().get_node("PleaseSelect").visible = true;
					node.get_parent().get_parent().get_node("PleaseSelectMargin").size_flags_vertical = Control.SizeFlags.SIZE_EXPAND_FILL;
					node.get_parent().get_parent().get_node("YouAre").visible = false;
					node.get_parent().size_flags_vertical = 1;
			var modifier_ui_container: VBoxContainer = modifier_selection_ui.get_node("Control").get_node("VBoxContainer");
			modifier_ui_container.get_node("Modifier").add_theme_font_size_override("font_size", 26);
			modifier_ui_container.get_node("Modifier").text = "";
			modifier_ui_container.get_node("WaitingForExperimental").visible = true;
			modifier_ui_container.get_node("ModifierDescription").self_modulate.a = 0;
			modifier_ui_container.get_node("ModifierDescription").text = "";
			
			for player in get_tree().current_scene.get_node("Players").get_children():
				if ready_for_minigame.has(player.steam_id):
					player.global_position = Vector2(0, 0);
			get_tree().current_scene.get_node(available_minigame_names[current_minigame]).queue_free();
			get_tree().current_scene.get_node("Camera2D").enabled = true;
			
			var results_page = get_tree().current_scene.get_node("Results").get_node("ResultsScreen");
			results_page.get_node("AnimationPlayer").play("RESET");
			if ready_for_minigame.has(Main.player_steam_id):
				results_page.visible = true;
			
			var experimental_points: int = 0;
			if current_scores.has(current_experimental_group):
				experimental_points = current_scores[current_experimental_group];
			for pl in ready_for_minigame:
				if not current_scores.has(pl):
					current_scores[pl] = 0;
			var total_control_points: int = 0;
			var control_won: bool = true;
			var mvp_id = 0;
			var lvp_id = 0;
			var mvp_name = "";
			var lvp_name = "";
			var mvp_score = 0;
			var lvp_score = 100000000;
			for scored_player in current_scores:
				if scored_player == MinigameManager.current_experimental_group:
					pass
				else:
					total_control_points += current_scores[scored_player];
					if current_scores[scored_player] > mvp_score:
						mvp_score = current_scores[scored_player];
						mvp_id = scored_player;
					if current_scores[scored_player] < lvp_score:
						lvp_score = current_scores[scored_player];
						lvp_id = scored_player;
			for player in get_tree().current_scene.get_node("Players").get_children():
				if ready_for_minigame.has(player.steam_id):
					if player.steam_id == mvp_id:
						mvp_name = player.name;
					if player.steam_id == lvp_id:
						lvp_name = player.name;
			results_page.get_node("ControlPoints").text = str(total_control_points);
			results_page.get_node("ExperimentalPoints").text = str(experimental_points);
			if experimental_points > total_control_points:
				control_won = false;
			if control_won:
				results_page.get_node("ControlWinner").visible = true;
			else:
				results_page.get_node("ExperimentalWinner").visible = true;
			if control_won and current_control_group.size() >= 2:
				results_page.get_node("ControlWNotes").visible = true;
				results_page.get_node("MVP").text = mvp_name;
				results_page.get_node("LVP").text = lvp_name;
			else:
				results_page.get_node("ExperimentalWNotes").visible = true;
			
			await get_tree().create_timer(1).timeout;
			if ready_for_minigame.has(Main.player_steam_id):
				results_page.get_node("AnimationPlayer").play("show");
				await get_tree().create_timer(0.5).timeout;
				results_page.get_node("Confetti").emitting = true;
				await get_tree().create_timer(4.5).timeout;
				results_page.get_node("AnimationPlayer").play("hide");
				await get_tree().create_timer(1).timeout;
				results_page.visible = false;
			
			results_page.get_node("ControlWinner").visible = false;
			results_page.get_node("ExperimentalWinner").visible = false;
			results_page.get_node("ControlWNotes").visible = false;
			results_page.get_node("ExperimentalWNotes").visible = false;
			
			if Network.is_host:
				Main.update_game_state(Enums.GameState.LOBBY);

## Sets the current minigame.
func set_current_minigame(readable_data: Dictionary) -> void:
	current_minigame = readable_data["minigame"];


## Readies a player for the next minigame.
func set_ready_for_minigame(readable_data: Dictionary) -> void:
	if not ready_for_minigame.has(readable_data["steam_id"]):
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


## Set the control group modifiers.
func set_control_group_modifiers(readable_data: Dictionary) -> void:
	current_modifiers["control"] = readable_data["modifiers"];


## Do the logic for the experimental group modifier.
func _update_experimental_group_modifier() -> void:
	var chosen_modifier = get_viewport().gui_get_focus_owner();
	if not chosen_modifier: return;
	var modifier_container: VBoxContainer = chosen_modifier.get_parent();
	var modifier: Dictionary;
	for mod in minigame_modifiers[current_minigame]["experimental"]:
		if mod.get("name") == modifier_container.get_node("Title").text:
			modifier = mod;
			break;
	var experimental_group_modifier_update: Dictionary = {
		"message": "experimental_group_modifier_update",
		"modifier": modifier
	};
	Network.send_p2p_packet(0, experimental_group_modifier_update);
	set_experimental_group_modifier(experimental_group_modifier_update);


## Set the experimental group modifier
func set_experimental_group_modifier(readable_data: Dictionary) -> void:
	if ready_for_minigame.has(Main.player_steam_id):
		current_modifiers["experimental"] = readable_data["modifier"];
		has_experimental_chosen = true;
		var modifier_selection_ui: Control = get_tree().current_scene.get_node("Selection").get_node("ModifierSelection");
		
		if Main.player_steam_id == current_experimental_group:
			for node in modifier_selection_ui.get_node("Experimental").get_node("VBoxContainer").get_node("Modifier").get_children():
				if node is VBoxContainer:
					if node.get_node("Title").text != current_modifiers["experimental"]["name"]:
						node.visible = false;
					else:
						node.alignment = 1;
						node.get_node("Pick").visible = false;
						node.get_node("Gradient").visible = false;
						node.get_node("Title").add_theme_font_size_override("font_size", 20);
						node.get_parent().get_parent().get_node("PleaseSelect").visible = false;
						node.get_parent().get_parent().get_node("PleaseSelectMargin").size_flags_vertical = Control.SizeFlags.SIZE_SHRINK_BEGIN;
						node.get_parent().get_parent().get_node("YouAre").visible = true;
						node.get_parent().size_flags_vertical = 1;
		else:
			var modifier_ui_container: VBoxContainer = modifier_selection_ui.get_node("Control").get_node("VBoxContainer");
			var modifier = current_modifiers["control"][Main.player_steam_id];
			modifier_ui_container.get_node("Modifier").text = modifier["name"];
			modifier_ui_container.get_node("Modifier").add_theme_font_size_override("font_size", 20);
			modifier_ui_container.get_node("WaitingForExperimental").visible = false;
			modifier_ui_container.get_node("ModifierDescription").self_modulate.a = 1;
			modifier_ui_container.get_node("ModifierDescription").add_theme_color_override("font_color", Constants.GAME_COLORS["gray"]);
			modifier_ui_container.get_node("ModifierDescription").text = modifier["description"];
			modifier_ui_container.get_node("ModifierDescription").add_theme_font_size_override("font_size", 8);
		
		await get_tree().create_timer(3).timeout;
	
	if Network.is_host:
		Main.update_game_state(Enums.GameState.MINIGAME_START);


## Sets all the players to their correct spawn positions before the minigame
func spawn_pos_update(readable_data: Dictionary) -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id == readable_data["experimental"][0]:
			player.global_position = readable_data["experimental"][1];
		elif player.steam_id == readable_data["control"][0][0] and ready_for_minigame.has(player.steam_id):
			player.global_position = readable_data["control"][0][1];
		elif player.steam_id == readable_data["control"][1][0] and ready_for_minigame.has(player.steam_id):
			player.global_position = readable_data["control"][1][1];
		elif player.steam_id == readable_data["control"][2][0] and ready_for_minigame.has(player.steam_id):
			player.global_position = readable_data["control"][2][1];


## Updates the current score.
func update_scores(readable_data: Dictionary) -> void:
	current_scores = readable_data["scores"];


## Update visual timer for minigame countdown timer.
func update_minigame_timer(readable_data: Dictionary) -> void:
	var minigame_name: NodePath = NodePath(MinigameManager.available_minigame_names[MinigameManager.current_minigame]);
	var minigame_timer: Label = get_tree().current_scene.get_node(minigame_name).get_node("BaseMinigame").get_node("TV").get_node("MinigameTimer");
	var time: float = readable_data["time"];
	if time <= 0: 
		minigame_timer.text = "";
		is_timer_running = false;
		get_tree().current_scene.get_node(minigame_name).minigame_ended.emit();
	else:
		minigame_timer.text = str(time);


## Update the hook components in the fishing minigame.
func hook_update(readable_data: Dictionary) -> void:
	if not readable_data["steam_id"] == Main.player_steam_id:
		for player in get_tree().current_scene.get_node("Players").get_children():
			if player.steam_id == readable_data["steam_id"] and player.get_node("HookComponent"):
				if readable_data["direction"] == 0:
					player.get_node("HookComponent").lower_hook(false);
				else:
					player.get_node("HookComponent").raise_hook(false);
				break;


## Spawn fish for all players in the fishing minigame.
func fish_spawn(readable_data: Dictionary) -> void:
	var fish: FishComponent = fish_component_path.instantiate();
	fish.is_jellyfish = readable_data["is_jellyfish"];
	fish.color = readable_data["color"];
	fish.time_scale = readable_data["time_scale"];
	fish.fish_speed = readable_data["fish_speed"];
	if readable_data["spawn_from_right"]:
		fish.spawn_from_right = false;
		get_tree().current_scene.add_child(fish);
		fish.position = readable_data["fish_door_left_pos"];
	else:
		get_tree().current_scene.add_child(fish);
		fish.position =  readable_data["fish_door_right_pos"];
	fish.position.y += readable_data["height_modifier"];


## Stuns a player
func stun(readable_data: Dictionary):
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id == Main.player_steam_id:
			player.stun(readable_data["time"]);


## Does the EMP particles for a player
func emp_particles(readable_data: Dictionary):
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id == readable_data["steam_id"]:
			player.emp_area.get_node("Particles").emitting = true;


## Fires a laser for the space minigame
func laser_fired(readable_data: Dictionary):
	var laser = laser_component_path.instantiate();
	laser.laser_type = readable_data["laser_type"];
	laser.shot_rotation = readable_data["shot_rotation"];
	laser.steam_id = readable_data["steam_id"];
	laser.tracking_active = readable_data["tracking"]
	get_tree().current_scene.get_node("Space").get_node("Lasers").add_child(laser);
	laser.global_position = readable_data["position"];


## Kills a player
func player_died(readable_data: Dictionary):
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id == readable_data["steam_id"]:
			var explosion = load("res://scenes/components/death_effect_component.tscn").instantiate();
			get_tree().current_scene.add_child(explosion);
			explosion.position = player.position;
			player.is_dead = true;
			player.visible = false;
			player.can_move = false;
			player.position = Vector2.ZERO;
			explosion.emitting = true;
			await get_tree().create_timer(0.5).timeout;
			explosion.queue_free();


## Kills a player
func player_undied(readable_data: Dictionary):
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id == readable_data["steam_id"]:
			player.is_dead = false;
			player.visible = true;
			player.can_move = true;
