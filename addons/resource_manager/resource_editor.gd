@tool
extends PanelContainer

const ROW_MIN_HEIGHT := 24
const ROW_END_PADDING := 8

var _resource_types: Array[Dictionary]
var _resource_template: Script
var _loaded_resources: Array[Resource]
var _is_resource_just_created: bool = false
var _undo_redo: UndoRedo

@onready var _column_headers := %ColumnHeaders as BoxContainer
@onready var _item_actions := %ItemActions as BoxContainer
@onready var _data := %Data as BoxContainer
@onready var _content_scroll := %ScrollContents as ScrollContainer
@onready var _header_scroll := %ScrollHeader as ScrollContainer
@onready var _item_action_scroll := %ScrollActions as ScrollContainer
@onready var _resource_type_selector := %ResourceTypes as OptionButton
@onready var _reload := %Reload as Button
@onready var _save_btn := %Save as Button
@onready var _undo_btn := %Undo as Button
@onready var _redo_btn := %Redo as Button
@onready var _title := %Title as Label
@onready var _add_row := %AddRow as Button
@onready var _new_resource_popup := %NewResourcePopup as PopupPanel
@onready var _new_resource_folder := %NewResourceFolder as OptionButton
@onready var _new_resource_filename := %NewResourceFilename as LineEdit
@onready var _new_resource_cancel := %CancelNewResource as Button
@onready var _new_resource_confirm := %ConfirmNewResource as Button
@onready var _new_resource_filename_error := %NewResourceError as Label
@onready var _editor_container := %EditorContainer as Control
@onready var _save_indicator := %SavingIndicator as Control
@onready var _save_progress := %SavingProgress as ProgressBar


func _exit_tree() -> void:
	EditorInterface.get_inspector().property_edited.disconnect(_inspector_resource_edited)
	# TODO: Disconnect all the anonymous lambda connections to Resource.changed that each input 
	#       control node sets up.


func _inspector_resource_edited(property: String) -> void:
	if not _loaded_resources.has(EditorInterface.get_inspector().get_edited_object()):
		return
	(EditorInterface.get_inspector().get_edited_object() as Resource).changed.emit()


func _ready() -> void:
	# BUG: This works, but throws GDScript errors:
	#      modules/gdscript/gdscript_lambda_callable.cpp:126 - GDScript bug (please report): Invalid value of lambda capture at index 0.
	#      core/object/object.cpp:1310 - Error calling from signal 'changed' to callable: 'GDScript::<anonymous lambda>': Method not found.
	#      modules/gdscript/gdscript_lambda_callable.cpp:110 - Lambda capture at index 2 was freed. Passed "null" instead.
	#      res://addons/resource_manager/resource_editor.gd:197 - Cannot call method 'set_value_no_signal' on a null value.
	#
	#      On further investigation, it seems this might have something to do with the callables not 
	#      being disconnected when the plugin is unloaded, so maybe trying to call anonymous lambdas
	#      that no longer exist. Maybe trying to disconnect them when the plugin is unloaded will 
	#      work?
	EditorInterface.get_inspector().property_edited.connect(_inspector_resource_edited)
	_new_resource_popup.hide()
	_resource_types.clear()
	_new_resource_cancel.pressed.connect(_new_resource_popup.hide)
	_add_row.pressed.connect(_new_resource_popup.popup_centered)
	_add_row.pressed.connect(func():
		_validate_filename(_new_resource_filename.text))
	_new_resource_confirm.disabled = true
	_new_resource_filename.text_changed.connect(_validate_filename)
	_new_resource_confirm.pressed.connect(_add_new_resource)
	_resource_type_selector.clear()
	for resource_type in ProjectSettings.get_global_class_list():
		if _is_class_resource(resource_type):
			_resource_types.append(resource_type)
			_resource_type_selector.add_item(resource_type[&"class"])
	_title.text = _resource_type_selector.get_item_text(_resource_type_selector.selected).capitalize()
	_content_scroll.get_h_scroll_bar().share(_header_scroll.get_h_scroll_bar())
	_content_scroll.get_v_scroll_bar().share(_item_action_scroll.get_v_scroll_bar())
	_save_btn.icon = EditorInterface.get_editor_theme().get_icon("Save", "EditorIcons")
	_reload.icon = EditorInterface.get_editor_theme().get_icon("Reload", "EditorIcons")
	_undo_btn.icon = EditorInterface.get_editor_theme().get_icon("UndoRedo", "EditorIcons")
	_redo_btn.icon = EditorInterface.get_editor_theme().get_icon("Redo", "EditorIcons")
	_add_row.icon = EditorInterface.get_editor_theme().get_icon("Add", "EditorIcons")
	_save_btn.pressed.connect(_save_all)
	_undo_btn.pressed.connect(_undo)
	_redo_btn.pressed.connect(_redo)
	_reload.pressed.connect(func() -> void:
		if _resource_type_selector.selected == -1:
			return
		var script: Script = load(_resource_types[_resource_type_selector.selected][&"path"])
		reload(script))
	_undo_redo = UndoRedo.new() # TODO: Use this, SEE: https://docs.godotengine.org/en/stable/classes/class_undoredo.html
	# TODO: Maybe use the EditorUndoRedoManager?
	#       https://docs.godotengine.org/en/stable/classes/class_editorundoredomanager.html#class-editorundoredomanager


