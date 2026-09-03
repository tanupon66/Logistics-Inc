extends Control

signal port_tapped(port_name)

const TILE_SIZE := 256.0
const TILE_ZOOM := 5

var ports = {}
var ship_lat := 13.05794
var ship_lon := 100.89191
var target_lat := 13.05794
var target_lon := 100.89191
var route_active := false
var center_lat := 8.5
var center_lon := 104.0

var tile_textures = {}
var tile_queue = []
var current_tile = Vector2i(-1, -1)
var request_busy := false
var http: HTTPRequest

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_tile_request_completed)
	resized.connect(_on_resized)
	call_deferred("_refresh_tiles")

func set_ports(value):
	ports = value
	queue_redraw()

func set_ship_position(lat, lon):
	ship_lat = lat
	ship_lon = lon
	queue_redraw()

func set_target(lat, lon, active := true):
	target_lat = lat
	target_lon = lon
	route_active = active
	queue_redraw()

func clear_target():
	route_active = false
	queue_redraw()

func _on_resized():
	_refresh_tiles()
	queue_redraw()

func _process(_delta):
	if not request_busy and tile_queue.size() > 0:
		_request_next_tile()

func _refresh_tiles():
	if size.x < 10.0 or size.y < 10.0:
		return
	var center_world = _geo_to_world(center_lat, center_lon)
	var half_x = int(ceil(size.x / TILE_SIZE / 2.0)) + 1
	var half_y = int(ceil(size.y / TILE_SIZE / 2.0)) + 1
	var cx = int(floor(center_world.x))
	var cy = int(floor(center_world.y))
	var n = 1 << TILE_ZOOM
	for y in range(cy - half_y, cy + half_y + 1):
		if y < 0 or y >= n:
			continue
		for x_raw in range(cx - half_x, cx + half_x + 1):
			var x = posmod(x_raw, n)
			var key = Vector2i(x, y)
			if tile_textures.has(key) or tile_queue.has(key):
				continue
			var path = _tile_cache_path(key)
			if FileAccess.file_exists(path):
				var img = Image.new()
				var err = img.load(path)
				if err == OK:
					tile_textures[key] = ImageTexture.create_from_image(img)
					continue
			tile_queue.append(key)

func _request_next_tile():
	if tile_queue.is_empty():
		return
	current_tile = tile_queue.pop_front()
	var url = "https://tile.openstreetmap.org/%d/%d/%d.png" % [TILE_ZOOM, current_tile.x, current_tile.y]
	var headers = PackedStringArray([
		"User-Agent: LogisticsIncPrototype/0.1 (+https://github.com/tanupon66/Logistics-Inc)"
	])
	request_busy = true
	var err = http.request(url, headers)
	if err != OK:
		request_busy = false
		current_tile = Vector2i(-1, -1)

func _on_tile_request_completed(result, response_code, _headers, body):
	request_busy = false
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200 and current_tile.x >= 0:
		var img = Image.new()
		var err = img.load_png_from_buffer(body)
		if err == OK:
			tile_textures[current_tile] = ImageTexture.create_from_image(img)
			var file = FileAccess.open(_tile_cache_path(current_tile), FileAccess.WRITE)
			if file:
				file.store_buffer(body)
			queue_redraw()
	current_tile = Vector2i(-1, -1)

func _tile_cache_path(tile):
	return "user://osm_%d_%d_%d.png" % [TILE_ZOOM, tile.x, tile.y]

func _geo_to_world(lat, lon):
	var n = float(1 << TILE_ZOOM)
	var x = (lon + 180.0) / 360.0 * n
	var lat_clamped = clamp(lat, -85.05112878, 85.05112878)
	var rad = deg_to_rad(lat_clamped)
	var y = (1.0 - log(tan(rad) + 1.0 / cos(rad)) / PI) / 2.0 * n
	return Vector2(x, y)

func geo_to_screen(lat, lon):
	var p = _geo_to_world(lat, lon)
	var center_world = _geo_to_world(center_lat, center_lon)
	var n = float(1 << TILE_ZOOM)
	var dx = p.x - center_world.x
	if dx > n * 0.5:
		dx -= n
	elif dx < -n * 0.5:
		dx += n
	return Vector2(dx * TILE_SIZE + size.x * 0.5, (p.y - center_world.y) * TILE_SIZE + size.y * 0.5)

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color("#09283a"))
	var center_world = _geo_to_world(center_lat, center_lon)
	var n = 1 << TILE_ZOOM
	var half_x = int(ceil(size.x / TILE_SIZE / 2.0)) + 1
	var half_y = int(ceil(size.y / TILE_SIZE / 2.0)) + 1
	var cx = int(floor(center_world.x))
	var cy = int(floor(center_world.y))
	for y in range(cy - half_y, cy + half_y + 1):
		if y < 0 or y >= n:
			continue
		for x_raw in range(cx - half_x, cx + half_x + 1):
			var x = posmod(x_raw, n)
			var key = Vector2i(x, y)
			if not tile_textures.has(key):
				continue
			var pos = Vector2((float(x_raw) - center_world.x) * TILE_SIZE + size.x * 0.5, (float(y) - center_world.y) * TILE_SIZE + size.y * 0.5)
			draw_texture_rect(tile_textures[key], Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), false)

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.06, 0.10, 0.18))

	if route_active:
		var a = geo_to_screen(ship_lat, ship_lon)
		var b = geo_to_screen(target_lat, target_lon)
		draw_dashed_line(a, b, Color("#7de8ff"), 3.0, 12.0)

	for port_name in ports:
		var p = ports[port_name]
		var pos = geo_to_screen(float(p["lat"]), float(p["lon"]))
		if pos.x < -80 or pos.y < -30 or pos.x > size.x + 80 or pos.y > size.y + 30:
			continue
		draw_circle(pos, 8.0, Color("#ffd166"))
		draw_circle(pos, 4.0, Color("#152536"))
		draw_string(ThemeDB.fallback_font, pos + Vector2(11, -7), port_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

	var sp = geo_to_screen(ship_lat, ship_lon)
	var hull = PackedVector2Array([sp + Vector2(0, -14), sp + Vector2(10, 10), sp + Vector2(0, 6), sp + Vector2(-10, 10)])
	draw_colored_polygon(hull, Color("#38d9c5"))
	draw_polyline(PackedVector2Array([hull[0], hull[1], hull[2], hull[3], hull[0]]), Color.WHITE, 2.0)

	var attr = "© OpenStreetMap contributors"
	var text_size = ThemeDB.fallback_font.get_string_size(attr, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_rect(Rect2(Vector2(size.x - text_size.x - 16, size.y - 26), Vector2(text_size.x + 12, 22)), Color(0,0,0,0.55))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - text_size.x - 10, size.y - 10), attr, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func _gui_input(event):
	var click_pos = Vector2.ZERO
	var clicked = false
	if event is InputEventScreenTouch and event.pressed:
		click_pos = event.position
		clicked = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_pos = event.position
		clicked = true
	if not clicked:
		return
	for port_name in ports:
		var p = ports[port_name]
		var pos = geo_to_screen(float(p["lat"]), float(p["lon"]))
		if click_pos.distance_to(pos) <= 28.0:
			port_tapped.emit(port_name)
			accept_event()
			return
