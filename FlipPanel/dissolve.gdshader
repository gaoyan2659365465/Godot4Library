shader_type canvas_item;

// 带旋转的溶解效果

uniform sampler2D noise;
uniform float progress:hint_range(0.0, 1.5) = 0.0;
uniform vec3 edge_color:source_color;
uniform float angle = 0.0;

vec2 customRotator(vec2 UVs,vec2 RotationCenter,float RotationAngle){
    //自定义旋转
    //RotationAngle为旋转输入0-1个值。值为1等于360度转弯。
    //RotationCenter输入一个数字作为旋转中心点。
    //UVs插入uv，世界坐标或其他值来旋转。
    vec2 _uv = UVs + RotationCenter * -1.0;
    float angle_cos = cos(RotationAngle);
    float angle_sin = sin(RotationAngle);
    vec2 _a = vec2(angle_cos, angle_sin * -1.0);
    vec2 _b = vec2(angle_sin, angle_cos);

    return vec2(dot(_uv, _a), dot(_uv, _b)) + RotationCenter;
}

void fragment(){
	COLOR = texture(TEXTURE,UV);
	vec4 noise_color = texture(noise,UV);

	float rotation_uvr = customRotator(UV,vec2(0.5),angle).r;

	float rotation_uvr_1 = smoothstep(rotation_uvr,rotation_uvr+0.5,progress);
	float noise_mask = step(0.0,noise_color.r-rotation_uvr_1);
	//COLOR = vec4(noise_mask,0.0,0.0,1.0);
	float rotation_uvr_2 = smoothstep(rotation_uvr,rotation_uvr+0.5,progress+0.02);
	vec3 noise_mask_edge = vec3(noise_mask - step(0.0,noise_color.r-rotation_uvr_2));

	COLOR.a = clamp(COLOR.a * noise_mask,0.0,1.0);
	COLOR.rgb = clamp(COLOR.rgb - noise_mask_edge,0.0,1.0) + noise_mask_edge * edge_color;
	//COLOR = vec4(noise_mask);
}