func _is_class_resource(class_type) -> bool:
	if class_type[&"base"] == &"Resource" and not class_type[&"is_abstract"]:
		return true
	# TODO: Ascend ancestors to see if it comes from a Resource type
	return false


func _validate_filename(filepath: String) -> void:
	_new_resource_filename_error.text = ""
	var dir := _new_resource_folder.get_item_text(_new_resource_folder.selected)
	var valid_filename := true
	if filepath.is_empty():
		_new_resource_filename_error.text = "Filename cannot be empty"
		valid_filename = false
	elif not filepath.is_valid_filename():
		_new_resource_filename_error.text = "Invalid filename"
		valid_filename = false
	elif FileAccess.file_exists(dir + "/" + filepath + ".tres"):
		_new_resource_filename_error.text = "File already exists"
		valid_filename = false
	_new_resource_confirm.disabled = not valid_filename


func _get_dirs(root:String="res://") -> Array[String]:
	if root == "res://" and ProjectSettings.get_setting(ResourceManagerPlugin.SETTINGS_ONLY_INCLUDE_ALLOWED_DIRS, false):
		return (ProjectSettings.get_setting(ResourceManagerPlugin.SETTINGS_ALLOWED_DIRS, []))
	else:
		var dirs: Array[String] = [root]
		for subdir in DirAccess.get_directories_at(root):
			if subdir.begins_with("."):
				continue
			var path := root + ("/" if not root.ends_with("/") else "") + subdir
			if ProjectSettings.get_setting(ResourceManagerPlugin.SETTINGS_IGNORED_DIRS, []).has(path):
				continue
			dirs.append_array(_get_dirs(path))
		return dirs


func reload(resource_template: Script) -> void:
	_resource_template = resource_template
	for child in _column_headers.get_children():
		_column_headers.remove_child(child)
		child.queue_free()
	for child in _item_actions.get_children():
		_item_actions.remove_child(child)
		child.queue_free()
	for row in _data.get_children():
		_data.remove_child(row)
		row.queue_free()
	_new_resource_folder.clear()
	_loaded_resources.clear()
	for property in _get_resource_properties():
		var label := Label.new()
		label.text = (property[&"name"] as String).capitalize()
		label.custom_minimum_size.x = _get_column_width(property)
		_column_headers.add_child(label)
	var right_side_buffer := Control.new()
	right_side_buffer.custom_minimum_size.x = ROW_END_PADDING
	_column_headers.add_child(right_side_buffer)
	for dir in _get_dirs():
		_new_resource_folder.add_item(dir)
		for file in DirAccess.get_files_at(dir):
			if file.begins_with("."):
				continue
			var allowed_filetypes: Array[String]
			allowed_filetypes.assign(ProjectSettings.get_setting(ResourceManagerPlugin.SETTINGS_ALLOWED_FILETYPES, []))
			allowed_filetypes.map(func(ext: String) -> String:
				return ext.trim_prefix(".") if ext.begins_with(".") else ext)
			if not allowed_filetypes.has(file.get_extension()):
				continue
			var path := dir + ("/" if not dir.ends_with("/") else "") + file
			_load_resource(path)


