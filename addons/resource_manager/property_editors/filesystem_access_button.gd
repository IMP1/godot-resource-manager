@tool
extends HBoxContainer
class_name FilesystemAccessButton

signal path_changed

@export var path: String
@export var file_mode: EditorFileDialog.FileMode = EditorFileDialog.FileMode.FILE_MODE_OPEN_FILE
@export var access: EditorFileDialog.Access = EditorFileDialog.Access.ACCESS_RESOURCES

var line_edit: LineEdit
var button: Button
var dialog: EditorFileDialog


func _enter_tree() -> void:
	line_edit = LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button = Button.new()
	button.icon = EditorInterface.get_editor_theme().get_icon("FolderBrowse", "EditorIcons")
	dialog = EditorFileDialog.new()
	dialog.file_mode = file_mode
	dialog.access = access
	dialog.min_size = Vector2(1024, 720) # TODO: How should this be determined?
	add_child(line_edit)
	add_child(button)
	add_child(dialog, false, Node.INTERNAL_MODE_BACK)


func _ready() -> void:
	button.pressed.connect(dialog.popup_centered)
	if file_mode == EditorFileDialog.FileMode.FILE_MODE_OPEN_FILE or file_mode == EditorFileDialog.FileMode.FILE_MODE_OPEN_ANY:
		dialog.file_selected.connect(func(value: String) -> void:
			path = value
			line_edit.text = path
			path_changed.emit())
	if file_mode == EditorFileDialog.FileMode.FILE_MODE_OPEN_DIR or file_mode == EditorFileDialog.FileMode.FILE_MODE_OPEN_ANY:
		dialog.dir_selected.connect(func(value: String) -> void:
			path = value
			line_edit.text = path
			path_changed.emit())
	line_edit.text_changed.connect(func(value: String) -> void:
		path = value
		path_changed.emit())
	line_edit.text = path
	dialog.hide()
