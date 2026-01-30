shader_type canvas_item;
uniform vec4 origin : source_color;
uniform vec4 new_color : source_color;

void fragment() {
    vec4 current_pixel = texture(TEXTURE, UV);
    if (current_pixel == origin) {
        COLOR = new_color;
    }
	else if (current_pixel.a == 0.0) {
		COLOR = current_pixel;
	}
	else {
        COLOR = origin;
    }
}

void light() {
	
}
