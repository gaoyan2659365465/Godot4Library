extends Node2D


var step_per_frame:int = 10
var max_iteration:int = 50
var line_art_mode:bool = false
var elapsed_passes:int = 0

var OpNone = 0
var OpClick = 1
var OpClear = 2
var OpPrepassLine = 4
var OpPrepassColor = 8
var OpSeedingMaskBuffer = 16
var OpFloodingMaskBuffer = 32



var CurrentTexSet = 0
var PrevTexSet = 1
var SamplerTexSet = 2
var MaskTexSet = 3
var DisplayTexSet = 4
var TextureSize = Vector2i(512,512)

var rd:RenderingDevice
var shader_rd:RID
var pipeline_rd:RID

var current_tex:RID
var previous_tex:RID
var display_tex:RID
var mask_tex:RID
var tex_resource:RID
var tex_sampler:RID

var current_tex_uniform_set:RID
var previous_tex_uniform_set:RID
var display_tex_uniform_set:RID
var mask_tex_uniform_set:RID
var tex_sampler_uniform_set:RID

var main_tex_rd:Texture2DRD
var back_buffer_rd:Texture2DRD
var mask_buffer_rd:Texture2DRD
var display_buffer_rd:Texture2DRD

var shader_parameter:PushConstants

class PushConstants:
	var TexSize:Vector2i = Vector2i.ONE
	var QueryPosition:Vector2i = Vector2i.ZERO
	var OperationFlag:int = 0
	var DisplayMode:int  = 0
	var PassCounter:int = 0
	var Threshold:float = 0.25
	var ColorTarget:Color = Color.GREEN

func createTextureUniformSet(texture_rid:RID,shader_set:int):
	var uniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(texture_rid)
	return rd.uniform_set_create([uniform],shader_rd,shader_set)


func updateCompute():
	#var push_constant_bytes:PackedByteArray = var_to_bytes(shader_parameter)

	var push_constant_bytes:PackedByteArray = PackedByteArray()
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
	push_constant_bytes.append_array(abytes)
	push_constant_bytes.append_array(bbytes)

	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline_rd)
	rd.compute_list_set_push_constant(compute_list, push_constant_bytes, push_constant_bytes.size())
	rd.compute_list_bind_uniform_set(compute_list, current_tex_uniform_set, CurrentTexSet)
	rd.compute_list_bind_uniform_set(compute_list, previous_tex_uniform_set, PrevTexSet)
	rd.compute_list_bind_uniform_set(compute_list, tex_sampler_uniform_set, SamplerTexSet)
	rd.compute_list_bind_uniform_set(compute_list, mask_tex_uniform_set, MaskTexSet)
	rd.compute_list_bind_uniform_set(compute_list, display_tex_uniform_set, DisplayTexSet)
	rd.compute_list_dispatch(compute_list, int(TextureSize.x / 8), int(TextureSize.y / 8), 1)
	rd.compute_list_end()
	
	var swap_tex = previous_tex
	var swap_uniform = previous_tex_uniform_set
	previous_tex = current_tex
	previous_tex_uniform_set = current_tex_uniform_set
	current_tex = swap_tex
	current_tex_uniform_set = swap_uniform

func refreshTexture(tex:Texture2D):
	if tex_resource.is_valid():
		rd.free_rid(tex_resource)
	if tex_sampler_uniform_set.is_valid():
		rd.free_rid(tex_sampler_uniform_set)
	var tex_view = RDTextureView.new()
	var tex_rid = RenderingServer.texture_get_rd_texture(tex.get_rid())
	tex_resource = rd.texture_create_shared(tex_view,tex_rid)
	var tex_sampler_uniform = RDUniform.new()
	tex_sampler_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	tex_sampler_uniform.add_id(tex_sampler)
	tex_sampler_uniform.add_id(tex_resource)
	tex_sampler_uniform_set = rd.uniform_set_create([tex_sampler_uniform],shader_rd,SamplerTexSet)

func floodingPrepass():
	if line_art_mode:
		shader_parameter.OperationFlag = OpPrepassLine
	else:
		shader_parameter.OperationFlag = OpPrepassColor
	updateCompute()
	shader_parameter.OperationFlag = OpSeedingMaskBuffer
	updateCompute()
	elapsed_passes = 0

func floodAndDraw():
	if elapsed_passes < max_iteration:
		for i in range(step_per_frame):
			shader_parameter.OperationFlag = OpFloodingMaskBuffer
			shader_parameter.PassCounter = elapsed_passes
			updateCompute()
			elapsed_passes += 1
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			shader_parameter.OperationFlag = OpClick
			shader_parameter.QueryPosition = get_local_mouse_position()
		else:
			shader_parameter.OperationFlag = OpNone
		updateCompute()

