extends CanvasLayer

signal speed_requested(value: int)
signal zoom_requested(delta: float)
signal reset_camera_requested()

var cash_label: Label
var date_label: Label
var speed_label: Label
var context_panel: PanelContainer
var context_title: Label
var context_body: RichTextLabel
var toast: Label
var toast_timer := 0.0

func _ready() -> void:
	_build_ui()
	set_process(true)

func _process(delta: float) -> void:
	_refresh_top()
	if toast_timer > 0.0:
		toast_timer -= delta
		toast.visible = true
	else:
		toast.visible = false

func _build_ui() -> void:
	_build_top_bar()
	_build_left_bar()
	_build_bottom_controls()
	_build_context()
	_build_toast()

func _panel(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s

func _button(text_value: String, size := 13) -> Button:
	var b := Button.new()
	b.text = text_value
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color("#e9ddbd"))
	b.add_theme_stylebox_override("normal", _panel(Color(0.02,0.07,0.09,0.94), Color("#6e5a35")))
	b.add_theme_stylebox_override("hover", _panel(Color(0.05,0.13,0.16,0.98), Color("#c69a4a")))
	b.add_theme_stylebox_override("pressed", _panel(Color(0.08,0.18,0.21,0.98), Color("#e1b65f")))
	return b

func _build_top_bar() -> void:
	var panel := PanelContainer.new()
	panel.anchor_right = 1.0
	panel.offset_bottom = 54
	panel.add_theme_stylebox_override("panel", _panel(Color(0.01,0.04,0.055,0.96), Color("#8f713a")))
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	var brand := Label.new()
	brand.text = "⚓  LOGISTICS INC.   •   TCH STUDIO"
	brand.custom_minimum_size.x = 360
	brand.add_theme_font_size_override("font_size", 20)
	brand.add_theme_color_override("font_color", Color("#e5bd66"))
	row.add_child(brand)
	date_label = Label.new()
	date_label.custom_minimum_size.x = 210
	date_label.add_theme_font_size_override("font_size", 15)
	row.add_child(date_label)
	cash_label = Label.new()
	cash_label.custom_minimum_size.x = 190
	cash_label.add_theme_font_size_override("font_size", 17)
	cash_label.add_theme_color_override("font_color", Color("#74e08d"))
	row.add_child(cash_label)
	speed_label = Label.new()
	speed_label.custom_minimum_size.x = 100
	speed_label.add_theme_font_size_override("font_size", 14)
	row.add_child(speed_label)
	var rep := Label.new()
	rep.text = "Reputation  10"
	rep.add_theme_font_size_override("font_size", 14)
	rep.add_theme_color_override("font_color", Color("#e4d39d"))
	row.add_child(rep)

func _build_left_bar() -> void:
	var panel := PanelContainer.new()
	panel.anchor_top = 0.10
	panel.anchor_bottom = 0.74
	panel.offset_left = 8
	panel.offset_right = 116
	panel.add_theme_stylebox_override("panel", _panel(Color(0.01,0.04,0.055,0.91), Color("#806634")))
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 7)
	panel.add_child(col)
	for item in ["⚓\nPORT", "⛵\nFLEET", "▤\nCONTRACTS", "⌂\nSHIPYARD", "◎\nWORLD", "♙\nPEOPLE"]:
		var b := _button(item, 11)
		b.custom_minimum_size = Vector2(88,55)
		b.pressed.connect(_nav_pressed.bind(item))
		col.add_child(b)

func _build_bottom_controls() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.32
	panel.anchor_right = 0.68
	panel.anchor_top = 0.88
	panel.anchor_bottom = 0.985
	panel.add_theme_stylebox_override("panel", _panel(Color(0.01,0.04,0.055,0.93), Color("#806634")))
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	panel.add_child(row)
	for data in [["Ⅱ",0],["▶",1],["▶▶",4]]:
		var b := _button(str(data[0]),14)
		b.custom_minimum_size = Vector2(58,48)
		b.pressed.connect(_speed.bind(int(data[1])))
		row.add_child(b)
	var minus := _button("−",20)
	minus.custom_minimum_size = Vector2(52,48)
	minus.pressed.connect(func(): zoom_requested.emit(-0.12))
	row.add_child(minus)
	var reset := _button("CENTER",11)
	reset.custom_minimum_size = Vector2(88,48)
	reset.pressed.connect(func(): reset_camera_requested.emit())
	row.add_child(reset)
	var plus := _button("+",20)
	plus.custom_minimum_size = Vector2(52,48)
	plus.pressed.connect(func(): zoom_requested.emit(0.12))
	row.add_child(plus)

