@tool
extends EditorPlugin
class_name ResourceManagerPlugin

const SETTINGS_ONLY_INCLUDE_ALLOWED_DIRS := "addons/resource_manager/config/only_include_allowed_directories"
const SETTINGS_ALLOWED_DIRS := "addons/resource_manager/config/allowed_directories"
const SETTINGS_RECURSIVELY_SEARCH_ALLOWED_DIRS := "addons/resource_manager/config/include_allowed_directories_subfolders"
const SETTINGS_IGNORED_DIRS := "addons/resource_manager/config/ignored_directories"
const SETTINGS_ALLOWED_FILETYPES := "addons/resource_manager/config/allowed_filetypes"
const SETTINGS_IGNORED_FILES := "addons/resource_manager/config/ignored_files"
const SETTINGS_FLAG_FIELD_ABBREVIATION := "addons/resource_manager/display/flag_field_abbreviation"

enum FlagAbbreviations {
	NONE,
	INITIALS,
	BIT_POSITIONS,
}

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
	
	if not ProjectSettings.has_setting(SETTINGS_RECURSIVELY_SEARCH_ALLOWED_DIRS):
		ProjectSettings.set_setting(SETTINGS_RECURSIVELY_SEARCH_ALLOWED_DIRS, true)
	ProjectSettings.set_initial_value(SETTINGS_RECURSIVELY_SEARCH_ALLOWED_DIRS, true)
	
	if not ProjectSettings.has_setting(SETTINGS_ALLOWED_DIRS):
		ProjectSettings.set_setting(SETTINGS_ALLOWED_DIRS, [])
		ProjectSettings.add_property_info({
			"name": SETTINGS_ALLOWED_DIRS,
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_ARRAY_TYPE,
			"hint_string": "%d/%d:" % [TYPE_STRING, PROPERTY_HINT_DIR] # TODO: These should be dir paths
		})
	ProjectSettings.set_initial_value(SETTINGS_ALLOWED_DIRS, [])
	
	if not ProjectSettings.has_setting(SETTINGS_IGNORED_DIRS):
		ProjectSettings.set_setting(SETTINGS_IGNORED_DIRS, ["res://addons"])
		ProjectSettings.add_property_info({
			"name": SETTINGS_IGNORED_DIRS,
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_ARRAY_TYPE,
			"hint_string": "%d/%d:" % [TYPE_STRING, PROPERTY_HINT_DIR] # TODO: These should be dir paths
		})
	ProjectSettings.set_initial_value(SETTINGS_IGNORED_DIRS, ["res://addons"])
	
	if not ProjectSettings.has_setting(SETTINGS_ALLOWED_FILETYPES):
		ProjectSettings.set_setting(SETTINGS_ALLOWED_FILETYPES, ["tres", "res"])
		ProjectSettings.add_property_info({
			"name": SETTINGS_ALLOWED_FILETYPES,
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_ARRAY_TYPE,
			"hint_string": "%d:" % [TYPE_STRING]
		})
	ProjectSettings.set_initial_value(SETTINGS_ALLOWED_FILETYPES, ["tres", "res"])
	
	if not ProjectSettings.has_setting(SETTINGS_IGNORED_FILES):
		ProjectSettings.set_setting(SETTINGS_IGNORED_FILES, [])
		ProjectSettings.add_property_info({
			"name": SETTINGS_IGNORED_FILES,
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_ARRAY_TYPE,
			"hint_string": "%d/%d:" % [TYPE_STRING, PROPERTY_HINT_FILE_PATH]
		})
	ProjectSettings.set_initial_value(SETTINGS_IGNORED_FILES, [])
	
	if not ProjectSettings.has_setting(SETTINGS_FLAG_FIELD_ABBREVIATION):
		ProjectSettings.set_setting(SETTINGS_FLAG_FIELD_ABBREVIATION, FlagAbbreviations.NONE)
		ProjectSettings.add_property_info({
			"name": SETTINGS_FLAG_FIELD_ABBREVIATION,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(PackedStringArray(FlagAbbreviations.keys().map(func(key: String) -> String: return key.capitalize())))
		})
	ProjectSettings.set_initial_value(SETTINGS_FLAG_FIELD_ABBREVIATION, FlagAbbreviations.NONE)


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
