class_name SelectPanel extends Control


@onready var flip_panel: FlipPanel = $FlipPanel
@onready var flip_panel_2: FlipPanel = $FlipPanel2
@onready var flip_panel_3: FlipPanel = $FlipPanel3

signal select

func _on_flip_panel_flip() -> void:
	flip_panel_2.flipAnim()
	flip_panel_3.flipAnim()
	await get_tree().create_timer(3.0).timeout
	flip_panel_2.burningAnim()
	flip_panel_3.burningAnim()


func _on_flip_panel_2_flip() -> void:
	flip_panel.flipAnim()
	flip_panel_3.flipAnim()
	await get_tree().create_timer(3.0).timeout
	flip_panel.burningAnim()
	flip_panel_3.burningAnim()


func _on_flip_panel_3_flip() -> void:
	flip_panel_2.flipAnim()
	flip_panel.flipAnim()
	await get_tree().create_timer(3.0).timeout
	flip_panel.burningAnim()
	flip_panel_2.burningAnim()


func _on_flip_panel_burning() -> void:
	await get_tree().create_timer(1.0).timeout
	emit_signal("select")
	queue_free()


func _on_flip_panel_2_burning() -> void:
	await get_tree().create_timer(1.0).timeout
	emit_signal("select")
	queue_free()

func _on_flip_panel_3_burning() -> void:
	await get_tree().create_timer(1.0).timeout
	emit_signal("select")
	queue_free()
