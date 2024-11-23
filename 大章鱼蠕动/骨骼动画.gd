@tool
class_name SkeletonAnimTool extends Node


@export var skeleton_path: NodePath
@export var rotation_value: float = 0.0
@export var speed: float = 1.0
@export var offset: float = 0.0

var bone_count: int
var skeleton: Skeleton2D
var angle_offsets: float = 0.0

func _ready():
	skeleton = get_node(skeleton_path)
	bone_count = skeleton.get_bone_count()


func _process(delta):
	angle_offsets += delta * speed
	for i in bone_count:
		var bone = skeleton.get_bone(i)
		bone.rotation_degrees = sin(angle_offsets + offset*i) * rotation_value
