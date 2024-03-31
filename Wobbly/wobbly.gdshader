shader_type canvas_item;

//扭曲边缘适合做对话气泡

// 定义属性
uniform sampler2D disp_tex : hint_default_black;
uniform float speed : hint_range(0.0, 2.0);
uniform float intensity : hint_range(0.0, 0.1);


void fragment() {
    // 计算时间变量
    float t = TIME * speed;
    // 从扭曲纹理中获取偏移量
    float disp = texture(disp_tex, fract(  (UV + vec2(t, t))   )).r;
    // 应用偏移量到主纹理的UV坐标
    vec4 col = texture(TEXTURE, UV + disp * intensity);
    // 输出最终颜色
    COLOR = col;
}