extends Label
class_name PropertyHeaderLabel

var property_name: String
var property_type: String


func _ready() -> void:
	tooltip_text = "[b][color=%s]Property[/color] %s[color=%s]:[/color][/b]  [color=%s][code]%s[/code][/color]" % [
		get_theme_color("title_color", "EditorHelp").to_html(),
		property_name, 
		get_theme_color("symbol_color", "EditorHelp").to_html(),
		get_theme_color("type_color", "EditorHelp").to_html(),
		property_type
	]


func _make_custom_tooltip(for_text: String) -> Object:
	var label := RichTextLabel.new()
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.bbcode_enabled = true
	label.parse_bbcode(for_text)
	var root := EditorInterface.get_base_control()
	var font_size := root.get_theme_font_size(&"main_size", &"EditorFonts")
	label.add_theme_font_size_override(&"normal_font_size", font_size)
	label.add_theme_font_size_override(&"bold_font_size", font_size)
	label.add_theme_font_size_override(&"mono_font_size", font_size)
	label.add_theme_font_override(&"normal_font", get_theme_font("doc_title", "EditorFonts"))
	label.add_theme_font_override(&"bold_font", get_theme_font("doc_bold", "EditorFonts"))
	label.add_theme_font_override(&"mono_font", get_theme_font("doc_keyboard", "EditorFonts"))
	return label
