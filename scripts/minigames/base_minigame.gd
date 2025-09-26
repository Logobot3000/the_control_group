extends Node;

## The base class for all minigames.
class_name BaseMinigame;

## Emits when the minigame finishes.
signal minigame_finished(winner_group: String, scores: Dictionary);

## The duration of the minigame. Default 90 seconds.
@export var game_duration: float = 60.0;

## The time remaining in the minigame.
var time_remaining: float;
## Determines whether or not the game is active.
var game_active: bool = false;
## A reference to the experimental group. -1 means no experimental group.
var experimental_group: int = -1;
## A reference to the control group. An empty array means no control group.
var control_group: Array = [];
## A reference to the modifiers. An empty dictionary means no modifiers.
var modifiers: Dictionary = {};
## The experimental group's score.
var experimental_score: int = 0;
## The control group's score.
var control_score: int = 0;
## The individual scores for each player.
var individual_scores: Dictionary = {};
## A timer label reference that will be set by child classes.
var timer_label: Label;
## A score display reference that will be set by child classes.
var score_display: Control;


func _ready() -> void:
	if MinigameManager:
		experimental_group = MinigameManager.current_experimental_group;
		control_group = MinigameManager.current_control_group;
		modifiers = MinigameManager.current_modifiers;
	
	individual_scores[experimental_group] = 0;
	for player_id in control_group:
		individual_scores[player_id] = 0;
	
	setup_minigame();
	start_countdown();


func _process(delta: float) -> void:
	if not game_active: return;
	
	time_remaining -= delta;
	time_remaining = max(0, time_remaining);
	
	update_ui();
	
	if check_early_finish():
		end_game();


## A virtual function to be overriden by child classes. Should set up everything needed for the minigame.
func setup_minigame() -> void:
	print("you shouldn't see this lmao override this now loser");


## Start the countdown before the game begins.
func start_countdown() -> void:
	print("Get ready...");
	await get_tree().create_timer(1.0).timeout;
	print("3...");
	await get_tree().create_timer(1.0).timeout;
	print("2...");
	await get_tree().create_timer(1.0).timeout;
	print("1...");
	await get_tree().create_timer(1.0).timeout;
	print("GO!");
	start_game();


## Start the actual game.
func start_game() -> void:
	game_active = true;
	time_remaining = game_duration;
	
	var timer: SceneTreeTimer = get_tree().create_timer(game_duration);
	timer.timeout.connect(_on_game_timer_timeout);
	
	set_process(true);
	
	print("MINIGAME STARTED");


## Virtual function to be overriden by child classes. Should check early finish conditions.
func check_early_finish() -> bool:
	return false;


## Update the UI elements.
func update_ui() -> void:
	if timer_label:
		timer_label.text = "Time: " + str(int(time_remaining));
	
	update_score_display();


## Virtual function to be overriden by child classes. Should update a score display.
func update_score_display() -> void:
	pass;


## Called when the game timer ends.
func _on_game_timer_timeout() -> void:
	end_game();


## End the minigame and determine a winner.
func end_game() -> void:
	if not game_active: return;
	
	game_active = false;
	set_process(false);
	
	print("MINIGAME ENDED");
	
	control_score = 0;
	for player_id in control_group:
		control_score += individual_scores.get(player_id, 0);
	
	experimental_score = individual_scores.get(experimental_group, 0);
	
	var winner_group: String;
	if experimental_score > control_score: winner_group = "experimental";
	elif experimental_score < control_score: winner_group = "control";
	else: winner_group = "tie";
	
	print("FINAL SCORES - EXPERIMENTAL: ", experimental_score, ", CONTROL: ", control_score);
	print("WINNER: ", winner_group);
	
	show_results(winner_group);
	
	var final_scores = {
		"experimental": experimental_score,
		"control": control_score,
		"individual": individual_scores
	};
	minigame_finished.emit(winner_group, final_scores);


## Virtual function to be overriden by child classes. Should display the scores to the player.
func show_results(winner: String) -> void:
	pass;


## Adds a score for a player.
func add_score(player_id: int, points: int) -> void:
	if not individual_scores.has(player_id): individual_scores[player_id] = 0;
	
	individual_scores[player_id] += points;
	
	var score_data = {
		"message": "score_update",
		"player_id": player_id,
		"points": points,
		"total_score": individual_scores[player_id]
	};
	Network.send_p2p_packet(0, score_data);
	
	print("PLAYER ", player_id, " SCORED ", points, " POINTS! TOTAL: ", individual_scores[player_id]);


## Checks if a player has a specific modifier.
func player_has_modifier(player_id: int, modifier_name: String) -> bool:
	if player_id == experimental_group:
		return modifiers.get("experimental", "") == modifier_name;
	elif player_id in control_group:
		var control_mods = modifiers.get("control", {});
		return control_mods.get(player_id, "") == modifier_name;
	return false;


## Get the modifier description for UI reasons.
func get_modifier_description(player_id: int) -> String:
	var modifier_name = "";
	if player_id == experimental_group:
		modifier_name = modifiers.get("experimental", "");
	elif player_id in control_group:
		var control_mods = modifiers.get("control", {});
		modifier_name = control_mods.get(player_id, "");
	
	if modifier_name.is_empty():
		return "No modifier";
	
	return modifier_name;


## Checks if this is the local player.
func is_local_player(player_id: int) -> bool:
	if not Network.use_local_networking:
		return player_id == Main.player_steam_id;
	else:
		return player_id == multiplayer.get_unique_id();


## Gets the local player's role.
func get_local_player_role() -> Enums.PlayerGroup:
	var local_id = Main.player_steam_id if not Network.use_local_networking else multiplayer.get_unique_id();
	return MinigameManager.get_player_role(local_id) if MinigameManager else Enums.PlayerGroup.CONTROL;
