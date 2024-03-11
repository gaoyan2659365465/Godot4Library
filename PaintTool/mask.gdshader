shader_type canvas_item;

uniform sampler2D mask_img;

void fragment() {
	vec4 tex_color = texture(TEXTURE,UV);
	vec4 mask_color = texture(mask_img,UV);
	//mask_color.a = mask_color.r;
	tex_color.a *= mask_color.r;
	COLOR = tex_color;
}
