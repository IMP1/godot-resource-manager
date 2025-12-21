@tool
extends HBoxContainer
class_name FilesystemAccessButton

signal path_changed

@export var path: String
@export var file_mode: EditorFileDialog.FileMode = EditorFileDialog.FileMode.FILE_MODE_OPEN_FILE
@export var access: EditorFileDialog.Access = EditorFileDialog.Access.ACCESS_RESOURCES
## This doesn't affect the value of path, which is always a filepath, but it does add buttons for 
## toggling UID and path
@export var store_uid: bool = false 

var line_edit: LineEdit
var button: Button
var dialog: EditorFileDialog
var _uid_toggle: Button
var _path_toggle: Button
var show_uid: bool = false


func _enter_tree() -> void:
	line_edit = LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(line_edit)
	
	if store_uid:
		_uid_toggle = Button.new()
		_uid_toggle.icon = EditorInterface.get_editor_theme().get_icon("UID", "EditorIcons")
		_uid_toggle.tooltip_text = "Toggles displaying between path and UID.\nThe UID is the actual value of this property."
		_uid_toggle.visible = false
		add_child(_uid_toggle)
		_path_toggle = Button.new()
		_path_toggle.icon = EditorInterface.get_editor_theme().get_icon("NodePath", "EditorIcons")
		_path_toggle.tooltip_text = "Toggles displaying between path and UID.\nThe UID is the actual value of this property."
		add_child(_path_toggle)
		_uid_toggle.pressed.connect(func() -> void:
			_path_toggle.visible = true
			_uid_toggle.visible = false
			show_uid = false
			_path_toggle.grab_focus()
			line_edit.text = ResourceUID.ensure_path(path))
		_path_toggle.pressed.connect(func() -> void:
			if ResourceUID.path_to_uid(path) == path:
				return
			_path_toggle.visible = false
			_uid_toggle.visible = true
			show_uid = true
			_uid_toggle.grab_focus()
			line_edit.text = ResourceUID.path_to_uid(path))
	
	button = Button.new()
	button.icon = EditorInterface.get_editor_theme().get_icon("FolderBrowse", "EditorIcons")
	button.tooltip_text = "Select %s Path..." % ("Directory" if file_mode == EditorFileDialog.FileMode.FILE_MODE_OPEN_DIR else "File")
	add_child(button)
	
	dialog = EditorFileDialog.new()
	dialog.file_mode = file_mode
	dialog.access = access
	dialog.min_size = Vector2(1024, 720) # TODO: How should this be determined?
	add_child(dialog, false, Node.INTERNAL_MODE_BACK)


func _ready() -> void:
	add_theme_constant_override(&"separation", 2)
	button.pressed.connect(dialog.popup_centered)
	if file_mode == EditorFileDialog.FileMode.FILE_MODE_OPEN_FILE or file_mode == EditorFileDialog.FileMode.FILE_MODE_OPEN_ANY:
		dialog.file_selected.connect(func(value: String) -> void:
			path = value
			if store_uid:
				if ResourceUID.path_to_uid(path) == path:
					_path_toggle.visible = false
					_uid_toggle.visible = false
					line_edit.text = path
				elif show_uid:
					_uid_toggle.visible = true
					line_edit.text = ResourceUID.path_to_uid(path)
				else:
					_path_toggle.visible = true
					line_edit.text = path
			else:
				line_edit.text = path
			path_changed.emit())
	if file_mode == EditorFileDialog.FileMode.FILE_MODE_OPEN_DIR or file_mode == EditorFileDialog.FileMode.FILE_MODE_OPEN_ANY:
		dialog.dir_selected.connect(func(value: String) -> void:
			path = value
			path_changed.emit())
	line_edit.text_changed.connect(func(value: String) -> void:
		if show_uid:
			path = ResourceUID.ensure_path(value)
		else:
			path = value
		path_changed.emit())
	if store_uid:
		if ResourceUID.path_to_uid(path) == path:
			_path_toggle.visible = false
			_uid_toggle.visible = false
			line_edit.text = path
		elif show_uid:
			_uid_toggle.visible = true
			line_edit.text = ResourceUID.path_to_uid(path)
		else:
			_path_toggle.visible = true
			line_edit.text = path
	else:
		line_edit.text = path
	dialog.hide()