func _build_context() -> void:
	context_panel = PanelContainer.new()
	context_panel.anchor_left = 0.79
	context_panel.anchor_right = 0.99
	context_panel.anchor_top = 0.10
	context_panel.anchor_bottom = 0.76
	context_panel.add_theme_stylebox_override("panel", _panel(Color(0.01,0.04,0.055,0.94), Color("#9b7839")))
	context_panel.visible = false
	add_child(context_panel)
	var col := VBoxContainer.new()
	context_panel.add_child(col)
	context_title = Label.new()
	context_title.add_theme_font_size_override("font_size", 18)
	context_title.add_theme_color_override("font_color", Color("#e5bd66"))
	context_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(context_title)
	col.add_child(HSeparator.new())
	context_body = RichTextLabel.new()
	context_body.bbcode_enabled = true
	context_body.fit_content = false
	context_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	context_body.add_theme_font_size_override("normal_font_size", 14)
	col.add_child(context_body)
	var close := _button("CLOSE",11)
	close.pressed.connect(func(): context_panel.visible = false)
	col.add_child(close)

func _build_toast() -> void:
	toast = Label.new()
	toast.anchor_left = 0.26
	toast.anchor_right = 0.74
	toast.anchor_top = 0.09
	toast.anchor_bottom = 0.145
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 13)
	toast.add_theme_color_override("font_color", Color("#f7e7b4"))
	toast.add_theme_stylebox_override("normal", _panel(Color(0.01,0.04,0.055,0.92), Color("#ad8742")))
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.visible = false
	add_child(toast)

func _refresh_top() -> void:
	if GameState.world.is_empty():
		return
	var day := int(GameState.world.get("day",1))
	var month := int(GameState.world.get("month",1))
	var year := int(GameState.world.get("year",1750))
	var hour := int(GameState.world.get("hour",8))
	date_label.text = "%02d/%02d/%04d   %02d:00" % [day,month,year,hour]
	cash_label.text = "£ %s" % _money(int(GameState.get_cash()))
	speed_label.text = "Time  x%d" % TimeSystem.speed

func _money(value: int) -> String:
	var s := str(abs(value))
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if value < 0 else "") + s + out

func _speed(value: int) -> void:
	speed_requested.emit(value)
	show_message("Simulation speed x%d" % value)

func _nav_pressed(item: String) -> void:
	show_message(item.replace("\n"," ") + " — deeper management opens in Phase 2; the port keeps running.")

func set_selection(_kind: String, data: Dictionary) -> void:
	context_panel.visible = true
	context_title.text = str(data.get("name","PORT ASSET"))
	var lines := []
	lines.append("[b]Type[/b]  %s" % str(data.get("type","facility")).capitalize())
	if data.has("level"): lines.append("[b]Level[/b]  %s" % str(data["level"]))
	if data.has("workers"): lines.append("[b]Workers[/b]  %s" % str(data["workers"]))
	if data.has("capacity"): lines.append("[b]Capacity[/b]  %s t" % str(data["capacity"]))
	if data.has("berths"): lines.append("[b]Berths[/b]  %s" % str(data["berths"]))
	if data.has("year"): lines.append("[b]Year[/b]  %s" % str(data["year"]))
	lines.append("")
	lines.append("[color=#79dc8c]%s[/color]" % str(data.get("status","Operating")))
	lines.append("")
	lines.append("Tap-drag the world to pan. Pinch or use +/- to zoom.")
	context_body.text = "\n".join(lines)

func show_message(message: String) -> void:
	toast.text = message
	toast_timer = 2.7
	toast.visible = true