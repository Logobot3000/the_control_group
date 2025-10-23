extends Node

@onready var tiles: TileMapLayer = $InteractableTiles;
var hue: int = 125;

func _process(delta: float) -> void:
	hue += 1;
	tiles.modulate = Color.from_hsv((hue % 360) / 360.0, 0.15, 1.0);
	tiles.rotation += 0.005;
