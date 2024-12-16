@tool
extends Path2D

var percentRange : float = 0.1;
var textChars : PackedStringArray;


@export var text = "":
	set(v):
		text = v;
		self._updateNode();

@export var 字体尺寸 = 16:
	set(v):
		字体尺寸 = v;
		self._updateNode();

@export var 字体颜色:Color:
	set(v):
		字体颜色 = v
		self._updateNode();

@export var font:Font = ThemeDB.fallback_font:
	set(v):
		font = v;
		self._updateNode();

@export_range(0.0,1.0) var pxSpacing:float = 0.1:
	set(v):
		pxSpacing = v;
		self._updateNode();

@export_range(0.0,1.0) var offset:float = 0.0:
	set(v):
		offset = v;
		self._updateNode();


func _updateNode():
	self._decomposeString();
	self.queue_redraw()


func _decomposeString():
	self.textChars = PackedStringArray([]);
	var chars : Array = [];
	for i in range(text.length()):
		self.textChars.push_back(text[i]);

func _draw():
	self._drawString();


func _drawString():
	var cPosition = Vector2.ZERO;
	
	cPosition.x += self.offset
	self.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE);

	for i in textChars.size():
		var percentBox = cPosition.x;
		var xOnLine = self.curve.sample_baked(percentBox * self.curve.get_baked_length());

		var tangPoints : Array = [];
		tangPoints.append(self.curve.sample_baked((percentBox - self.percentRange) * self.curve.get_baked_length()));
		tangPoints.append(self.curve.sample_baked((percentBox + self.percentRange) * self.curve.get_baked_length()));
		
		var posNormal = (tangPoints[1] - tangPoints[0]).normalized()
		var angleTo = Vector2.RIGHT.angle_to(posNormal);
		self.draw_set_transform(xOnLine, angleTo, Vector2.ONE);
		self.draw_char(self.font, Vector2.ZERO, textChars[i],字体尺寸,字体颜色)
		cPosition.x += self.pxSpacing;
