extends VBoxContainer
## Edit palette: terrain / plant / animal tools (D-010). Emits tool dictionaries.

signal tool_selected(tool: Dictionary)

const TOOLS: Array[Dictionary] = [
	{"section": "지형", "kind": "terrain", "id": "wall", "label": "벽지"},
	{"section": "지형", "kind": "terrain", "id": "floor", "label": "땅"},
	{"section": "지형", "kind": "terrain", "id": "water", "label": "물"},
	{
		"section": "식물·이끼",
		"kind": "plant",
		"id": "moss_floor",
		"label": "이끼(바닥)",
		"surfaces": ["floor_air", "floor_water"],
	},
	{
		"section": "식물·이끼",
		"kind": "plant",
		"id": "moss_wall",
		"label": "이끼(벽지)",
		"surfaces": ["wall_air", "wall_water"],
	},
	{"section": "동물", "kind": "animal", "id": "nerite_snail", "label": "nerite_snail"},
]

var _buttons: Array[Button] = []
var _style_fn: Callable


func setup(style_button: Callable) -> void:
	_style_fn = style_button
	add_theme_constant_override("separation", 8)
	custom_minimum_size = Vector2(200, 0)

	var title := Label.new()
	title.text = "편집 팔레트"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)

	var hint := Label.new()
	hint.text = "지형: 클릭·드래그\n동물·식물: 클릭"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	add_child(hint)

	var current_section := ""
	for tool in TOOLS:
		var section: String = tool["section"]
		if section != current_section:
			current_section = section
			var sec := Label.new()
			sec.text = section
			sec.add_theme_font_size_override("font_size", 13)
			sec.add_theme_color_override("font_color", Color.WHITE)
			add_child(sec)
		var btn := Button.new()
		btn.text = String(tool["label"])
		btn.custom_minimum_size = Vector2(0, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured: Dictionary = tool
		btn.pressed.connect(func() -> void: _on_tool(captured, btn))
		if _style_fn.is_valid():
			_style_fn.call(btn)
		add_child(btn)
		_buttons.append(btn)


func _on_tool(tool: Dictionary, btn: Button) -> void:
	for b in _buttons:
		b.modulate = Color.WHITE
	btn.modulate = Color(0.7, 0.9, 1.0)
	tool_selected.emit(tool)
