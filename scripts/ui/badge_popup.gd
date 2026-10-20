extends Control
## Kartu pop-up saat badge wilayah diperoleh.

signal closed

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.075, 0.10, 0.15, 1.0), UiKit.GOLD, 16, 2))
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)
	var v := UiKit.vbox(14)
	panel.add_child(v)

	var head := UiKit.title("BADGE DIPEROLEH", 12, UiKit.GOLD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(104, 104)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(icon)

	var nm := UiKit.title("", 14, UiKit.TEXT)
	nm.name = "Name"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nm)

	var desc := UiKit.label("Wilayah berikutnya telah terbuka. Lanjutkan perjalanan dari Peta Wilayah.", 15, UiKit.MUTED, 400)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(desc)

	var btn := UiKit.primary_button("Lanjut  ▸", UiKit.GOLD, 17)
	btn.pressed.connect(func():
		visible = false
		closed.emit()
	)
	v.add_child(btn)

func show_badge(badge_id: String, badge_name: String) -> void:
	var icon: TextureRect = find_child("Icon", true, false)
	var nm: Label = find_child("Name", true, false)
	if icon:
		icon.texture = load("res://assets/ui/badge_%s.png" % badge_id)
	if nm:
		nm.text = badge_name.to_upper()
	visible = true
	scale = Vector2(0.9, 0.9)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
