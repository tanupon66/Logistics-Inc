extends Control

const MapViewScript = preload("res://scripts/map_view.gd")

var ports = {
	"Laem Chabang": {"lat": 13.05794, "lon": 100.89191, "country": "Thailand"},
	"Bangkok Port": {"lat": 13.7077, "lon": 100.5750, "country": "Thailand"},
	"Map Ta Phut": {"lat": 12.6755, "lon": 101.1546, "country": "Thailand"},
	"Singapore": {"lat": 1.2644, "lon": 103.8200, "country": "Singapore"},
	"Port Klang": {"lat": 3.0028, "lon": 101.3967, "country": "Malaysia"},
	"Tanjung Pelepas": {"lat": 1.3620, "lon": 103.5500, "country": "Malaysia"},
	"Cat Lai": {"lat": 10.75848, "lon": 106.78471, "country": "Vietnam"},
	"Sihanoukville": {"lat": 10.6297, "lon": 103.5226, "country": "Cambodia"},
	"Hai Phong": {"lat": 20.8449, "lon": 106.6881, "country": "Vietnam"}
}

var contracts = [
	{"from":"Laem Chabang", "to":"Singapore", "cargo":"Electronics • 148 TEU", "reward":84000.0},
	{"from":"Laem Chabang", "to":"Port Klang", "cargo":"Auto parts • 126 TEU", "reward":69000.0},
	{"from":"Laem Chabang", "to":"Cat Lai", "cargo":"Industrial machinery • 92 TEU", "reward":76000.0}
]

var money := 500000.0
var fuel := 100.0
var max_speed_knots := 18.0
var throttle := 0.0
var heading := 180.0
var autopilot := true
var active_contract = null
var selected_contract := 0
var ship_lat := 13.05794
var ship_lon := 100.89191
var total_distance_nm := 0.0

var map_view
var money_label: Label
var status_label: Label
var contract_label: Label
var mode_label: Label
var fuel_bar: ProgressBar
var throttle_label: Label
var helm_panel: PanelContainer
var contract_buttons = []

func _ready():
	set_process(true)
	_build_ui()
	_update_contract_panel()
	_update_status()

