extends TextureButton;

# bing bong - Manogne
@onready var small_anim_player: AnimationPlayer = $AnimationPlayerStart;
@onready var anim_player: AnimationPlayer = $"../BigBoyAnimationPlayer";


func _on_mouse_entered() -> void:
	if !small_anim_player.is_playing():
		small_anim_player.play("hover_in");


func _on_mouse_exited() -> void:
	if !small_anim_player.is_playing():
		small_anim_player.play("hover_out");


func _on_pressed() -> void:
	if !anim_player.is_playing():
		anim_player.play("hit_play_button");


func _on_back_pressed() -> void:
	if !anim_player.is_playing():
		anim_player.play_backwards("hit_play_button");
