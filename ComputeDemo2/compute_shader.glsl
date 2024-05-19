#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

//int a = 0;
//所有工作项各自不同的全局变量

//ivec2 gid = ivec2(gl_GlobalInvocationID.xy);
//每个工作项的唯一ID
//vec2表示两个浮点数的向量
//ivec2表示两个整数的向量

//#define A 0
//编辑阶段A替换成0，运行效率较高

//layout(set = 0, binding = 0)
// set和binding必须同时存在
// set是rd.uniform_set_create的参数
// binding是RDUniform的一个属性

//layout(set = 0, binding = 0) int a;
// 绑定数据，需要uniform或buffer参数
//layout(set = 0, binding = 0) uniform int a;
// uniform或buffer参数需要结构体而不是单独的变量

//layout(set = 0, binding = 0) uniform MyData{
//	int a;
//}
//mydata;

// int b = MyData.a;
// 结构体需要实例名称才能访问
// int b = mydata.a;

//layout(set = 0, binding = 0) buffer MyData{
//	int a;
//}
//mydata;
// uniform或buffer的区别
// uniform只能读不能写，适合低频访问的数据或静态数据
// buffer可以读写，适合高频访问的数据

//layout(rgba32f, set = 0, binding = 0) buffer readonly image2D input_image;
//layout(rgba32f, set = 1, binding = 0) uniform writeonly image2D output_image;
//layout(set = 0, binding = 0) uniform sampler2D base_image;
// uniform可以定义图像、采样器、缓冲区
// buffer只能定义缓冲区

//layout(rgba32f, set = 0, binding = 0) uniform readonly image2D input_image;
//layout(rgba32f, set = 1, binding = 0) uniform writeonly image3D output_image;
// readonly对image2D只读或image3D
// writeonly对image2D只写或image3D
// 这两者不能用于定义其他东西，如采样器sampler2D
// rgba32f rgba8 r8 等等只能对image2D或image3D使用

//layout(std430, set = 0, binding = 0) uniform MyData{
//	int a;
//}mydata;
// std430只能用来修饰buffer,uniform可以使用std430或std140
// std430表述数据内存比较紧凑，std140表述数据内存不紧凑，兼容性更好
// std430或std140只能用在结构体上，缓冲区

//layout(set = 0, binding = 0, std430) restrict buffer MyDataBuffer {
//    float data[];
//}my_data_buffer;
// layout内的顺序无所谓
// restrict 防止重复绑定，可写可不写

//layout(push_constant) uniform MyData{
//	int a;
//}mydata;
// 高效地向着色器传递少量、频繁更新的数据
// 只能使用uniform不能用buffer
// 并且不需要使用std430或std140
// 不需要set和binding
// 代码中使用rd.compute_list_set_push_constant进行传递

//shared uint selected_pixels[64];
// 每个工作组之内共享读写，但是需要配合同步函数
// 同步所有线程，确保所有线程都初始化完成
// gl_LocalInvocationID 和 gl_GlobalInvocationID
// selected_pixels[gl_LocalInvocationID.x] = 0;
// barrier();

// 采样器sampler2D和图像image2D的区别

layout(set = 0, binding = 0) uniform sampler2D base_image;
layout(rgba8, set = 1, binding = 0) uniform restrict writeonly image2D output_image;


void main() {
	ivec2 st = ivec2(gl_GlobalInvocationID.xy);
	vec2 uv = vec2(st) / imageSize(output_image);
	vec4 mask_color = texture(base_image, uv*0.5);
	imageStore(output_image, st, mask_color);
}


