extends Area2D;

@export var target_tier: int = 0;
var hit: bool = false;
var id: int = 0;


func _ready() -> void:
	match target_tier:
		0:
			get_node("AppearParticlesDefault").emitting = true;
		1:
			get_node("AppearParticlesBronze").emitting = true;
		2:
			get_node("AppearParticlesSilver").emitting = true;
		3:
			get_node("AppearParticlesGold").emitting = true;
	get_node("AnimationPlayer").play("appear");


func _process(delta: float) -> void:
	match target_tier:
		0:
			get_node("AnimatedSprite2D").play("default");
		1:
			get_node("AnimatedSprite2D").play("bronze");
		2:
			get_node("AnimatedSprite2D").play("silver");
		3:
			get_node("AnimatedSprite2D").play("gold");


func hit_control():
	if not hit:
		get_node("AnimatedSprite2D").visible = false;
		get_node("ControlHitParticles").emitting = true;


func hit_experimental():
	if not hit:
		get_node("AnimatedSprite2D").visible = false;
		get_node("ExperimentalHitParticles").emitting = true;


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action("click"):
		var break_target_data: Dictionary = {
			"message": "break_target",
			"target_id": id,
			"player_id": Main.player_steam_id
		};
		Network.send_p2p_packet(0, break_target_data);
		MinigameManager.break_target(break_target_data);
