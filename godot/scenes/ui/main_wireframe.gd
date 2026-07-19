extends Control
## Color placeholders (pixel art later): observe / edit, size presets, palette.
## See docs/guides/godot-beginner.md

const HabitatStageScript := preload("res://scenes/ui/habitat_stage.gd")
const EditPaletteScript := preload("res://scenes/ui/edit_palette.gd")
const CELL_CM := 1.0

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
var _grid_button: Button
var _size_option: OptionButton
var _aspect: AspectRatioContainer
var _stage: Control
var _palette: Control
var _palette_wrap: Control
var _is_edit: bool = false
var _grid_on: bool = true


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
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var margin_top := MarginContainer.new()
	margin_top.add_theme_constant_override("margin_left", 12)
	margin_top.add_theme_constant_override("margin_right", 12)
	margin_top.add_theme_constant_override("margin_top", 8)
	root.add_child(margin_top)

	var chrome := HBoxContainer.new()
	chrome.add_theme_constant_override("separation", 8)
	margin_top.add_child(chrome)

	chrome.add_child(_wire_label("Glass Wild", 16))
	chrome.add_child(_spacer())
	chrome.add_child(_wire_label("규격", 12))

	_size_option = OptionButton.new()
	_size_option.custom_minimum_size = Vector2(140, 28)
	for i in PRESETS.size():
		_size_option.add_item(PRESETS[i]["label"], i)
	_size_option.select(DEFAULT_PRESET_INDEX)
	_size_option.item_selected.connect(_on_size_selected)
	_style_option(_size_option)
	chrome.add_child(_size_option)

	_mode_button = Button.new()
	_mode_button.custom_minimum_size = Vector2(72, 28)
	_mode_button.pressed.connect(_on_mode_pressed)
	_style_button(_mode_button)
	chrome.add_child(_mode_button)

	_grid_button = Button.new()
	_grid_button.custom_minimum_size = Vector2(88, 28)
	_grid_button.pressed.connect(_on_grid_pressed)
	_style_button(_grid_button)
	_update_grid_button_text()
	chrome.add_child(_grid_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	root.add_child(body)

	var stage_margin := MarginContainer.new()
	stage_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_margin.add_theme_constant_override("margin_left", 24)
	stage_margin.add_theme_constant_override("margin_bottom", 4)
	body.add_child(stage_margin)

	_aspect = AspectRatioContainer.new()
	_aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	_aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	_aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	_aspect.custom_minimum_size = Vector2(240, 180)
	_aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_margin.add_child(_aspect)

	_stage = Control.new()
	_stage.set_script(HabitatStageScript)
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_aspect.add_child(_stage)

	_palette_wrap = MarginContainer.new()
	_palette_wrap.visible = false
	_palette_wrap.add_theme_constant_override("margin_right", 12)
	_palette_wrap.add_theme_constant_override("margin_top", 4)
	_palette_wrap.add_theme_constant_override("margin_bottom", 4)
	body.add_child(_palette_wrap)

	_palette = VBoxContainer.new()
	_palette.set_script(EditPaletteScript)
	_palette_wrap.add_child(_palette)
	_palette.call("setup", Callable(self, "_style_button"))
	_palette.tool_selected.connect(_on_tool_selected)
	_palette.terrain_mode_selected.connect(_on_terrain_mode_selected)

	var footer := MarginContainer.new()
	footer.add_theme_constant_override("margin_left", 12)
	footer.add_theme_constant_override("margin_right", 12)
	footer.add_theme_constant_override("margin_bottom", 8)
	root.add_child(footer)

	var footer_row := HBoxContainer.new()
	footer.add_child(footer_row)
	_status_label = _wire_label("상태: 안정", 13)
	footer_row.add_child(_status_label)
	footer_row.add_child(_spacer())
	_depth_label = _wire_label("", 11)
	footer_row.add_child(_depth_label)


func _on_size_selected(index: int) -> void:
	_apply_preset(index)


func _on_mode_pressed() -> void:
	_set_edit_mode(not _is_edit)


func _on_grid_pressed() -> void:
	_grid_on = not _grid_on
	_stage.call("set_show_display_grid", _grid_on)
	_update_grid_button_text()


func _update_grid_button_text() -> void:
	_grid_button.text = "격자 ON" if _grid_on else "격자 OFF"


func _on_tool_selected(tool: Dictionary) -> void:
	_stage.call("set_selected_tool", tool)


func _on_terrain_mode_selected(mode: String) -> void:
	_stage.call("set_terrain_place_mode", mode)


func _apply_preset(index: int) -> void:
	var p: Dictionary = PRESETS[index]
	_stage.call("set_preset", p["w"], p["d"], p["h"])
	_aspect.ratio = float(p["w"]) / float(p["h"])
	var cols := int(round(float(p["w"]) / CELL_CM))
	var rows := int(round(float(p["h"]) / CELL_CM))
	_depth_label.text = "깊이 %dcm · 논리 셀 %d×%d (1cm) · 표시 5cm" % [p["d"], cols, rows]


func _set_edit_mode(edit: bool) -> void:
	_is_edit = edit
	_stage.call("set_edit_mode", edit)
	_palette_wrap.visible = edit
	_grid_button.visible = edit
	_grid_button.disabled = not edit
	if edit:
		_mode_button.text = "관찰로"
		_status_label.text = "편집 · 논리 셀 1cm"
		_stage.call("set_show_display_grid", _grid_on)
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
	normal.set_content_margin_all(4)
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
	box.set_content_margin_all(4)
	opt.add_theme_stylebox_override("normal", box)
	opt.add_theme_stylebox_override("hover", box)
	opt.add_theme_stylebox_override("pressed", box)
	opt.add_theme_stylebox_override("focus", box)
