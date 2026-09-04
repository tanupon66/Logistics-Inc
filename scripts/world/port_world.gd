extends Node2D

signal selection_changed(kind: String, data: Dictionary)
signal camera_changed(zoom_value: float)

const PORT_ART = preload("res://assets/port_backdrop_v05.svg")
const LivingLayer = preload("res://scripts/world/living_port_layer.gd")

var camera: Camera2D
var art: Sprite2D
var living: Node2D
var night_tint: CanvasModulate
var zoom_value := 1.0
var touch_origin := Vector2.ZERO
var touch_moved := false
var mouse_dragging := false

var hotspots := {
	"ROYAL SHIPYARD": {"rect": Rect2(75,-105,260,165), "type":"shipyard", "level":1, "workers":42, "status":"Building merchant hull"},
	"EASTERN TRADING CO.": {"rect": Rect2(-280,-120,220,145), "type":"warehouse", "level":1, "capacity":800, "status":"Cargo handling"},
	"WAREHOUSE No.3": {"rect": Rect2(325,-95,190,135), "type":"warehouse", "level":1, "capacity":520, "status":"Leased storage"},
	"OLD DRY DOCK": {"rect": Rect2(235,65,235,130), "type":"dry_dock", "level":1, "status":"External repair yard"},
	"LIVERPOOL QUAY": {"rect": Rect2(-480,40,300,170), "type":"berth", "berths":2, "status":"Busy"}
}

func _ready() -> void:
	_build_world()
	set_process(true)

func _build_world() -> void:
	art = Sprite2D.new()
	art.texture = PORT_ART
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.position = Vector2.ZERO
	add_child(art)

	night_tint = CanvasModulate.new()
	night_tint.color = Color.WHITE
	add_child(night_tint)

	living = LivingLayer.new()
	add_child(living)

	camera = Camera2D.new()
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	add_child(camera)
	camera.make_current()
	set_zoom(1.0)

func _process(_delta: float) -> void:
	_update_lighting()

func _update_lighting() -> void:
	if GameState.world.is_empty():
		return
	var hour := int(GameState.world.get("hour", 8))
	var factor := 1.0
	if hour < 6 or hour >= 21:
		factor = 0.42
	elif hour < 8:
		factor = lerpf(0.52, 1.0, float(hour - 6) / 2.0)
	elif hour >= 18:
		factor = lerpf(1.0, 0.5, float(hour - 18) / 3.0)
	night_tint.color = Color(factor, factor * 0.98, min(1.0, factor * 1.08), 1.0)

func set_zoom(value: float) -> void:
	zoom_value = clampf(value, 0.82, 1.85)
	if camera != null:
		camera.zoom = Vector2(zoom_value, zoom_value)
	camera_changed.emit(zoom_value)

func zoom_by(delta: float) -> void:
	set_zoom(zoom_value + delta)

func reset_camera() -> void:
	if camera == null:
		return
	camera.position = Vector2.ZERO
	set_zoom(1.0)

func _clamp_camera() -> void:
	if camera == null:
		return
	camera.position.x = clampf(camera.position.x, -310.0, 310.0)
	camera.position.y = clampf(camera.position.y, -165.0, 170.0)

func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_origin = event.position
			touch_moved = false
		else:
			if not touch_moved and event.position.distance_to(touch_origin) < 18.0:
				_select_at_screen(event.position)
	elif event is InputEventScreenDrag:
		touch_moved = true
		camera.position -= event.relative / zoom_value
		_clamp_camera()
	elif event is InputEventMagnifyGesture:
		set_zoom(zoom_value * event.factor)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_dragging = event.pressed
			if not event.pressed:
				_select_at_screen(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_by(0.08)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_by(-0.08)
	elif event is InputEventMouseMotion and mouse_dragging:
		camera.position -= event.relative / zoom_value
		_clamp_camera()

func _select_at_screen(screen_pos: Vector2) -> void:
	var world_pos := get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	for key in hotspots.keys():
		var data: Dictionary = hotspots[key]
		var rect: Rect2 = data["rect"]
		if rect.has_point(world_pos):
			var payload := data.duplicate(true)
			payload.erase("rect")
			payload["name"] = key
			selection_changed.emit(str(key), payload)
			return
	selection_changed.emit("LIVERPOOL PORT", {
		"name":"Liverpool Port",
		"type":"port",
		"year":int(GameState.world.get("year",1750)),
		"berths":int(GameState.ports.get("port_liverpool",{}).get("berths",2)),
		"status":"Harbor operating normally"
	})