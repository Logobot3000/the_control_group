class_name NarratorComponent;
extends Node2D;

var currently_playing: AudioStreamPlayer2D = null;
var playing_length: float = 0;
var vol_control = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];


func narrator_intro(intro_range: Vector2, intro_override: int = 0) -> void:
	var intro_num: int;
	if intro_override != 0:
		intro_num = intro_override;
	else:
		intro_num = randi_range(intro_range.x, intro_range.y);
	currently_playing = get_node("NarratorIntro").get_node("NarratorIntro" + str(intro_num));
	if currently_playing:
		currently_playing.play();
		playing_length = currently_playing.stream.get_length();
		await currently_playing.finished;
		currently_playing = null;
		playing_length = 0;


func _process(delta: float) -> void:
	var volume: float = 0.0;
	if currently_playing:
		var spectrum = AudioServer.get_bus_effect_instance(0, 0);
		volume = spectrum.get_magnitude_for_frequency_range(100, 1000).length() * 10;
	vol_control.pop_back();
	vol_control.push_front(volume);
	var i = 0;
	for rect in get_tree().current_scene.get_node("TV").get_node("NarratorVisualizer").get_children():
		rect.scale.y = vol_control[i];
		i += 1;
