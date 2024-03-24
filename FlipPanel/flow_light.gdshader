shader_type canvas_item;

// 流光效果

uniform float progress:hint_range(-1.0, 2.0) = 0.0;
uniform float angle = 2.206;
uniform float n = 0.163;

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
	float color_a = step(customRotator(UV,vec2(0.5),angle).r ,progress);
	float color_b = step(customRotator(UV,vec2(0.5),angle).r ,progress - n);

	float color_c = step(customRotator(UV,vec2(0.5),angle).r ,progress - 3.0*n);
	float color_d = step(customRotator(UV,vec2(0.5),angle).r ,progress - 4.0*n);

	COLOR = COLOR + (color_a - color_b)*0.2 + (color_c - color_d)*0.2;
}