extends Node2D;


var wave: int = 0;
var spawn_amt: int = 1;
var enemy_num: int = 0;
var base_spawns: Array = [Vector2(712, 1431), Vector2(1289, 1431)];
var fly_spawns: Array = [Vector2(787, 1178), Vector2(1214, 1178)];
var humpher_spawn: Vector2 = Vector2(1000, 1272);
var wave_active: bool = true;
var pause: bool = true;


func _ready() -> void:
	for player in get_tree().current_scene.get_node("Players").get_children():
		player.can_move = false;
	get_node("AnimationPlayer").play("go");
	await get_tree().create_timer(4).timeout;
	get_node("NarratorComponent").narrator_secret_intro();
	await get_node("NarratorComponent").finished;
	for player in get_tree().current_scene.get_node("Players").get_children():
		player.can_move = true;
		player.secret_active = true;
	get_node("AnimationPlayer2").play("see_lobby");
	await get_tree().create_timer(6).timeout;
	wave_active = false;
	pause = false;


func _physics_process(delta: float) -> void:
	get_node("WaveNum").text = "WAVE " + str(wave);
	for player in get_tree().current_scene.get_node("Players").get_children():
		if player.is_dead and player.is_local:
			get_tree().quit();
	
	if not wave_active:
		wave_active = true;
		pause = true;
		await get_tree().create_timer(5).timeout;
		wave += 1;
		if wave % 15 == 0:
			spawn_humpher();
		else:
			spawn_amt = floor(wave / 3) + 1;
			spawn_base_enemies();
	
	if get_node("SecretEnemies").get_children().size() == 0 and wave_active and not pause:
		wave_active = false;


func spawn_humpher() -> void:
	var enemy = load("res://scenes/components/minigames/secret/secret_enemy.tscn").instantiate();
	enemy.type = 3;
	enemy.global_position = humpher_spawn;
	get_node("SecretEnemies").add_child(enemy);
	pause = false;


func spawn_base_enemies() -> void:
	var i = 0;
	while i < spawn_amt:
		var type = enemy_num % 3;
		
		var enemy = load("res://scenes/components/minigames/secret/secret_enemy.tscn").instantiate();
		enemy.type = type;
		print(enemy.type);
		
		if type == 0 or type == 1:
			enemy.global_position = base_spawns[enemy_num % 2];
		else:
			enemy.global_position = fly_spawns[enemy_num % 2];
		
		get_node("SecretEnemies").add_child(enemy);
		
		enemy_num += 1;
		i += 1;
		
		await get_tree().create_timer(1.5).timeout;
	
	pause = false;
