@tool
extends EditorPlugin

var dock: Control


func _enter_tree() -> void:
	dock = preload("res://addons/resource_manager/resource_editor.tscn").instantiate() as Control
	EditorInterface.get_editor_main_screen().add_child(dock)
	dock.hide()


func _exit_tree() -> void:
	EditorInterface.get_editor_main_screen().remove_child(dock)
	dock.free()


func _make_visible(visible):
	dock.visible = visible


func _get_plugin_name():
	return "ResourceManager"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("PackedDataContainer", "EditorIcons")


func _has_main_screen():
	return true