func _build_ui():
	var bg = ColorRect.new()
	bg.color = Color("#07131e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	map_view = MapViewScript.new()
	map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_view.anchor_left = 0.275
	map_view.anchor_top = 0.105
	map_view.anchor_right = 0.995
	map_view.anchor_bottom = 0.89
	map_view.offset_left = 0
	map_view.offset_top = 0
	map_view.offset_right = 0
	map_view.offset_bottom = 0
	map_view.set_ports(ports)
	map_view.set_ship_position(ship_lat, ship_lon)
	map_view.port_tapped.connect(_on_port_tapped)
	add_child(map_view)

	var top = PanelContainer.new()
	top.anchor_left = 0.0
	top.anchor_top = 0.0
	top.anchor_right = 1.0
	top.anchor_bottom = 0.095
	top.add_theme_stylebox_override("panel", _style(Color("#102637"), 14))
	add_child(top)

	var top_box = HBoxContainer.new()
	top_box.add_theme_constant_override("separation", 22)
	top.add_child(top_box)

	var title = _label("LOGISTICS INC", 28, Color("#eaf7ff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_box.add_child(title)

	var ship = _label("MV SIAM VENTURE  •  Feeder 320 TEU", 16, Color("#8fb3c9"))
	ship.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_box.add_child(ship)

	money_label = _label("", 20, Color("#78e6be"))
	top_box.add_child(money_label)

	var side = PanelContainer.new()
	side.anchor_left = 0.008
	side.anchor_top = 0.105
	side.anchor_right = 0.265
	side.anchor_bottom = 0.985
	side.add_theme_stylebox_override("panel", _style(Color("#0d2130"), 16))
	add_child(side)

	var side_box = VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 10)
	side.add_child(side_box)

	side_box.add_child(_label("CONTRACT MARKET", 18, Color("#7de8ff")))
	contract_label = _label("", 16, Color.WHITE)
	contract_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contract_label.custom_minimum_size = Vector2(0, 120)
	side_box.add_child(contract_label)

	for i in range(contracts.size()):
		var c = contracts[i]
		var b = _button("%s → %s" % [c["from"], c["to"]])
		b.pressed.connect(_select_contract.bind(i))
		side_box.add_child(b)
		contract_buttons.append(b)

	var accept = _button("ACCEPT CONTRACT")
	accept.pressed.connect(_accept_contract)
	side_box.add_child(accept)

	side_box.add_child(HSeparator.new())
	side_box.add_child(_label("CAPTAIN MODE", 18, Color("#7de8ff")))

	var auto_btn = _button("AUTO CAPTAIN")
	auto_btn.pressed.connect(_set_auto_captain)
	side_box.add_child(auto_btn)

	var manual_btn = _button("TAKE COMMAND")
	manual_btn.pressed.connect(_take_command)
	side_box.add_child(manual_btn)

	mode_label = _label("", 15, Color("#ffd166"))
	side_box.add_child(mode_label)

	side_box.add_child(HSeparator.new())
	side_box.add_child(_label("FUEL", 16, Color("#8fb3c9")))
	fuel_bar = ProgressBar.new()
	fuel_bar.min_value = 0
	fuel_bar.max_value = 100
	fuel_bar.value = fuel
	fuel_bar.show_percentage = true
	fuel_bar.custom_minimum_size = Vector2(0, 28)
	side_box.add_child(fuel_bar)

	var bottom = PanelContainer.new()
	bottom.anchor_left = 0.275
	bottom.anchor_top = 0.90
	bottom.anchor_right = 0.995
	bottom.anchor_bottom = 0.985
	bottom.add_theme_stylebox_override("panel", _style(Color("#0d2130"), 14))
	add_child(bottom)

	status_label = _label("", 16, Color("#d8ecf7"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(status_label)

	helm_panel = PanelContainer.new()
	helm_panel.anchor_left = 0.42
	helm_panel.anchor_top = 0.70
	helm_panel.anchor_right = 0.93
	helm_panel.anchor_bottom = 0.87
	helm_panel.add_theme_stylebox_override("panel", _style(Color(0.04,0.10,0.15,0.94), 16))
	helm_panel.visible = false
	add_child(helm_panel)

	var helm_box = HBoxContainer.new()
	helm_box.add_theme_constant_override("separation", 10)
	helm_panel.add_child(helm_box)

	var left = _button("◀ RUDDER")
	left.pressed.connect(_rudder_left)
	helm_box.add_child(left)

	var down = _button("− THROTTLE")
	down.pressed.connect(_throttle_down)
	helm_box.add_child(down)

	throttle_label = _label("0%", 18, Color("#78e6be"))
	throttle_label.custom_minimum_size = Vector2(70, 0)
	throttle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	helm_box.add_child(throttle_label)

	var up = _button("+ THROTTLE")
	up.pressed.connect(_throttle_up)
	helm_box.add_child(up)

	var right = _button("RUDDER ▶")
	right.pressed.connect(_rudder_right)
	helm_box.add_child(right)

func _style(color, radius):
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func _label(text, font_size, color):
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _button(text):
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 15)
	return b

func _select_contract(index):
	selected_contract = index
	_update_contract_panel()

func _update_contract_panel():
	var c = contracts[selected_contract]
	contract_label.text = "%s\n%s → %s\nReward  ฿%s" % [c["cargo"], c["from"], c["to"], _money(c["reward"])]
	for i in range(contract_buttons.size()):
		contract_buttons[i].disabled = active_contract != null
		contract_buttons[i].text = ("%s  %s → %s" % ["●" if i == selected_contract else "○", contracts[i]["from"], contracts[i]["to"]])

func _accept_contract():
	if active_contract != null:
		return
	var c = contracts[selected_contract]
	if _distance_nm(ship_lat, ship_lon, ports[c["from"]]["lat"], ports[c["from"]]["lon"]) > 8.0:
		_show_message("Ship must be at %s to accept this contract." % c["from"])
		return
	active_contract = c.duplicate(true)
	var target = ports[active_contract["to"]]
	map_view.set_target(target["lat"], target["lon"], true)
	heading = _bearing_to(target["lat"], target["lon"])
	throttle = 0.65
	autopilot = true
	helm_panel.visible = false
	_update_contract_panel()
	_show_message("Cargo loaded. Auto Captain ready for departure.")

func _set_auto_captain():
	autopilot = true
	helm_panel.visible = false
	if active_contract != null:
		throttle = max(throttle, 0.65)
	mode_label.text = "AUTO CAPTAIN • route guidance active"
	_update_status()

func _take_command():
	autopilot = false
	helm_panel.visible = true
	if active_contract != null and throttle < 0.20:
		throttle = 0.40
	mode_label.text = "MANUAL HELM • you control heading & throttle"
	_update_status()

func _rudder_left():
	heading = fposmod(heading - 7.5, 360.0)
	_update_status()

func _rudder_right():
	heading = fposmod(heading + 7.5, 360.0)
	_update_status()

func _throttle_up():
	throttle = clamp(throttle + 0.10, 0.0, 1.0)
	_update_status()

func _throttle_down():
	throttle = clamp(throttle - 0.10, 0.0, 1.0)
	_update_status()

func _process(delta):
	if active_contract == null:
		return
	if fuel <= 0.0:
		throttle = 0.0
		return
	var target = ports[active_contract["to"]]
	if autopilot:
		var desired = _bearing_to(target["lat"], target["lon"])
		heading = _approach_angle(heading, desired, 18.0 * delta)
		throttle = 0.72
	var speed = max_speed_knots * throttle
	if speed <= 0.01:
		_update_status()
		return
	var travel_nm = speed * delta * 0.5
	var next = _destination_point(ship_lat, ship_lon, heading, travel_nm)
	ship_lat = next.x
	ship_lon = next.y
	total_distance_nm += travel_nm
	fuel = max(0.0, fuel - travel_nm * 0.018 * (0.75 + throttle * 0.45))
	map_view.set_ship_position(ship_lat, ship_lon)
	var remaining = _distance_nm(ship_lat, ship_lon, target["lat"], target["lon"])
	if remaining <= 4.0:
		_complete_contract()
	_update_status()

func _complete_contract():
	money += active_contract["reward"]
	ship_lat = ports[active_contract["to"]]["lat"]
	ship_lon = ports[active_contract["to"]]["lon"]
	map_view.set_ship_position(ship_lat, ship_lon)
	map_view.clear_target()
	var delivered_to = active_contract["to"]
	active_contract = null
	throttle = 0.0
	fuel = min(100.0, fuel + 8.0)
	helm_panel.visible = false
	_show_message("Delivered successfully at %s. Payment received." % delivered_to)
	_update_contract_panel()
	_update_status()

func _on_port_tapped(port_name):
	var p = ports[port_name]
	_show_message("%s • %s\n%.4f° N, %.4f° E" % [port_name, p["country"], p["lat"], p["lon"]])

func _update_status():
	money_label.text = "CASH  ฿%s" % _money(money)
	fuel_bar.value = fuel
	mode_label.text = ("AUTO CAPTAIN" if autopilot else "MANUAL HELM") + (" • ACTIVE" if active_contract != null else " • IDLE")
	if throttle_label:
		throttle_label.text = "%d%%" % int(round(throttle * 100.0))
	var speed = max_speed_knots * throttle
	var destination = "No active contract"
	var distance_text = ""
	if active_contract != null:
		var target = ports[active_contract["to"]]
		var remaining = _distance_nm(ship_lat, ship_lon, target["lat"], target["lon"])
		destination = "DEST  %s" % active_contract["to"]
		distance_text = "  •  %.0f nm remaining" % remaining
	status_label.text = "%s%s  •  HDG %03d°  •  %.1f kn  •  Fuel %.0f%%  •  Pos %.3f, %.3f" % [destination, distance_text, int(round(heading)), speed, fuel, ship_lat, ship_lon]

func _show_message(text):
	contract_label.text = text
	await get_tree().create_timer(2.2).timeout
	if is_instance_valid(contract_label):
		_update_contract_panel()

func _money(value):
	var s = "%d" % int(round(value))
	var out = ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func _distance_nm(lat1, lon1, lat2, lon2):
	var r = 3440.065
	var p1 = deg_to_rad(float(lat1))
	var p2 = deg_to_rad(float(lat2))
	var dp = deg_to_rad(float(lat2) - float(lat1))
	var dl = deg_to_rad(float(lon2) - float(lon1))
	var a = sin(dp / 2.0) * sin(dp / 2.0) + cos(p1) * cos(p2) * sin(dl / 2.0) * sin(dl / 2.0)
	var c = 2.0 * atan2(sqrt(a), sqrt(max(0.0, 1.0 - a)))
	return r * c

func _bearing_to(lat2, lon2):
	var p1 = deg_to_rad(ship_lat)
	var p2 = deg_to_rad(float(lat2))
	var dl = deg_to_rad(float(lon2) - ship_lon)
	var y = sin(dl) * cos(p2)
	var x = cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dl)
	return fposmod(rad_to_deg(atan2(y, x)), 360.0)

func _approach_angle(current, target, max_delta):
	var diff = fposmod(target - current + 540.0, 360.0) - 180.0
	if abs(diff) <= max_delta:
		return target
	return fposmod(current + sign(diff) * max_delta, 360.0)

func _destination_point(lat, lon, bearing_deg, distance_nm):
	var r = 3440.065
	var d = distance_nm / r
	var lat1 = deg_to_rad(lat)
	var lon1 = deg_to_rad(lon)
	var b = deg_to_rad(bearing_deg)
	var lat2 = asin(sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(b))
	var lon2 = lon1 + atan2(sin(b) * sin(d) * cos(lat1), cos(d) - sin(lat1) * sin(lat2))
	return Vector2(rad_to_deg(lat2), fposmod(rad_to_deg(lon2) + 540.0, 360.0) - 180.0)
