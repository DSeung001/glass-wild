extends Control
## Glass Wild learning wireframe: Dashboard / Habitat / Edit with ColorRect placeholders.
## See docs/guides/godot-beginner.md

const CreatureScript := preload("res://scenes/ui/creature_placeholder.gd")

var dashboard: Control
var habitat: Control
var edit_screen: Control


func _ready() -> void:
	_build_ui()
	_show_only(dashboard)


func _show_only(screen: Control) -> void:
	dashboard.visible = screen == dashboard
	habitat.visible = screen == habitat
	edit_screen.visible = screen == edit_screen


func _on_to_habitat_pressed() -> void:
	_show_only(habitat)


func _on_to_dashboard_pressed() -> void:
	_show_only(dashboard)


func _on_to_edit_pressed() -> void:
	_show_only(edit_screen)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.13, 0.15)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	dashboard = _build_dashboard()
	habitat = _build_habitat()
	edit_screen = _build_edit()
	add_child(dashboard)
	add_child(habitat)
	add_child(edit_screen)


func _build_dashboard() -> Control:
	var root := Control.new()
	root.name = "Dashboard"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title := _label("사육장 대시보드", 28)
	title.position = Vector2(64, 48)
	root.add_child(title)

	var subtitle := _label("UI-02 · 색 박스로 사육장 카드 자리만 잡음", 16)
	subtitle.position = Vector2(64, 96)
	subtitle.modulate = Color(0.75, 0.78, 0.82)
	root.add_child(subtitle)

	var cards := [
		{"name": "사육장 1", "status": "안정", "color": Color(0.28, 0.45, 0.32)},
		{"name": "사육장 2", "status": "주의", "color": Color(0.45, 0.38, 0.22)},
		{"name": "사육장 3", "status": "정보", "color": Color(0.25, 0.35, 0.48)},
	]
	for i in cards.size():
		var card := _card(cards[i]["name"], cards[i]["status"], cards[i]["color"])
		card.position = Vector2(64 + i * 420, 180)
		root.add_child(card)

	var btn := _button("관찰하기", Vector2(64, 520), Vector2(220, 56))
	btn.pressed.connect(_on_to_habitat_pressed)
	root.add_child(btn)
	return root


func _build_habitat() -> Control:
	var root := Control.new()
	root.name = "Habitat"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.visible = false

	var title := _label("사육장 관찰", 28)
	title.position = Vector2(64, 40)
	root.add_child(title)

	var view := ColorRect.new()
	view.position = Vector2(64, 100)
	view.size = Vector2(1400, 720)
	view.color = Color(0.18, 0.28, 0.22)
	root.add_child(view)

	var water := ColorRect.new()
	water.position = Vector2(64, 100 + 480)
	water.size = Vector2(1400, 240)
	water.color = Color(0.15, 0.28, 0.42, 0.85)
	root.add_child(water)
	var water_label := _label("수역 (placeholder)", 14)
	water_label.position = Vector2(80, 100 + 500)
	root.add_child(water_label)

	var creature := ColorRect.new()
	creature.position = Vector2(280, 420)
	creature.size = Vector2(64, 48)
	creature.color = Color(0.85, 0.75, 0.35)
	creature.set_script(CreatureScript)
	root.add_child(creature)

	var creature_label := _label("nerite_snail", 14)
	creature_label.position = Vector2(270, 475)
	root.add_child(creature_label)

	var status := _label("상태: 안정", 20)
	status.position = Vector2(64, 850)
	root.add_child(status)

	var hint := _label("화살표 키로 색 박스(생물 자리) 이동 · Step 6", 14)
	hint.position = Vector2(64, 890)
	hint.modulate = Color(0.7, 0.72, 0.76)
	root.add_child(hint)

	var to_dash := _button("대시보드로", Vector2(1520, 100), Vector2(280, 52))
	to_dash.pressed.connect(_on_to_dashboard_pressed)
	root.add_child(to_dash)

	var to_edit := _button("편집", Vector2(1520, 168), Vector2(280, 52))
	to_edit.pressed.connect(_on_to_edit_pressed)
	root.add_child(to_edit)
	return root


func _build_edit() -> Control:
	var root := Control.new()
	root.name = "Edit"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.visible = false

	var title := _label("편집 — 격자 표시", 28)
	title.position = Vector2(64, 40)
	root.add_child(title)

	var note := _label("UI-04 · D-003 논리 격자 느낌 (도트/타일맵 아님)", 16)
	note.position = Vector2(64, 88)
	note.modulate = Color(0.75, 0.78, 0.82)
	root.add_child(note)

	var cols := 12
	var rows := 8
	var cell := 72
	var origin := Vector2(64, 140)
	for y in rows:
		for x in cols:
			var rect := ColorRect.new()
			rect.position = origin + Vector2(x * (cell + 4), y * (cell + 4))
			rect.size = Vector2(cell, cell)
			var shade := 0.22 + ((x + y) % 2) * 0.04
			rect.color = Color(shade, shade + 0.02, shade + 0.04)
			root.add_child(rect)

	var back := _button("관찰로 돌아가기", Vector2(64, 820), Vector2(280, 56))
	back.pressed.connect(_on_to_habitat_pressed)
	root.add_child(back)
	return root


func _card(card_name: String, status: String, color: Color) -> ColorRect:
	var card := ColorRect.new()
	card.size = Vector2(380, 260)
	card.color = color

	var name_label := _label(card_name, 22)
	name_label.position = Vector2(24, 24)
	card.add_child(name_label)

	var status_label := _label("상태: %s" % status, 18)
	status_label.position = Vector2(24, 80)
	card.add_child(status_label)

	var hint := _label("미리보기 자리", 14)
	hint.position = Vector2(24, 180)
	hint.modulate = Color(1, 1, 1, 0.7)
	card.add_child(hint)
	return card


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _button(text: String, pos: Vector2, size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = size
	return btn