func _ready() -> void:
	# 编译glsl
	#var rd := RenderingServer.create_local_rendering_device()
	rd = RenderingServer.get_rendering_device()
	var shader_file := load("res://ComputeDemo/compute_example.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader_rd = rd.shader_create_from_spirv(shader_spirv)
	# 创建计算管线
	pipeline_rd = rd.compute_pipeline_create(shader_rd)
	
	# 创建采样器
	var sampler_state = RDSamplerState.new()
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	tex_sampler = rd.sampler_create(sampler_state)
	
	# 创建TextureView
	var tex_view = RDTextureView.new()
	var tex_rid = RenderingServer.texture_get_rd_texture($Icon.texture.get_rid())
	tex_resource = rd.texture_create_shared(tex_view,tex_rid)
	# 绑定缓冲区
	var tex_sampler_uniform := RDUniform.new()
	tex_sampler_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	tex_sampler_uniform.add_id(tex_sampler)
	tex_sampler_uniform.add_id(tex_resource)
	tex_sampler_uniform_set = rd.uniform_set_create([tex_sampler_uniform], shader_rd, SamplerTexSet)# base_image
	# 创建结构体
	shader_parameter = PushConstants.new()
	shader_parameter.TexSize = TextureSize
	
	# 创建缓冲区
	var tf_buffer := RDTextureFormat.new()
	tf_buffer.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	tf_buffer.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf_buffer.width = TextureSize.x
	tf_buffer.height = TextureSize.y
	tf_buffer.depth = 1
	tf_buffer.array_layers = 1
	tf_buffer.mipmaps = 1
	tf_buffer.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |\
					 RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |\
					 RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |\
					 RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |\
					 RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT
	
	var tf_display := RDTextureFormat.new()
	tf_display.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	tf_display.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf_display.width = TextureSize.x
	tf_display.height = TextureSize.y
	tf_display.depth = 1
	tf_display.array_layers = 1
	tf_display.mipmaps = 1
	tf_display.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |\
					 RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |\
					 RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |\
					 RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |\
					 RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT
	
	var tf_mask := RDTextureFormat.new()
	tf_mask.format = RenderingDevice.DATA_FORMAT_R8_UNORM
	tf_mask.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf_mask.width = TextureSize.x
	tf_mask.height = TextureSize.y
	tf_mask.depth = 1
	tf_mask.array_layers = 1
	tf_mask.mipmaps = 1
	tf_mask.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |\
					 RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |\
					 RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |\
					 RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |\
					 RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT
	
	
	# 创建各个图像并绑定
	current_tex = rd.texture_create(tf_buffer,RDTextureView.new(),[])
	previous_tex = rd.texture_create(tf_buffer,RDTextureView.new(),[])
	display_tex = rd.texture_create(tf_display,RDTextureView.new(),[])
	mask_tex = rd.texture_create(tf_mask,RDTextureView.new(),[])
	current_tex_uniform_set = createTextureUniformSet(current_tex,CurrentTexSet)# output_image
	previous_tex_uniform_set = createTextureUniformSet(previous_tex,PrevTexSet)# prev_image
	display_tex_uniform_set = createTextureUniformSet(display_tex,DisplayTexSet)# display_image
	mask_tex_uniform_set = createTextureUniformSet(mask_tex,MaskTexSet)# mask_image
	main_tex_rd = Texture2DRD.new()
	main_tex_rd.texture_rd_rid = current_tex #当前帧
	back_buffer_rd = Texture2DRD.new()
	back_buffer_rd.texture_rd_rid = previous_tex #前一帧
	mask_buffer_rd = Texture2DRD.new()
	mask_buffer_rd.texture_rd_rid = mask_tex
	display_buffer_rd = Texture2DRD.new()
	display_buffer_rd.texture_rd_rid = display_tex
	
	$Sprite2D.texture = display_buffer_rd
	$Sprite2D2.texture = mask_buffer_rd
	$Sprite2D3.texture = back_buffer_rd #前一帧
	$Sprite2D4.texture = main_tex_rd #当前帧
	floodingPrepass()

func _process(delta: float) -> void:
	floodAndDraw()


func _on_check_box_toggled(toggled_on: bool) -> void:
	line_art_mode = toggled_on
	floodingPrepass()


func _on_h_slider_value_changed(value: float) -> void:
	step_per_frame = value
	floodingPrepass()


func _on_h_slider_2_value_changed(value: float) -> void:
	max_iteration = value
	floodingPrepass()


func _on_h_slider_3_value_changed(value: float) -> void:
	shader_parameter.Threshold = value
	floodingPrepass()


func _on_color_picker_button_color_changed(color: Color) -> void:
	shader_parameter.ColorTarget = color
	floodingPrepass()


func _on_h_slider_4_value_changed(value: float) -> void:
	shader_parameter.DisplayMode = value
	floodingPrepass()

