extends Control
## Popup singkat saat quest selesai dan uang diterima.

var _panel: PanelContainer
var _title: Label
var _amount: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.055, 0.10, 0.13, 0.97), UiKit.ACCENT, 12, 2))
	_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_panel.offset_left = -190
	_panel.offset_right = 190
	_panel.offset_top = 92
	_panel.offset_bottom = 174
	add_child(_panel)

	var box := UiKit.vbox(2)
	_panel.add_child(box)
	_title = UiKit.kicker("QUEST SELESAI", UiKit.ACCENT, 10)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_amount = UiKit.title("+10 UANG", 22, UiKit.GOLD)
	_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_amount)

func show_reward(amount: int) -> void:
	_amount.text = "+%d UANG" % amount
	visible = true
	modulate.a = 0.0
	_panel.position.y = -10
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
	tween.tween_property(_panel, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(1.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	tween.tween_callback(func(): visible = false)
