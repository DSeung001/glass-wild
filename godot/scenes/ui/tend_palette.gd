extends VBoxContainer
## Tend palette: terrain modes + tools (D-010). Access tags (D-009).

signal tool_selected(tool: Dictionary)
signal terrain_mode_selected(mode: String)

const ACCESS_LAND_CLIMB: Array[String] = ["floor_air", "wall_air"]
const ACCESS_FLOOR_ONLY: Array[String] = ["floor_air"]
const ACCESS_SWIM: Array[String] = ["swim"]
const ACCESS_NEWT: Array[String] = ["floor_air", "wall_air", "floor_water", "swim"]
const ACCESS_NERITE: Array[String] = ["floor_water", "wall_water"]
const ACCESS_SHRIMP: Array[String] = ["floor_water", "swim"]
const ACCESS_MOSS_FLOOR: Array[String] = ["floor_air", "floor_water"]
const ACCESS_MOSS_WALL: Array[String] = ["wall_air", "wall_water"]

## Placeholder colors until pixel art (distinct per animal).
const TOOLS: Array[Dictionary] = [
	{"section": "지형", "kind": "terrain", "id": "wall", "label": "벽지"},
	{"section": "지형", "kind": "terrain", "id": "floor", "label": "땅"},
	{"section": "지형", "kind": "terrain", "id": "water", "label": "물"},
	{
		"section": "식물·이끼",
		"kind": "plant",
		"id": "moss_floor",
		"label": "이끼(바닥)",
		"access": ACCESS_MOSS_FLOOR,
	},
	{
		"section": "식물·이끼",
		"kind": "plant",
		"id": "moss_wall",
		"label": "이끼(벽지)",
		"access": ACCESS_MOSS_WALL,
	},
	{
		"section": "동물",
		"kind": "animal",
		"id": "nerite_snail",
		"display_name": "네리트 달팽이",
		"label": "네리트 달팽이",
		"color": Color(0.75, 0.78, 0.82),
		"access": ACCESS_NERITE,
	},
	{
		"section": "동물",
		"kind": "animal",
		"id": "cherry_shrimp",
		"display_name": "체리새우",
		"label": "체리새우",
		"color": Color(0.85, 0.28, 0.32),
		"access": ACCESS_SHRIMP,
	},
	{
		"section": "동물",
		"kind": "animal",
		"id": "isopod",
		"display_name": "등각류",
		"label": "등각류",
		"color": Color(0.55, 0.48, 0.38),
		"access": ACCESS_LAND_CLIMB,
	},
	{
		"section": "동물",
		"kind": "animal",
		"id": "mourning_gecko",
		"display_name": "모어닝게코",
		"label": "모어닝게코",
		"color": Color(0.72, 0.62, 0.35),
		"access": ACCESS_LAND_CLIMB,
	},
	{
		"section": "동물",
		"kind": "animal",
		"id": "springtail",
		"display_name": "스프링테일",
		"label": "스프링테일",
		"color": Color(0.9, 0.9, 0.85),
		"access": ACCESS_FLOOR_ONLY,
	},
	{
		"section": "동물",
		"kind": "animal",
		"id": "dart_frog",
		"display_name": "다트프록",
		"label": "다트프록",
		"color": Color(0.2, 0.55, 0.95),
		"access": ACCESS_LAND_CLIMB,
	},
	{
		"section": "동물",
		"kind": "animal",
		"id": "endler_guppy",
		"display_name": "앤들러 구피",
		"label": "앤들러 구피",
		"color": Color(0.95, 0.55, 0.15),
		"access": ACCESS_SWIM,
	},
	{
		"section": "동물",
		"kind": "animal",
		"id": "fire_belly_newt",
		"display_name": "파이어밸리 뉴트",
		"label": "파이어밸리 뉴트",
		"color": Color(0.85, 0.35, 0.2),
		"access": ACCESS_NEWT,
		"access_limits": {"wall_air": 5},
	},
]

var _buttons: Array[Button] = []
var _mode_dot: Button
var _mode_rect: Button
var _style_fn: Callable
var _terrain_mode: String = "dot"


func setup(style_button: Callable) -> void:
	_style_fn = style_button
	add_theme_constant_override("separation", 4)
	custom_minimum_size = Vector2(160, 0)

	var title := Label.new()
	title.text = "팔레트"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)

	var mode_cap := Label.new()
	mode_cap.text = "지형 모드"
	mode_cap.add_theme_font_size_override("font_size", 11)
	mode_cap.add_theme_color_override("font_color", Color.WHITE)
	add_child(mode_cap)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 4)
	add_child(mode_row)

	_mode_dot = Button.new()
	_mode_dot.text = "점"
	_mode_dot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mode_dot.custom_minimum_size = Vector2(0, 26)
	_mode_dot.pressed.connect(func() -> void: _set_terrain_mode("dot"))
	if _style_fn.is_valid():
		_style_fn.call(_mode_dot)
	mode_row.add_child(_mode_dot)

	_mode_rect = Button.new()
	_mode_rect.text = "사각형"
	_mode_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mode_rect.custom_minimum_size = Vector2(0, 26)
	_mode_rect.pressed.connect(func() -> void: _set_terrain_mode("rect"))
	if _style_fn.is_valid():
		_style_fn.call(_mode_rect)
	mode_row.add_child(_mode_rect)
	_refresh_mode_buttons()

	var hint := Label.new()
	hint.text = "점: 클릭\n사각형: 드래그\n동물·식물: 클릭"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	add_child(hint)

	var current_section := ""
	for tool in TOOLS:
		var section: String = tool["section"]
		if section != current_section:
			current_section = section
			var sec := Label.new()
			sec.text = section
			sec.add_theme_font_size_override("font_size", 11)
			sec.add_theme_color_override("font_color", Color.WHITE)
			add_child(sec)
		var btn := Button.new()
		btn.text = String(tool["label"])
		btn.custom_minimum_size = Vector2(0, 26)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured: Dictionary = tool
		btn.pressed.connect(func() -> void: _on_tool(captured, btn))
		if _style_fn.is_valid():
			_style_fn.call(btn)
		add_child(btn)
		_buttons.append(btn)


func _set_terrain_mode(mode: String) -> void:
	_terrain_mode = mode
	_refresh_mode_buttons()
	terrain_mode_selected.emit(mode)


func _refresh_mode_buttons() -> void:
	_mode_dot.modulate = Color(0.7, 0.9, 1.0) if _terrain_mode == "dot" else Color.WHITE
	_mode_rect.modulate = Color(0.7, 0.9, 1.0) if _terrain_mode == "rect" else Color.WHITE


func _on_tool(tool: Dictionary, btn: Button) -> void:
	for b in _buttons:
		b.modulate = Color.WHITE
	btn.modulate = Color(0.7, 0.9, 1.0)
	tool_selected.emit(tool)
