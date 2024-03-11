shader_type canvas_item;
render_mode blend_premul_alpha,unshaded;

uniform vec4 color:source_color;

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
	vec2 uv_ = customRotator(UV, vec2(0.5,0.5), angle);
	COLOR = texture(TEXTURE,uv_) * color;
	COLOR.a = 0.0;
}