extends Node2D;

func _ready() -> void:
	var i: int;
	for n in self.get_children():
		i += 1;
		n.scale = Vector2(0, 0);
		popup(n, i);


## Does the little ad popping up animation.
func popup(n: Node, index: int) -> void:
	if get_tree() != null:
		await get_tree().create_timer(randf_range(3.0 * index, 8.0 * index) + 3).timeout;
		var tween: Tween = get_tree().create_tween();
		tween.tween_property(n, "scale", Vector2(2, 2), 0.1);
