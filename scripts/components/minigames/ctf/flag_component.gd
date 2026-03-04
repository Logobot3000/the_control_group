extends Area2D;
class_name FlagComponent;

var locked_player = null;
var barrier_active: bool = true;

func _on_body_entered(body) -> void:
	if body.get_parent().name == "Players":
		if body.is_experimental and !locked_player:
			player_lock(true, body, true);
			await get_tree().create_timer(5).timeout;
			if locked_player:
				toggle_barrier(false, true);
		elif !body.is_experimental and locked_player:
			if Main.player_steam_id == body.steam_id:
				if body.ctf_flag_hunter_enabled:
					get_tree().current_scene.get_node("CTF").score_point(2);
				else:
					get_tree().current_scene.get_node("CTF").score_point(1);
				player_lock(false, null, true);
				toggle_barrier(true, true);
				relocate_player(body);


func _physics_process(delta: float) -> void:
	if not locked_player == null:
		global_position = locked_player.global_position;
		global_position.y -= 16;
	else:
		global_position = Vector2(1000, 1000);


func _on_flag_submit_body_entered(body) -> void:
	if locked_player:
		if body.steam_id == locked_player.steam_id:
			var success: bool = false;
			if Main.player_steam_id == locked_player.steam_id:
				if locked_player.ctf_flag_master_enabled:
					get_tree().current_scene.get_node("CTF").score_point(3);
				else:
					get_tree().current_scene.get_node("CTF").score_point(1);
				player_lock(false, null, true);
				relocate_player(body);
				success = true;
			if success:
				toggle_barrier(true, true);


func relocate_player(player) -> void:
	var spots = [Vector2(280, -132), Vector2(-280, 156), Vector2(-280, -132), Vector2(280, 156)];
	var spot = spots[randi_range(0, 3)];
	player.global_position = Vector2(1000 + spot.x, 1000 + spot.y);


func player_lock(lock_toggle: bool, player, send: bool) -> void:
	if not lock_toggle:
		locked_player = null;
		if send:
			Network.send_p2p_packet(0, {
				"message": "player_lock",
				"toggle": false,
			});
	else:
		locked_player = player;
		if send:
			Network.send_p2p_packet(0, {
				"message": "player_lock",
				"toggle": true,
				"player_id": player.steam_id
			});


func toggle_barrier(toggle: bool, send: bool) -> void:
	if toggle:
		for barrier in get_tree().current_scene.get_node("CTF").get_node("ExperimentalBarriers").get_children():
			barrier.visible = true;
		barrier_active = true;
	else:
		for barrier in get_tree().current_scene.get_node("CTF").get_node("ExperimentalBarriers").get_children():
			barrier.visible = false;
		barrier_active = false;
	if send:
		Network.send_p2p_packet(0, {
			"message": "toggle_barrier",
			"toggle": toggle,
		});


func _on_experimental_barrier_body_entered(body: Node2D) -> void:
	if body.get_parent().name == "Players":
		if !body.is_experimental and barrier_active:
			relocate_player(body);
