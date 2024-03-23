extends Node2D



func _ready() -> void:
	pass


func _on_button_pressed() -> void:
	var py_path = ProjectSettings.globalize_path("res://addons/pygde/bin/")
	var gde = GDExample.new()
	var a = gde.runPython(py_path,"你好Python")
	print(a)
