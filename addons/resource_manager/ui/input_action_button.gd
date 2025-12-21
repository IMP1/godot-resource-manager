@tool
extends HBoxContainer
class_name InputActionButton

signal action_changed

@export var action: String
@export var include_system: bool = true:
	set(value):
		include_system = value
		if is_node_ready():
			_refresh_list()

var line_edit: LineEdit
var button: Button
var dialog: PopupMenu
var _selected_index: int = -1


func _enter_tree() -> void:
	line_edit = LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button = Button.new()
	button.icon = EditorInterface.get_editor_theme().get_icon("InputEventAction", "EditorIcons")
	button.tooltip_text = "Select Input Action..."
	dialog = PopupMenu.new()
	add_child(line_edit)
	add_child(button)
	add_child(dialog, false, Node.INTERNAL_MODE_BACK)


func _refresh_list() -> void:
	_selected_index = -1
	dialog.clear()
	for i in InputMap.get_actions().size():
		var action_name := InputMap.get_actions()[i]
		if _is_system_input_action(action_name) and not include_system:
			continue
		dialog.add_radio_check_item(action_name, i)
		if action_name == action:
			_selected_index = i
			dialog.set_item_checked(i, true)


func _is_system_input_action(action: StringName) -> bool:
	return action.begins_with("ui") or action.begins_with("spatial_editor")


func _ready() -> void:
	button.pressed.connect(func() -> void:
		dialog.popup(Rect2i(button.global_position, Vector2(100, 100))))
	line_edit.text_changed.connect(func(value: String) -> void:
		if _selected_index > -1:
			dialog.set_item_checked(_selected_index, false)
		_selected_index = range(dialog.item_count).find_custom(func(i: int) -> bool:
			return dialog.get_item_text(i) == value)
		if _selected_index > -1:
			dialog.set_item_checked(_selected_index, true)
		action = value
		action_changed.emit())
	dialog.index_pressed.connect(func(index: int) -> void:
		if _selected_index > -1:
			dialog.set_item_checked(_selected_index, false)
		dialog.set_item_checked(index, true)
		_selected_index = index
		action = dialog.get_item_text(index)
		line_edit.text = action
		action_changed.emit())
	line_edit.text = action
	dialog.hide()
	_refresh_list()
