class_name ComputeDemo2 extends Node2D


var rd:RenderingDevice
var shader_rd:RID
var pipeline_rd:RID



var shader_parameter:PushConstants

class PushConstants:
	var TexSize:Vector2i = Vector2i.ONE
	var QueryPosition:Vector2i = Vector2i.ZERO
	var OperationFlag:int = 0
	var DisplayMode:int  = 0
	var PassCounter:int = 0
	var Threshold:float = 0.25
	var ColorTarget:Color = Color.GREEN

var shaderSCRIPT = """
#version 450
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(set = 0, binding = 0) uniform sampler2D base_image;
layout(rgba8, set = 1, binding = 0) uniform restrict writeonly image2D output_image;

layout(push_constant) uniform restrict MyDataBuffer {
	ivec2 texture_size;
	ivec2 query_pos;
	int op_flag;
	int display_mode;
	int pass_counter;
	float threshold;
	vec4 color_target;
}
my_data_buffer;
void main() {
	ivec2 st = ivec2(gl_GlobalInvocationID.xy);
	vec2 uv = vec2(st) / my_data_buffer.texture_size;
	vec4 mask_color = texture(base_image, uv*0.5);
	imageStore(output_image, st, mask_color);
	
}
"""

func _ready() -> void:
	# 创建渲染设备
	rd = RenderingServer.get_rendering_device()
	#var shader_file := load("res://ComputeDemo2/compute_shader.glsl")
	var s = RDShaderSource.new()
	s.source_compute = shaderSCRIPT
	var shader_spirv = rd.shader_compile_spirv_from_source(s,false)
	#var shader_byte = rd.shader_compile_binary_from_spirv(shader_spirv)
	
	#var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	# 创建着色器实例
	#shader_rd = rd.shader_create_from_bytecode(shader_byte)
	shader_rd = rd.shader_create_from_spirv(shader_spirv)
	# 创建计算管线
	pipeline_rd = rd.compute_pipeline_create(shader_rd)
	

	# 创建采样器
	var sampler_state = RDSamplerState.new()
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	var tex_sampler = rd.sampler_create(sampler_state)
	
	var tex_rid = RenderingServer.texture_get_rd_texture($Icon.texture.get_rid())
	# 绑定缓冲区
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform.add_id(tex_sampler)
	uniform.add_id(tex_rid)
	#---------------------------------------------------------------------
	
	# 创建贴图Format
	var tex_format := RDTextureFormat.new()
	tex_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	tex_format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tex_format.width = 128
	tex_format.height = 128
	tex_format.depth = 1
	tex_format.array_layers = 1
	tex_format.mipmaps = 1
	tex_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |\
					 RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |\
					 RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |\
					 RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |\
					 RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT
	# 创建贴图RID
	var tex_rd_rid = rd.texture_create(tex_format,RDTextureView.new(),[])
	# 创建uniform
	var uniform_1 = RDUniform.new()
	uniform_1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform_1.binding = 0
	uniform_1.add_id(tex_rd_rid)
	# 创建贴图
	var tex_rd = Texture2DRD.new()
	tex_rd.texture_rd_rid = tex_rd_rid
	$Icon2.texture = tex_rd
	
	#---------------------------------------------------------------------
	# 创建结构体
	shader_parameter = PushConstants.new()
	shader_parameter.TexSize = Vector2(128,128)
	
	var input_bytes:PackedByteArray = PackedByteArray()
	var a:PackedInt32Array = PackedInt32Array()
	a.push_back(shader_parameter.TexSize.x)
	a.push_back(shader_parameter.TexSize.y)
	a.push_back(shader_parameter.QueryPosition.x)
	a.push_back(shader_parameter.QueryPosition.y)
	a.push_back(shader_parameter.OperationFlag)
	a.push_back(shader_parameter.DisplayMode)
	a.push_back(shader_parameter.PassCounter)
	var abytes = a.to_byte_array()
	var b:PackedFloat32Array = PackedFloat32Array()
	b.push_back(shader_parameter.Threshold)
	b.push_back(shader_parameter.ColorTarget.r)
	b.push_back(shader_parameter.ColorTarget.g)
	b.push_back(shader_parameter.ColorTarget.b)
	b.push_back(shader_parameter.ColorTarget.a)
	var bbytes = b.to_byte_array()
	input_bytes.append_array(abytes)
	input_bytes.append_array(bbytes)
	
	# 创建uniform_set
	var uniform_set = rd.uniform_set_create([uniform],shader_rd,0)
	var uniform_set_1 = rd.uniform_set_create([uniform_1],shader_rd,1)
	#---------------------------------------------------------------------
	# 向GPU发射数据
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline_rd)
	# 绑定uniform_set
	rd.compute_list_set_push_constant(compute_list,input_bytes,input_bytes.size())
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set_1, 1)
	rd.compute_list_dispatch(compute_list, 128/8, 128/8, 1)
	rd.compute_list_end()
