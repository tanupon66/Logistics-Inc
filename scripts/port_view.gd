extends Control

var sim_time := 0.0
var activity_level := 1.0
var owned_yard := false
var port_level := 1
var day_phase := 0.25
var selected_label := "Liverpool Harbour"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_business_state(level:int, yard:bool, activity:float) -> void:
	port_level = max(1, level)
	owned_yard = yard
	activity_level = clamp(activity, 0.35, 2.0)
	queue_redraw()

func _process(delta:float) -> void:
	sim_time += delta
	day_phase = fposmod(day_phase + delta * 0.0025, 1.0)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 8.0 or h <= 8.0:
		return
	var sun := 0.5 + 0.5 * sin((day_phase - 0.25) * TAU)
	var sky := Color("#243b50").lerp(Color("#82a9bd"), sun)
	var sea := Color("#17364b").lerp(Color("#2d6f87"), sun)
	var land := Color("#4b493f").lerp(Color("#77705d"), sun)
	draw_rect(Rect2(0, 0, w, h * 0.34), sky)
	draw_rect(Rect2(0, h * 0.34, w, h * 0.22), land)
	draw_rect(Rect2(0, h * 0.56, w, h * 0.44), sea)
	for i in range(14):
		var bx := 10.0 + float(i) * (w / 14.0)
		var bh := 35.0 + float((i * 31) % 70)
		var bw := 42.0 + float((i * 17) % 30)
		var c := Color("#3f4342").lerp(Color("#716c60"), sun)
		draw_rect(Rect2(bx, h * 0.34 - bh, bw, bh), c)
		if i % 3 == 0:
			draw_rect(Rect2(bx + bw * 0.55, h * 0.34 - bh - 28, 10, 28), Color("#303534"))
			_draw_smoke(Vector2(bx + bw * 0.55 + 5, h * 0.34 - bh - 30), i)
	draw_rect(Rect2(0, h * 0.405, w, 34), Color("#41413f"))
	draw_line(Vector2(0, h * 0.47), Vector2(w, h * 0.47), Color("#2a2a29"), 7)
	draw_line(Vector2(0, h * 0.49), Vector2(w, h * 0.49), Color("#2a2a29"), 7)
	for x in range(0, int(w) + 80, 42):
		draw_line(Vector2(x, h * 0.462), Vector2(x + 10, h * 0.498), Color("#6e624f"), 3)
	var buildings := min(11, 5 + port_level * 2)
	for i in range(buildings):
		var bx := 18.0 + float(i) * max(78.0, (w - 40.0) / float(buildings))
		var by := h * 0.37
		var bw := 62.0
		var bh := 52.0 + float((i * 13) % 25)
		draw_rect(Rect2(bx, by - bh, bw, bh), Color("#73543e"))
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 4, by - bh), Vector2(bx + bw * 0.5, by - bh - 16), Vector2(bx + bw + 4, by - bh)]), Color("#3d3834"))
		for wx in range(2):
			for wy in range(2):
				var lit := (i + wx + wy + int(sim_time * 0.1)) % 4 == 0 and sun < 0.45
				draw_rect(Rect2(bx + 10 + wx * 26, by - bh + 12 + wy * 18, 8, 7), Color("#edca71") if lit else Color("#28363a"))
	for i in range(4):
		var px := 45.0 + float(i) * (w * 0.22)
		var py := h * 0.56
		draw_rect(Rect2(px, py, 125, 32 + i * 8), Color("#5b4b38"))
		_draw_crane(Vector2(px + 32, py - 4), i)
		if port_level >= 2:
			_draw_crane(Vector2(px + 78, py + 5), i + 8)
	if owned_yard:
		var yx := w * 0.67
		var yy := h * 0.50
		draw_rect(Rect2(yx, yy - 80, w * 0.28, 80), Color("#594839"))
		draw_rect(Rect2(yx + 16, yy - 115, 72, 35), Color("#805a3c"))
		draw_string(ThemeDB.fallback_font, Vector2(yx + 12, yy - 124), "TCH SHIPYARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f1d28a"))
		draw_rect(Rect2(yx + 105, yy - 42, w * 0.15, 42), Color("#1a4154"))
		_draw_ship(Vector2(yx + 115, yy - 29), 0.55, Color("#293038"), Color("#e7d7b5"))
	var train_x := fposmod(sim_time * (34.0 * activity_level), w + 260.0) - 220.0
	for i in range(5):
		draw_rect(Rect2(train_x + i * 42, h * 0.452, 36, 16), Color("#8a3d2c") if i == 0 else Color("#4a5e5f"))
		draw_circle(Vector2(train_x + i * 42 + 9, h * 0.47), 4, Color("#15191b"))
		draw_circle(Vector2(train_x + i * 42 + 29, h * 0.47), 4, Color("#15191b"))
	for i in range(4):
		var cx := fposmod(sim_time * (24.0 + i * 4.0) * activity_level + i * 210.0, w + 120.0) - 80.0
		draw_rect(Rect2(cx, h * 0.414 + (i % 2) * 15, 28, 11), Color("#b68b49"))
		draw_circle(Vector2(cx + 7, h * 0.427 + (i % 2) * 15), 3, Color("#202326"))
		draw_circle(Vector2(cx + 22, h * 0.427 + (i % 2) * 15), 3, Color("#202326"))
	var ship_count := int(clamp(3.0 + activity_level * 2.5, 3.0, 8.0))
	for i in range(ship_count):
		var dir := 1.0 if i % 2 == 0 else -1.0
		var speed := 16.0 + i * 3.5
		var sx := fposmod(sim_time * speed * activity_level + i * 193.0, w + 250.0) - 130.0
		if dir < 0:
			sx = w - sx
		var sy := h * (0.62 + (i % 4) * 0.085)
		_draw_ship(Vector2(sx, sy), 0.62 + (i % 3) * 0.12, Color("#2a3035") if i % 2 == 0 else Color("#6b352e"), Color("#e6dac0"))
	for i in range(3):
		var tx := w - fposmod(sim_time * (37.0 + i * 7.0) * activity_level + i * 280.0, w + 100.0)
		var ty := h * (0.59 + i * 0.13)
		draw_rect(Rect2(tx, ty, 48, 12), Color("#9e4d35"))
		draw_rect(Rect2(tx + 15, ty - 13, 20, 13), Color("#e7dfc9"))
	for i in range(30):
		var yy := h * 0.585 + float(i % 13) * 20.0
		var xx := fposmod(float(i * 91) + sim_time * (10.0 + i % 4), w + 60.0) - 30.0
		draw_line(Vector2(xx, yy), Vector2(xx + 28 + (i % 4) * 7, yy), Color(0.72, 0.88, 0.9, 0.22), 2)
	draw_rect(Rect2(14, 14, 218, 48), Color(0.035, 0.07, 0.09, 0.86))
	draw_string(ThemeDB.fallback_font, Vector2(27, 35), selected_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f1d28a"))
	draw_string(ThemeDB.fallback_font, Vector2(27, 54), "LIVE PORT ACTIVITY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#9fc1cf"))

