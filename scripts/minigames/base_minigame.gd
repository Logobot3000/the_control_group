extends Node2D;

## The class that is going to be extended from for each minigame.
class_name BaseMinigame;


## Emits when the minigame starts.
signal minigame_started;
## Emits when the minigame ends.
signal minigame_ended;


@export_group("Player Spawn Positions")
## The position for the yellow player to be spawned in for each minigame.
@export var yellow_player_spawn_position: Vector2 = Vector2.ZERO;
## The position for the green player to be spawned in for each minigame.
@export var green_player_spawn_position: Vector2 = Vector2.ZERO;
## The position for the purple player to be spawned in for each minigame.
@export var purple_player_spawn_position: Vector2 = Vector2.ZERO;
## The position for the orange player to be spawned in for each minigame.
@export var orange_player_spawn_position: Vector2 = Vector2.ZERO;

@export_group("Timer Settings")
## How long the minigame timer lasts in seconds.
@export var minigame_timer_length: int = 90;

## Whether or not the timer at the top of the screen is running.
var is_timer_running: bool = false;


func _ready() -> void:
	minigame_started.connect(on_minigame_started);
	minigame_ended.connect(on_minigame_ended);
	
	minigame_setup();
	minigame_started.emit();
	countdown_timer(minigame_timer_length);


## A virtual function that is called whenever the minigame is instantiated.
func minigame_setup() -> void:
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
			"time": time,
			"minigame_instance": self
		};
		Network.send_p2p_packet(0, timer_update);
		MinigameManager.update_minigame_timer({"time": time, "minigame_instance": self});
		
		await get_tree().create_timer(0.1).timeout;
		if time > 0: countdown_timer(time - 0.1);
