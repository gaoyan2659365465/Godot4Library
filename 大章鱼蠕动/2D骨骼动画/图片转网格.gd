extends Node

# Thanks to Justo Delgado - a.k.a mrcdk (https://github.com/mrcdk) - for the function this one is based on.
# It can be found here https://github.com/godotengine/godot/issues/31323

# The sprite parameter must be a Sprite node.
func create_polygon_from_sprite(sprite):
	# Get the sprite's texture.
	var texture = sprite.texture
	# Get the sprite texture's size.
	var texture_size = sprite.texture.get_size()
	# Get the image from the sprite's texture.
	var image = texture.get_image()

	# Create a new bitmap.
	var bitmap = BitMap.new()
	# Create the bitmap from the image. We set the minimum alpha threshold.
	bitmap.create_from_image_alpha(image, 0.1) # 0.1 (default threshold).
	# Get the rect of the bitmap.
	var bitmap_rect = Rect2(Vector2(0, 0), bitmap.get_size())
	# Grow the bitmap if you need (we don't need it in this case).
#	bitmap.grow_mask(0, rect) # 2
	# Convert all the opaque parts of the bitmap into polygons.
	var polygons = bitmap.opaque_to_polygons(bitmap_rect, 4) # 2 (default epsilon).
	# Check if there are polygons.
	if polygons.size() > 0:
		# Loop through all the polygons.
		for i in range(polygons.size()):
			# Create a new 'Polygon2D'.
			var polygon = Polygon2D.new()
			# Set the polygon.
			polygon.polygon = polygons[i]
			# Set the texture.
			polygon.texture = texture

			# Check if the sprite is centered to get the proper position.
			if sprite.centered:
				polygon.position = sprite.position - (texture_size / 2)
			else:
				polygon.position = sprite.position

			# Take the sprite's scale into account and apply it to the position.
			polygon.scale = sprite.scale
			polygon.position *= polygon.scale

			polygon.name = "poly_sprite"

			return polygon
	else:
		return false