func _draw_smoke(origin:Vector2, seed:int) -> void:
	for j in range(4):
		var drift := fposmod(sim_time * (5.0 + seed * 0.1) + j * 13.0, 48.0)
		var p := origin + Vector2(drift * 0.35, -drift - j * 5.0)
		draw_circle(p, 5.0 + j * 1.5, Color(0.25, 0.27, 0.28, 0.24))

func _draw_crane(base:Vector2, seed:int) -> void:
	var swing := sin(sim_time * 0.75 + seed) * 11.0
	var gold := Color("#d4a43c")
	draw_line(base, base + Vector2(0, -72), gold, 6)
	draw_line(base + Vector2(0, -68), base + Vector2(52, -91), gold, 5)
	draw_line(base + Vector2(2, -68), base + Vector2(-18, -30), gold, 4)
	var hook_x := base.x + 36 + swing
	draw_line(base + Vector2(38, -84), Vector2(hook_x, base.y - 28), Color("#3b3330"), 2)
	draw_rect(Rect2(hook_x - 4, base.y - 29, 8, 8), Color("#2a2928"))

func _draw_ship(pos:Vector2, scale_v:float, hull:Color, cabin:Color) -> void:
	var s := scale_v
	var pts := PackedVector2Array([pos, pos + Vector2(118, 0) * s, pos + Vector2(100, 20) * s, pos + Vector2(18, 20) * s])
	draw_colored_polygon(pts, hull)
	draw_rect(Rect2(pos + Vector2(48, -20) * s, Vector2(42, 20) * s), cabin)
	draw_rect(Rect2(pos + Vector2(60, -34) * s, Vector2(9, 14) * s), Color("#7c3d2c"))
	draw_line(pos + Vector2(80, -20) * s, pos + Vector2(80, -44) * s, Color("#242729"), max(1.0, 2.0 * s))
	draw_line(pos + Vector2(-8, 15) * s, pos + Vector2(-38, 15) * s, Color(0.7,0.9,0.95,0.35), max(1.0,2.0*s))
