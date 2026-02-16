class_name NarratorComponent;
extends Node2D;

signal finished;

var currently_playing: AudioStreamPlayer2D = null;
var playing_length: float = 0;
var vol_control = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];


func narrator_intro(intro_num: int = 0) -> void:
	currently_playing = get_node("NarratorIntro").get_node("NarratorIntro" + str(intro_num));
	var current_currently_playing = currently_playing;
	if currently_playing:
		currently_playing.play();
		playing_length = currently_playing.stream.get_length();
		await currently_playing.finished;
		if currently_playing == current_currently_playing:
			currently_playing = null;
			playing_length = 0;
			finished.emit();


func narrator_disabled() -> void:
	currently_playing = get_node("NarratorDisabled/NarratorDisabled");
	var current_currently_playing = currently_playing;
	if currently_playing:
		currently_playing.play();
		playing_length = currently_playing.stream.get_length();
		await currently_playing.finished;
		if currently_playing == current_currently_playing:
			currently_playing = null;
			playing_length = 0;
			finished.emit();


func narrator_reenabled() -> void:
	currently_playing = get_node("NarratorReenabled/NarratorReenabled");
	var current_currently_playing = currently_playing;
	if currently_playing:
		currently_playing.play();
		playing_length = currently_playing.stream.get_length();
		await currently_playing.finished;
		if currently_playing == current_currently_playing:
			currently_playing = null;
			playing_length = 0;
			finished.emit();


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
