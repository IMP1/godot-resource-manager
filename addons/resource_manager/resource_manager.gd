@tool
extends EditorPlugin
class_name ResourceManagerPlugin

const SETTINGS_ONLY_INCLUDE_ALLOWED_DIRS := "addons/resource_manager/config/only_include_allowed_directories"
const SETTINGS_ALLOWED_DIRS := "addons/resource_manager/config/allowed_directories"
const SETTINGS_IGNORED_DIRS := "addons/resource_manager/config/ignored_directories"

var dock: Control


func _enter_tree() -> void:
	_setup_settings()
	dock = preload("res://addons/resource_manager/resource_editor.tscn").instantiate() as Control
	EditorInterface.get_editor_main_screen().add_child(dock)
	dock.hide()


func _setup_settings() -> void:
	if not ProjectSettings.has_setting(SETTINGS_ONLY_INCLUDE_ALLOWED_DIRS):
		ProjectSettings.set_setting(SETTINGS_ONLY_INCLUDE_ALLOWED_DIRS, false)
	ProjectSettings.set_initial_value(SETTINGS_ONLY_INCLUDE_ALLOWED_DIRS, false)
	if not ProjectSettings.has_setting(SETTINGS_ALLOWED_DIRS):
		ProjectSettings.set_setting(SETTINGS_ALLOWED_DIRS, [])
	ProjectSettings.set_initial_value(SETTINGS_ALLOWED_DIRS, [])
	if not ProjectSettings.has_setting(SETTINGS_IGNORED_DIRS):
		ProjectSettings.set_setting(SETTINGS_IGNORED_DIRS, [])
	ProjectSettings.set_initial_value(SETTINGS_IGNORED_DIRS, [])


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
