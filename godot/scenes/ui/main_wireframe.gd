extends Control
## B/W wireframe: observe / edit, size presets, edit palette (D-010).
## See docs/guides/godot-beginner.md

const HabitatStageScript := preload("res://scenes/ui/habitat_stage.gd")
const EditPaletteScript := preload("res://scenes/ui/edit_palette.gd")

const PRESETS: Array[Dictionary] = [
	{"label": "30×30×45cm", "w": 30, "d": 30, "h": 45},
	{"label": "45×45×45cm", "w": 45, "d": 45, "h": 45},
	{"label": "60×45×45cm", "w": 60, "d": 45, "h": 45},
	{"label": "60×45×60cm", "w": 60, "d": 45, "h": 60},
	{"label": "90×45×60cm", "w": 90, "d": 45, "h": 60},
	{"label": "120×60×60cm", "w": 120, "d": 60, "h": 60},
]

const DEFAULT_PRESET_INDEX := 2

var _status_label: Label
var _depth_label: Label
var _mode_button: Button
var _size_option: OptionButton
var _aspect: AspectRatioContainer
var _stage: Control
var _palette: Control
var _palette_wrap: Control
var _is_edit: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_apply_preset(DEFAULT_PRESET_INDEX)
	_set_edit_mode(false)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.BLACK
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var margin_top := MarginContainer.new()
	margin_top.add_theme_constant_override("margin_left", 24)
	margin_top.add_theme_constant_override("margin_right", 24)
	margin_top.add_theme_constant_override("margin_top", 16)
	root.add_child(margin_top)

	var chrome := HBoxContainer.new()
	chrome.add_theme_constant_override("separation", 16)
	margin_top.add_child(chrome)

	chrome.add_child(_wire_label("Glass Wild — 와이어프레임", 22))
	chrome.add_child(_spacer())
	chrome.add_child(_wire_label("사육장 규격", 14))

	_size_option = OptionButton.new()
	_size_option.custom_minimum_size = Vector2(180, 36)
	for i in PRESETS.size():
		_size_option.add_item(PRESETS[i]["label"], i)
	_size_option.select(DEFAULT_PRESET_INDEX)
	_size_option.item_selected.connect(_on_size_selected)
	_style_option(_size_option)
	chrome.add_child(_size_option)

	_mode_button = Button.new()
	_mode_button.custom_minimum_size = Vector2(120, 36)
	_mode_button.pressed.connect(_on_mode_pressed)
	_style_button(_mode_button)
	chrome.add_child(_mode_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var stage_margin := MarginContainer.new()
	stage_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_margin.add_theme_constant_override("margin_left", 48)
	stage_margin.add_theme_constant_override("margin_bottom", 8)
	body.add_child(stage_margin)

	_aspect = AspectRatioContainer.new()
	_aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	_aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	_aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	_aspect.custom_minimum_size = Vector2(320, 240)
	_aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_margin.add_child(_aspect)

	_stage = Control.new()
	_stage.set_script(HabitatStageScript)
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_aspect.add_child(_stage)

	_palette_wrap = MarginContainer.new()
	_palette_wrap.visible = false
	_palette_wrap.add_theme_constant_override("margin_right", 24)
	_palette_wrap.add_theme_constant_override("margin_top", 8)
	_palette_wrap.add_theme_constant_override("margin_bottom", 8)
	body.add_child(_palette_wrap)

	_palette = VBoxContainer.new()
	_palette.set_script(EditPaletteScript)
	_palette_wrap.add_child(_palette)
	_palette.call("setup", Callable(self, "_style_button"))
	_palette.tool_selected.connect(_on_tool_selected)

	var footer := MarginContainer.new()
	footer.add_theme_constant_override("margin_left", 24)
	footer.add_theme_constant_override("margin_right", 24)
	footer.add_theme_constant_override("margin_bottom", 20)
	root.add_child(footer)

	var footer_row := HBoxContainer.new()
	footer.add_child(footer_row)
	_status_label = _wire_label("상태: 안정", 18)
	footer_row.add_child(_status_label)
	footer_row.add_child(_spacer())
	_depth_label = _wire_label("", 14)
	footer_row.add_child(_depth_label)


func _on_size_selected(index: int) -> void:
	_apply_preset(index)


func _on_mode_pressed() -> void:
	_set_edit_mode(not _is_edit)


func _on_tool_selected(tool: Dictionary) -> void:
	_stage.call("set_selected_tool", tool)


func _apply_preset(index: int) -> void:
	var p: Dictionary = PRESETS[index]
	_stage.call("set_preset", p["w"], p["d"], p["h"])
	_aspect.ratio = float(p["w"]) / float(p["h"])
	var cols := int(round(float(p["w"]) / 0.5))
	var rows := int(round(float(p["h"]) / 0.5))
	_depth_label.text = "깊이 %dcm · 논리 셀 %d×%d (0.5cm)" % [p["d"], cols, rows]


func _set_edit_mode(edit: bool) -> void:
	_is_edit = edit
	_stage.call("set_edit_mode", edit)
	_palette_wrap.visible = edit
	if edit:
		_mode_button.text = "관찰로"
		_status_label.text = "편집 · 논리 셀 0.5cm"
	else:
		_mode_button.text = "편집"
		_status_label.text = "상태: 안정"


func _wire_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s


func _style_button(btn: Button) -> void:
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.BLACK)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.BLACK
	normal.set_border_width_all(1)
	normal.border_color = Color.WHITE
	normal.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.15, 0.15, 0.15)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = Color.WHITE
	btn.add_theme_stylebox_override("pressed", pressed)


func _style_option(opt: OptionButton) -> void:
	opt.add_theme_color_override("font_color", Color.WHITE)
	opt.add_theme_color_override("font_hover_color", Color.WHITE)
	var box := StyleBoxFlat.new()
	box.bg_color = Color.BLACK
	box.set_border_width_all(1)
	box.border_color = Color.WHITE
	box.set_content_margin_all(8)
	opt.add_theme_stylebox_override("normal", box)
	opt.add_theme_stylebox_override("hover", box)
	opt.add_theme_stylebox_override("pressed", box)
	opt.add_theme_stylebox_override("focus", box)
