extends TextureButton


@export var count: int = 0;
@export var lobby_name: String = "Lobby";


func _ready() -> void:
	match count:
		1:
			texture_normal.region.position.x = 5 + (228 * 2);
			texture_pressed.region.position.x = 5 + (228 * 2);
			texture_hover.region.position.x = 5 + (228 * 3);
			get_node("Count").text = "1/4";
		2:
			texture_normal.region.position.x = 5 + (228 * 4);
			texture_pressed.region.position.x = 5 + (228 * 4);
			texture_hover.region.position.x = 5 + (228 * 5);
			get_node("Count").text = "2/4";
		2:
			texture_normal.region.position.x = 5 + (228 * 6);
			texture_pressed.region.position.x = 5 + (228 * 6);
			texture_hover.region.position.x = 5 + (228 * 7);
			get_node("Count").text = "3/4";
		_:
			texture_normal.region.position.x = 5;
			texture_pressed.region.position.x = 5;
			texture_hover.region.position.x = 5 + 228;
			get_node("Count").text = "?/4";
	get_node("Name").text = lobby_name.to_upper();
	print(texture_normal.region.size.x)