func _get_resource_properties() -> Array[Dictionary]:
	var resource_example: Resource = _resource_template.new()
	return resource_example.get_property_list().filter(func(property: Dictionary) -> bool:
		return property[&"usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE > 0)


func _get_input_field(property: Dictionary, resource: Resource) -> Control:
	var value: Variant = resource.get(property[&"name"])
	match property[&"type"]:
		TYPE_BOOL:
			var input := CheckBox.new()
			input.button_pressed = value as bool
			input.custom_minimum_size.x = _get_column_width(property)
			input.toggled.connect(func(value: bool) -> void:
				resource.set(property[&"name"], value))
			resource.changed.connect(func() -> void:
				print("hi")
				input.set_pressed_no_signal(resource.get(property[&"name"]))
				#input.set_pressed_no_signal(resource.get.bind(property[&"name"]).call())
				print("ho"))
			return input
		TYPE_INT, TYPE_FLOAT:
			# TODO: Bitflags
			if property[&"hint"] == PROPERTY_HINT_ENUM:
				var names: Array[String] = []
				var values: Array[int] = []
				var input := OptionButton.new()
				input.custom_minimum_size.x = _get_column_width(property)
				for item in property[&"hint_string"].split(","):
					names.append(item.get_slice(":", 0))
					values.append(item.get_slice(":", 1).to_int())
				for i in names.size():
					input.add_item(names[i])
					input.set_item_metadata(i, values[i])
				input.selected = values.find(value as int)
				input.item_selected.connect(func(index: int) -> void:
					resource.set(property[&"name"], values.find(index)))
				resource.changed.connect(func() -> void:
					input.selected = values.find(resource.get(property[&"name"])))
				return input
			else:
				var input := SpinBox.new()
				input.value = value as float
				# TODO: Check for prefix/suffix and min/max
				input.custom_minimum_size.x = _get_column_width(property)
				input.value_changed.connect(func(value: float) -> void:
					resource.set(property[&"name"], value))
				resource.changed.connect(func() -> void:
					input.set_value_no_signal(resource.get(property[&"name"])))
				return input
		TYPE_STRING, TYPE_STRING_NAME:
			var input := LineEdit.new()
			input.text = str(value)
			input.custom_minimum_size.x = _get_column_width(property)
			input.placeholder_text = property[&"name"]
			input.text_changed.connect(func(value: String) -> void:
				resource.set(property[&"name"], value))
			resource.changed.connect(func() -> void:
				input.text = resource.get(property[&"name"]))
			return input
		TYPE_COLOR:
			var input := ColorPickerButton.new()
			input.color = value as Color
			input.custom_minimum_size.x = _get_column_width(property)
			input.text = property[&"name"]
			input.color_changed.connect(func(value: Color) -> void:
				resource.set(property[&"name"], value))
			resource.changed.connect(func() -> void:
				input.color = resource.get(property[&"name"]))
			return input
		TYPE_VECTOR2, TYPE_VECTOR2I:
			var input := HBoxContainer.new()
			input.custom_minimum_size.x = _get_column_width(property)
			var x_input := SpinBox.new()
			x_input.prefix = "x:"
			x_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			x_input.value = (value as Vector2).x
			x_input.value_changed.connect(func(value: float) -> void:
				resource.get(property[&"name"]).x = value)
			var y_input := SpinBox.new()
			y_input.prefix = "y:"
			y_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			y_input.value = (value as Vector2).y
			y_input.value_changed.connect(func(value: float) -> void:
				resource.get(property[&"name"]).y = value)
			resource.changed.connect(func() -> void:
				x_input.value = resource.get(property[&"name"]).x
				y_input.value = resource.get(property[&"name"]).y)
			input.add_child(x_input)
			input.add_child(y_input)
			return input
		TYPE_VECTOR3, TYPE_VECTOR3I:
			var input := HBoxContainer.new()
			input.custom_minimum_size.x = _get_column_width(property)
			var x_input := SpinBox.new()
			x_input.prefix = "x:"
			x_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			x_input.value = (value as Vector3).x
			x_input.value_changed.connect(func(value: float) -> void:
				resource.get(property[&"name"]).x = value)
			var y_input := SpinBox.new()
			y_input.prefix = "y:"
			y_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			y_input.value = (value as Vector3).y
			y_input.value_changed.connect(func(value: float) -> void:
				resource.get(property[&"name"]).y = value)
			var z_input := SpinBox.new()
			z_input.prefix = "z:"
			z_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			z_input.value = (value as Vector3).z
			z_input.value_changed.connect(func(value: float) -> void:
				resource.get(property[&"name"]).z = value)
			resource.changed.connect(func() -> void:
				x_input.value = resource.get(property[&"name"]).x
				y_input.value = resource.get(property[&"name"]).y
				z_input.value = resource.get(property[&"name"]).z)
			input.add_child(x_input)
			input.add_child(y_input)
			input.add_child(z_input)
			return input
		TYPE_VECTOR4, TYPE_VECTOR4I:
			var input := HBoxContainer.new()
			input.custom_minimum_size.x = _get_column_width(property)
			var x_input := SpinBox.new()
			x_input.prefix = "x:"
			x_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			x_input.value = (value as Vector4).x
			x_input.value_changed.connect(func(value: float) -> void:
				resource.get(property[&"name"]).x = value)
			var y_input := SpinBox.new()
			y_input.prefix = "y:"
			y_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			y_input.value = (value as Vector4).y
			y_input.value_changed.connect(func(value: float) -> void:
				resource.get(property[&"name"]).y = value)
			var z_input := SpinBox.new()
			z_input.prefix = "z:"
			z_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			z_input.value = (value as Vector4).z
			z_input.value_changed.connect(func(value: float) -> void:
				resource.get(property[&"name"]).z = value)
			var w_input := SpinBox.new()
			w_input.prefix = "w:"
			w_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			w_input.value = (value as Vector4).w
			w_input.value_changed.connect(func(value: float) -> void:
				resource.get(property[&"name"]).w = value)
			resource.changed.connect(func() -> void:
				x_input.value = resource.get(property[&"name"]).x
				y_input.value = resource.get(property[&"name"]).y
				z_input.value = resource.get(property[&"name"]).z
				w_input.value = resource.get(property[&"name"]).w)
			input.add_child(x_input)
			input.add_child(y_input)
			input.add_child(z_input)
			input.add_child(w_input)
			return input
		TYPE_RECT2, TYPE_RECT2I:
			pass # TODO: Copy from Vector4, and have w, h instead of z, w
		TYPE_TRANSFORM2D:
			pass
		TYPE_TRANSFORM3D:
			pass
		TYPE_PLANE:
			pass
		TYPE_QUATERNION:
			pass
		TYPE_AABB:
			pass
		TYPE_BASIS:
			pass
		TYPE_PROJECTION:
			pass
		TYPE_NODE_PATH:
			pass
		TYPE_ARRAY:
			#print("Array type")
			pass
			#var subtype := (property[&"hint_string"]).get_slice(":", 0).to_int() as Variant.Type
			#var input := ArrayEditorButton.new()
			#input.subtype = subtype
			#input.data = []
			#input.data.assign(value)
			#input.text = "Array[%s] (%d)" % [type_string(subtype), input.data.size()]
			#input.custom_minimum_size.x = _get_column_width(property)
			#return input
		# TODO: All the Packed_*_Array types
		TYPE_DICTIONARY:
			#print("Dictionary type")
			#print(property[&"hint_string"].get_slice(":", 0))
			#var input := Button.new()
			#input.disabled = true
			#input.text = "Coming soon"
			#input.custom_minimum_size.x = _get_column_width(property)
			#return input
			pass
		#TYPE_CALLABLE:
			#pass
		#TYPE_SIGNAL:
			#pass
		#TYPE_RID:
			#pass
		TYPE_OBJECT:
			assert(property[&"hint"] == 17)
			var input := EditorResourcePicker.new()
			input.base_type = property[&"hint_string"]
			input.custom_minimum_size.x = _get_column_width(property)
			input.resource_changed.connect(func(r: Resource) -> void:
				EditorInterface.get_inspector().edit(r)
				# HACK: This is assuming undocumented behaviour of EditorResourcePicker nodes
				var button := input.get_child(0, true) as Button
				button.pressed.connect(EditorInterface.get_inspector().edit.bind(r)))
			if value:
				input.edited_resource = value as Resource
				# HACK: This is assuming undocumented behaviour of EditorResourcePicker nodes
				var button := input.get_child(0, true) as Button
				button.pressed.connect(EditorInterface.get_inspector().edit.bind(value as Resource))
			return input
		_:
			push_warning("Unknown Resource Property type: %s" % type_string(property[&"type"]))
	var backup_button := Button.new()
	backup_button.disabled = false
	backup_button.text = type_string(property[&"type"])
	var subtype := str(property[&"hint_string"]).get_slice(":", 0)
	if subtype.contains("/"):
		subtype = type_string(subtype.get_slice("/", 0).to_int()) + ", " + type_string(subtype.get_slice("/", 1).to_int())
		backup_button.text += "[%s]" % subtype
	elif not subtype.is_empty():
		subtype = type_string(subtype.to_int())
		backup_button.text += "[%s]" % subtype
	backup_button.custom_minimum_size.x = _get_column_width(property)
	backup_button.pressed.connect(EditorInterface.inspect_object.bind(resource, property[&"name"]))
	return backup_button


func _get_column_width(property: Dictionary) -> int:
	match property[&"type"]:
		TYPE_BOOL:
			return 96
		TYPE_INT, TYPE_FLOAT:
			# TODO: Bitflags
			if property[&"hint"] == PROPERTY_HINT_ENUM:
				return 128
			else:
				return 128
		TYPE_STRING, TYPE_STRING_NAME:
			return 192
		TYPE_COLOR:
			return 96
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return 96*2
		TYPE_VECTOR3, TYPE_VECTOR3I:
			return 96*3
		TYPE_VECTOR4, TYPE_VECTOR4I:
			return 96*4
		TYPE_RECT2, TYPE_RECT2I:
			return 96*4
		TYPE_TRANSFORM2D:
			pass
		TYPE_TRANSFORM3D:
			pass
		TYPE_PLANE:
			pass
		TYPE_QUATERNION:
			pass
		TYPE_AABB:
			pass
		TYPE_BASIS:
			pass
		TYPE_PROJECTION:
			pass
		TYPE_NODE_PATH:
			pass
		TYPE_ARRAY:
			return 192
		# TODO: All the Packed_*_Array types
		TYPE_DICTIONARY:
			return 192
		#TYPE_CALLABLE:
			#pass
		#TYPE_SIGNAL:
			#pass
		#TYPE_RID:
			#pass
		TYPE_OBJECT:
			assert(property[&"hint"] == 17)
			return 192
		_:
			push_warning("Unknown Resource Property type: %s" % type_string(property[&"type"]))
	return 192


func _add_new_resource() -> void:
	var dir := _new_resource_folder.get_item_text(_new_resource_folder.selected)
	var filepath := dir + "/" + _new_resource_filename.text + ".tres"
	var resource: Resource = _resource_template.new()
	ResourceSaver.save(resource, filepath)
	_load_resource(filepath)
	_is_resource_just_created = true
	_new_resource_filename.text = ""
	_new_resource_confirm.disabled = true
	_new_resource_popup.hide()
	await get_tree().process_frame
	_is_resource_just_created = false


func _delete_resource(resource: Resource, filepath: String) -> void:
	print("Deleting not yet implemented")
	print("Note to developer: Implement Undo and Redo first :)")


func _duplicate_resource(resource: Resource) -> void:
	var dir := resource.resource_path.get_base_dir()
	var base := resource.resource_path.get_file().get_basename()
	var n := range(_new_resource_folder.item_count).find_custom(func(i: int) -> bool:
		return _new_resource_folder.get_item_text(i) == dir)
	if n > -1:
		_new_resource_folder.selected = n
	_new_resource_filename.text = "CopyOf_" + base
	_new_resource_popup.popup_centered()
	_validate_filename(_new_resource_filename.text)
	await _new_resource_popup.visibility_changed
	if _is_resource_just_created:
		var copy := _loaded_resources[_loaded_resources.size()-1]
		for i in _get_resource_properties().size():
			var property: StringName = _get_resource_properties()[i][&"name"]
			copy.set(property, resource.get(property))
		copy.changed.emit()
		ResourceSaver.save(copy, copy.resource_path)


func manual_edit(resource: Resource) -> void:
	EditorInterface.inspect_object(resource)


func _load_resource(filepath: String) -> void:
	var resource := load(filepath)
	if not is_type(_resource_template, resource.get_script()):
		return
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = ROW_MIN_HEIGHT
	_loaded_resources.append(resource)
	var item_actions := HBoxContainer.new()
	item_actions.custom_minimum_size.y = ROW_MIN_HEIGHT
	for property in _get_resource_properties():
		var input := _get_input_field(property, resource)
		item_actions.custom_minimum_size.y = ROW_MIN_HEIGHT
		input.resized.connect(func() -> void:
			item_actions.custom_minimum_size.y = maxf(item_actions.custom_minimum_size.y, input.size.y))
		row.add_child(input)
	var right_side_buffer := Control.new()
	right_side_buffer.custom_minimum_size.x = ROW_END_PADDING
	row.add_child(right_side_buffer)
	_data.add_child(row)
	var delete_btn := Button.new()
	var duplicate_btn := Button.new()
	var manual_edit_btn := Button.new()
	delete_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	duplicate_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	manual_edit_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	delete_btn.tooltip_text = "Delete this resource"
	duplicate_btn.tooltip_text = "Duplicate this resource"
	manual_edit_btn.tooltip_text = "Manually edit this resource"
	delete_btn.pressed.connect(_delete_resource.bind(resource, filepath))
	duplicate_btn.pressed.connect(_duplicate_resource.bind(resource))
	manual_edit_btn.pressed.connect(manual_edit.bind(resource))
	delete_btn.icon = EditorInterface.get_editor_theme().get_icon("Remove", "EditorIcons")
	duplicate_btn.icon = EditorInterface.get_editor_theme().get_icon("Duplicate", "EditorIcons")
	manual_edit_btn.icon = EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons")
	item_actions.add_child(duplicate_btn)
	item_actions.add_child(manual_edit_btn)
	item_actions.add_child(delete_btn)
	_item_actions.add_child(item_actions)


# SEE: https://forum.godotengine.org/t/type-type-hint/2471/4
func is_type(desired_type: Script, current_type: Script) -> bool:
	if not current_type:
		return false
	return true if current_type == desired_type else is_type(desired_type, current_type.get_base_script())


func _save_all() -> void:
	_editor_container.visible = false
	_save_indicator.visible = true
	_save_progress.max_value = _loaded_resources.size()
	_save_progress.value = 0
	for resource in _loaded_resources:
		ResourceSaver.save(resource, resource.resource_path)
		_save_progress.value += 1
		await get_tree().process_frame
	_save_indicator.visible = false
	_editor_container.visible = true


func _undo() -> void:
	_undo_redo.undo()


func _redo() -> void:
	_undo_redo.redo()
