extends Node2D;

## The class that is going to be extended from for each minigame.
class_name BaseMinigame;


## Emits when the minigame starts.
signal minigame_started;
## Emits when the minigame ends.
signal minigame_ended;

## How long the minigame timer lasts in seconds.
@export var minigame_timer_length: int = 90;

## Whether or not the timer at the top of the screen is running.
var is_timer_running: bool = false;


func _ready() -> void:
	if get_parent() is BaseMinigame:
		return;
	minigame_started.connect(on_minigame_started);
	minigame_ended.connect(on_minigame_ended);
	
	minigame_setup();
	load_modifiers();
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
func score_point() -> void:
	if not MinigameManager.current_scores[Main.player_steam_id]:
		MinigameManager.current_scores[Main.player_steam_id] = 1;
	else:
		MinigameManager.current_scores[Main.player_steam_id] += 1;
	
	var score_update: Dictionary = {
		"message": "score_update",
		"scores": MinigameManager.current_scores
	};
	
	Network.send_p2p_packet(0, score_update);


## A virtual function that is called whenever the minigame has started.
func on_minigame_started() -> void:
	pass;


## A virtual function that is called whenever the minigame has ended.
func on_minigame_ended() -> void:
	pass;


## Countdown timer for game.
func countdown_timer(time: float) -> void:
	if not is_timer_running and time == minigame_timer_length:
		is_timer_running = true;
	elif is_timer_running and time == minigame_timer_length:
		return;
	
	if Network.is_host:
		time = snapped(time, 0.1);
		var timer_update: Dictionary = {
			"message": "minigame_timer_updated",
			"time": time
		};
		Network.send_p2p_packet(0, timer_update);
		MinigameManager.update_minigame_timer({"time": time});
		
		await get_tree().create_timer(0.1).timeout;
		if time > 0: countdown_timer(time - 0.1);
