extends Node

@onready var tiles: TileMapLayer = $InteractableTiles;
@onready var white_flash: TextureRect = $WhiteFlash;
var hue: float = 125.0;


func _ready() -> void:
	white_flash.visible = true;
	await get_tree().create_timer(0.5).timeout;
	var tween: Tween = get_tree().create_tween();
	tween.tween_property(white_flash, "modulate", Color("#FFFFFF", 1.0), 0.75);
	tween.tween_property(white_flash, "modulate", Color("#FFFFFF", 0.0), 3);


func _process(delta: float) -> void:
	hue += 0.5;
	tiles.modulate = Color.from_hsv((int(floor(hue)) % 360) / 360.0, 0.25, 1.0);
	tiles.rotation += 0.005;
