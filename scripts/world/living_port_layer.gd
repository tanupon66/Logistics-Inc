extends Node2D

var t: float = 0.0
var activity: float = 1.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 1750
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	_draw_water_motion()
	_draw_smoke()
	_draw_birds()
	_draw_harbor_traffic()
	_draw_carts()

func _draw_water_motion() -> void:
	for row in range(9):
		var y := 55.0 + float(row) * 38.0
		for i in range(12):
			var phase := t * (14.0 + row) + float(i * 37 + row * 11)
			var x := -610.0 + float(i) * 112.0 + fmod(phase, 70.0)
			var len := 18.0 + float((i + row) % 4) * 5.0
			draw_line(Vector2(x, y), Vector2(x + len, y + sin(phase * 0.08) * 2.0), Color(0.65, 0.9, 0.95, 0.22), 1.0)

func _draw_smoke() -> void:
	var stacks := [Vector2(-455,-220), Vector2(230,-215), Vector2(438,-190), Vector2(505,-165)]
	for s in stacks:
		for i in range(5):
			var age := fmod(t * 0.52 + float(i) * 0.19, 1.0)
			var drift := Vector2(age * 26.0, -age * 58.0)
			var wobble := Vector2(sin(t * 1.7 + i) * 5.0 * age, 0)
			var radius := 4.0 + age * 9.0
			draw_circle(s + drift + wobble, radius, Color(0.72, 0.72, 0.69, 0.25 * (1.0 - age)))

func _draw_birds() -> void:
	for i in range(7):
		var x := -520.0 + fmod(t * (22.0 + i * 2.0) + i * 165.0, 1080.0)
		var y := -245.0 + sin(t * 0.8 + i) * 18.0 + float(i % 3) * 20.0
		var p := Vector2(x, y)
		draw_line(p + Vector2(-6,1), p, Color(0.15,0.17,0.16,0.8), 1.5)
		draw_line(p, p + Vector2(6,1), Color(0.15,0.17,0.16,0.8), 1.5)

func _draw_harbor_traffic() -> void:
	var lanes := [
		[Vector2(-620,245), Vector2(620,140), 0.022, 0],
		[Vector2(600,305), Vector2(-560,175), 0.017, 1],
		[Vector2(-500,310), Vector2(520,245), 0.013, 2]
	]
	for lane in lanes:
		var a: Vector2 = lane[0]
		var b: Vector2 = lane[1]
		var speed: float = lane[2]
		var idx: int = lane[3]
		var u := fmod(t * speed + float(idx) * 0.31, 1.0)
		var pos := a.lerp(b, u)
		_draw_sloop(pos, b - a, 0.72 if idx != 1 else 0.55)

func _draw_sloop(pos: Vector2, direction: Vector2, scale_v: float) -> void:
	var d := direction.normalized()
	var n := Vector2(-d.y, d.x)
	var hull := PackedVector2Array([
		pos - d * 30.0 * scale_v - n * 7.0 * scale_v,
		pos + d * 31.0 * scale_v,
		pos - d * 30.0 * scale_v + n * 7.0 * scale_v,
		pos - d * 37.0 * scale_v
	])
	draw_colored_polygon(hull, Color("#51301f"))
	var mast := pos - d * 2.0 * scale_v
	draw_line(mast, mast - n * 33.0 * scale_v, Color("#31241b"), max(1.0, 2.0 * scale_v))
	var tip := mast - n * 31.0 * scale_v
	var sail := PackedVector2Array([tip, mast - n * 4.0 * scale_v - d * 4.0 * scale_v, tip + d * 19.0 * scale_v + n * 10.0 * scale_v])
	draw_colored_polygon(sail, Color(0.93,0.87,0.72,0.92))
	for i in range(3):
		var wake_start := pos - d * (35.0 + i * 6.0) * scale_v
		draw_line(wake_start - n * (7.0 + i * 3.0) * scale_v, wake_start - d * 18.0 * scale_v - n * (12.0 + i * 4.0) * scale_v, Color(0.85,0.95,1,0.35), 1.0)

func _draw_carts() -> void:
	var road_y := -78.0
	for i in range(5):
		var u := fmod(t * (0.027 + i * 0.002) + i * 0.21, 1.0)
		var x := lerpf(-570.0, 520.0, u)
		var y := road_y - x * 0.045 + float(i % 2) * 16.0
		_draw_cart(Vector2(x,y), 0.62)

func _draw_cart(pos: Vector2, k: float) -> void:
	draw_rect(Rect2(pos, Vector2(22,9) * k), Color("#694629"))
	draw_circle(pos + Vector2(5,11) * k, 3.0 * k, Color("#26211b"))
	draw_circle(pos + Vector2(18,11) * k, 3.0 * k, Color("#26211b"))
	draw_line(pos + Vector2(22,4) * k, pos + Vector2(34,1) * k, Color("#4c3826"), 1.5)
	draw_circle(pos + Vector2(38,1) * k, 4.0 * k, Color("#795438"))