extends Node2D;

## The class that is going to be extended from for each minigame.
class_name BaseMinigame;


## Emits when the minigame starts.
signal minigame_started;
## Emits when the minigame ends.
signal minigame_ended;

## How long the minigame timer lasts in seconds.
@export var minigame_timer_length: int = 90;

## The experimental group's points container.
@onready var experimental_points_container: Label = $TV/ExperimentalPoints;
## The control group's points container.
@onready var control_points_container: Label = $TV/ControlPoints;

## The experimental group's points.
var experimental_points: int = 0;
## The control group's points.
var control_points: int = 0;
## Whether or not the timer at the top of the screen is running.
var is_timer_running: bool = false;
## Whether or not the current minigame is active.
var minigame_active: bool = false;
## Timer start time
var timer_start_time = 0.0;


func _ready() -> void:
	if not MinigameManager.ready_for_minigame.has(Main.player_steam_id):
		return;
	if get_parent() is BaseMinigame:
		return;
	minigame_started.connect(on_minigame_started);
	minigame_ended.connect(pre_on_minigame_ended);
	
	minigame_setup();
	load_modifiers();
	minigame_active = true;
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.steam_id == MinigameManager.current_experimental_group:
			player.is_experimental = true;
	
	if name != "BaseMinigame":
		get_node("BaseMinigame").get_node("AnimationPlayer").play("go");
	await get_tree().create_timer(1).timeout;
	get_tree().current_scene.get_node("SFX/Select").play();
	await get_tree().create_timer(1).timeout;
	get_tree().current_scene.get_node("SFX/Select").play();
	await get_tree().create_timer(1).timeout;
	get_tree().current_scene.get_node("SFX/Select").play();
	await get_tree().create_timer(1).timeout;
	
	minigame_started.emit();
	for player in get_tree().current_scene.get_node("Players").get_children():
		player.can_move = true;
	countdown_timer(minigame_timer_length);


## A virtual function that is called whenever the minigame is instantiated.
func minigame_setup() -> void:
	pass;


## A virtual function that is called to load the modifiers.
func load_modifiers() -> void:
	pass;


## Adds a one point for the current player in the MinigameManager [member current_score].
func score_point(amount: int) -> void:
	if not MinigameManager.current_scores.get(Main.player_steam_id):
		MinigameManager.current_scores[Main.player_steam_id] = amount;
	else:
		MinigameManager.current_scores[Main.player_steam_id] += amount;
	
	get_tree().current_scene.get_node("SFX/PointScored").play();
	
	var score_update: Dictionary = {
		"message": "score_update",
		"scores": MinigameManager.current_scores
	};
	
	Network.send_p2p_packet(0, score_update);


## Updates scores per group instead of per player.
func update_group_scores() -> void:
	if MinigameManager.ready_for_minigame.has(Main.player_steam_id):
		experimental_points = 0;
		control_points = 0;
		for scored_player in MinigameManager.current_scores:
			if scored_player ==  MinigameManager.current_experimental_group:
				experimental_points += MinigameManager.current_scores[scored_player];
			else:
				control_points += MinigameManager.current_scores[scored_player];
		
		experimental_points_container.text = str(experimental_points);
		control_points_container.text = str(control_points);


## A virtual function that is called whenever the minigame has started.
func on_minigame_started() -> void:
	timer_start_time = 0.0;
	pass;


## A function called when the minigame ends.
func pre_on_minigame_ended() -> void:
	minigame_active = false;
	on_minigame_ended();
	if Network.is_host:
		Main.update_game_state(Enums.GameState.MINIGAME_END);


## A virtual function that is called whenever the minigame has ended.
func on_minigame_ended() -> void:
	pass;


## Countdown timer for game.
func countdown_timer(time: float) -> void:
	if not is_timer_running and time == minigame_timer_length:
		is_timer_running = true
		timer_start_time = Time.get_ticks_msec() / 1000.0
	
	if Network.is_host:
		var now = Time.get_ticks_msec() / 1000.0
		var real_elapsed = now - timer_start_time
		var corrected_time = max(0.0, minigame_timer_length - real_elapsed)
		
		var snapped_time = floor(corrected_time * 10.0) / 10.0;
		
		var timer_update: Dictionary = {
			"message": "minigame_timer_updated",
			"time": snapped_time
		}
		
		Network.send_p2p_packet(0, timer_update)
		MinigameManager.update_minigame_timer({"time": snapped_time})
		
		await get_tree().create_timer(0.1).timeout
		
		if corrected_time > 0:
			countdown_timer(corrected_time)
		else:
			is_timer_running = false;
			minigame_ended.emit();


## Ends a minigame early.
func end_minigame_early() -> void:
	await get_tree().create_timer(1).timeout;
	is_timer_running = false;
	for music in get_tree().current_scene.get_node("MinigameMusic").get_children():
		music.stop();
	minigame_ended.emit();
