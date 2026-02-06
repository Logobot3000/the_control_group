extends Area2D;

@export var target_tier: int = 0;


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
			get_node("AnimatedSprite2D").play("defualt");
		1:
			get_node("AnimatedSprite2D").play("bronze");
		2:
			get_node("AnimatedSprite2D").play("silver");
		3:
			get_node("AnimatedSprite2D").play("gold");


func hit_control():
	get_node("AnimatedSprite2D").visible = false;
	get_node("ControlHitParticles").emitting = true;


func hit_experimental():
	get_node("AnimatedSprite2D").visible = false;
	get_node("experimentalHitParticles").emitting = true;


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	print("woah")
	if event.is_action("click"):
		for player in get_tree().current_scene.get_node("Players").get_children():
			if player.steam_id == Main.player_steam_id:
				if player.is_experimental:
					hit_experimental();
				else:
					hit_control();
