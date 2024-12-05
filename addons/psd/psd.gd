@tool
extends EditorPlugin

var image_plugin : PSDImportPlugin

# https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/#50577409_19840

func _enter_tree():
	image_plugin = PSDImportPlugin.new()
	add_import_plugin(image_plugin)

func _exit_tree():
	remove_import_plugin(image_plugin)
	image_plugin = null

class PSDImportPlugin extends EditorImportPlugin:
	func _get_importer_name():
		return "my.psd.plugin"
		
	func _get_visible_name():
		return "PSD"

	func _get_recognized_extensions():
		return ["psd"]

	func _get_save_extension():
		return "res"

	func _get_resource_type():
		return "PortableCompressedTexture2D"

	func _get_preset_count():
		return 1

	func _get_preset_name(preset_index):
		return "Default"

	func _get_priority():
		return 1
		
	func _get_import_order():
		return 0
	
	func _get_option_visibility(path: String, option_name: StringName, options: Dictionary):
		return true
	
	func _get_import_options(path, preset_index):
		return [{"name": "my_option", "default_value": false}]
	
	func read_psd_file(path):
		var _image# 准备导出的图像
		
		var file_path = path  # 替换为你的 PSD 文件路径
		var psd_file = FileAccess.open(file_path, FileAccess.READ)
		if psd_file:
			# 读取PSD文件的签名和版本信息
			var signature = psd_file.get_buffer(4)  # 读取4字节，检查签名是否为 "8BPS"
			#print("Signature: ", signature.get_string_from_utf8())  # "8BPS" 是PSD文件的标志
			
			# 读取版本号
			var version = psd_file.get_buffer(2)  # 获取版本号
			version.reverse()
			#print("version: ", version.decode_u16(0))
			
			# 长度:6 Reserved：必须为零。
			var reserved = psd_file.get_buffer(6)
			#print("reserved: ",reserved)
			
			# 长度:2 图像中的通道数，包括任何 Alpha 通道。支持的范围为 1 到 56。
			var 通道数 = psd_file.get_buffer(2)
			通道数.reverse()
			通道数 = 通道数.decode_u16(0)
			#print("通道数: ",通道数)
			
			# 长度:4 图像的高度（以像素为单位）
			var 高度 = psd_file.get_buffer(4)
			高度.reverse()
			高度 = 高度.decode_u32(0)
			#print("高度: ",高度)
			
			# 长度:4 图像的宽度（以像素为单位）
			var 宽度 = psd_file.get_buffer(4)
			宽度.reverse()
			宽度 = 宽度.decode_u32(0)
			#print("宽度: ",宽度)
			
			# 长度:2 Depth：每个通道的位数。支持的值为 1、8、16 和 32。
			var 通道位数 = psd_file.get_buffer(2)
			通道位数.reverse()
			#print("通道位数: ",通道位数.decode_u16(0))
			
			# 长度:2 文件的颜色模式。
			# 支持的值为：Bitmap = 0;灰度 = 1;索引 = 2;RGB = 3;CMYK = 4;多通道 = 7;双色调 = 8;实验室 = 9
			var 颜色模式 = psd_file.get_buffer(2)
			颜色模式.reverse()
			#print("颜色模式: ",颜色模式.decode_u16(0))
			
			# Color Mode Data 部分
			# 只有索引颜色和双色调具有颜色模式数据。对于所有其他模式，此部分只是 4 字节长度的字段，该字段设置为零。
			var 颜色模式数据 = psd_file.get_buffer(4)
			颜色模式数据.reverse()
			#print("颜色模式数据: ",颜色模式数据.decode_u32(0))
			
			
			# Image Resources 部分
			# 长度:4 图像资源部分的长度。长度可能为零。
			var 图像资源长度 = psd_file.get_buffer(4)
			图像资源长度.reverse()
			图像资源长度 = 图像资源长度.decode_u32(0)
			#print("图像资源长度: ",图像资源长度)
			# 跳过
			psd_file.get_buffer(图像资源长度)
			
			# 图层和蒙版信息部分
			# 长度:4 图层和蒙版信息部分的长度。
			var 图层长度 = psd_file.get_buffer(4)
			图层长度.reverse()
			图层长度 = 图层长度.decode_u32(0)
			#print("图层和蒙版信息部分的长度: ",图层长度)
			# 跳过
			psd_file.get_buffer(图层长度)
			
			# 图像数据部分
			# 首先是所有红色数据，然后是所有绿色数据
			# 长度:2 压缩方法：0 = 原始图像数据 1 = RLE 压缩图像数据 2 = 无预测的 ZIP 3 = 带预测的 ZIP
			var 压缩方法 = psd_file.get_buffer(2)
			压缩方法.reverse()
			压缩方法 = 压缩方法.decode_u16(0)
			#print("压缩方法: ",压缩方法)
			
			#Image
			var len = psd_file.get_length()
			#print("文件尺寸: ",len)
			var pos = psd_file.get_position()
			#print("当前位置: ",pos)
			var 图像数据 = psd_file.get_buffer(len-pos)
			#图像数据.reverse()
			
			if 压缩方法 == 0:
				var _data:PackedByteArray = []
				var index = 0
				while index < 宽度*高度:
					for i in range(4):
						var _d = 图像数据.decode_u8(index+宽度*高度*i)
						_data.append(_d)
					index += 1
				#print(_data)
				_image = Image.create_from_data(宽度,高度,false,Image.FORMAT_RGBA8,_data)
			elif 压缩方法 == 1:
				图像数据 = 图像数据.slice(通道数*2*高度)
				var 解码数据:PackedByteArray = []
				var index = 0
				while index < 图像数据.size():
					var _d = 图像数据.decode_u8(index)
					if _d >= 0x80:# 该行有重复像素
						index += 1
						for i in range(256-_d+1):
							解码数据.append(图像数据.decode_u8(index))
					else:# 该行没有重复，按字节填充像素
						for i in range(_d+1):
							index += 1
							解码数据.append(图像数据.decode_u8(index))
					index += 1
				var _data:PackedByteArray = []
				index = 0
				while index < 宽度*高度:
					for i in range(通道数):
						var _d = 解码数据.decode_u8(index+宽度*高度*i)
						_data.append(_d)
					index += 1
				
				if 通道数 == 3:
					_image = Image.create_from_data(宽度,高度,false,Image.FORMAT_RGB8,_data)
				elif 通道数 == 4:
					_image = Image.create_from_data(宽度,高度,false,Image.FORMAT_RGBA8,_data)
			psd_file.close()
		return _image

	func _import(source_file, save_path, options, platform_variants, gen_files):
		var filename = save_path + "." + _get_save_extension()
		var psd_res = PortableCompressedTexture2D.new()
		var img_data = self.read_psd_file(source_file)
		img_data.generate_mipmaps()
		psd_res.create_from_image(img_data,PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
		var err_0 = ResourceSaver.save(psd_res, filename)
		return err_0
