extends Node2D

signal selection_changed(kind:String,data:Dictionary)
signal camera_changed(zoom_value:float)

const PORT_ART=preload("res://assets/port_backdrop_v05.svg")
const LivingLayer=preload("res://scripts/world/living_port_layer_v061.gd")

var camera:Camera2D
var art:Sprite2D
var living:Node2D
var night_tint:CanvasModulate
var zoom_value:float=1.0
var touch_origin:=Vector2.ZERO
var touch_moved:=false
var mouse_dragging:=false

var hotspots:Dictionary={
	"ROYAL SHIPYARD":{"rect":Rect2(75,-105,260,165),"facility_id":"facility_royal_shipyard","type":"shipyard"},
	"EASTERN TRADING CO.":{"rect":Rect2(-280,-120,220,145),"facility_id":"facility_eastern_warehouse","type":"warehouse"},
	"WAREHOUSE No.3":{"rect":Rect2(325,-95,190,135),"facility_id":"facility_warehouse_3","type":"warehouse"},
	"OLD DRY DOCK":{"rect":Rect2(235,65,235,130),"facility_id":"facility_old_dry_dock","type":"dry_dock"},
	"LIVERPOOL QUAY":{"rect":Rect2(-480,40,300,170),"facility_id":"facility_liverpool_quay","type":"berth"}
}

func _ready() -> void:
	_build_world()
	set_process(true)

func _build_world() -> void:
	art=Sprite2D.new()
	art.texture=PORT_ART
	art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	art.position=Vector2.ZERO
	add_child(art)
	night_tint=CanvasModulate.new()
	night_tint.color=Color.WHITE
	add_child(night_tint)
	living=LivingLayer.new()
	add_child(living)
	camera=Camera2D.new()
	camera.position=Vector2.ZERO
	camera.zoom=Vector2.ONE
	camera.position_smoothing_enabled=true
	camera.position_smoothing_speed=10.0
	add_child(camera)
	camera.make_current()
	set_zoom(1.0)

func _process(_delta:float) -> void:
	_update_lighting()

func _update_lighting() -> void:
	if GameState.world.is_empty(): return
	var hour:=int(GameState.world.get("hour",8))
	var factor:=1.0
	if hour<6 or hour>=21:
		factor=.42
	elif hour<8:
		factor=lerpf(.52,1.0,float(hour-6)/2.0)
	elif hour>=18:
		factor=lerpf(1.0,.5,float(hour-18)/3.0)
	night_tint.color=Color(factor,factor*.98,minf(1.0,factor*1.08),1.0)

func set_zoom(value:float) -> void:
	zoom_value=clampf(value,.82,1.85)
	if camera!=null: camera.zoom=Vector2(zoom_value,zoom_value)
	camera_changed.emit(zoom_value)

func zoom_by(delta:float) -> void:
	set_zoom(zoom_value+delta)

func reset_camera() -> void:
	if camera==null: return
	camera.position=Vector2.ZERO
	set_zoom(1.0)

func _clamp_camera() -> void:
	if camera==null: return
	camera.position.x=clampf(camera.position.x,-310.0,310.0)
	camera.position.y=clampf(camera.position.y,-165.0,170.0)

func _unhandled_input(event:InputEvent) -> void:
	if camera==null: return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_origin=event.position
			touch_moved=false
		else:
			if not touch_moved and event.position.distance_to(touch_origin)<18.0:
				_select_at_screen(event.position)
	elif event is InputEventScreenDrag:
		touch_moved=true
		camera.position-=event.relative/zoom_value
		_clamp_camera()
	elif event is InputEventMagnifyGesture:
		set_zoom(zoom_value*event.factor)
	elif event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			mouse_dragging=event.pressed
			if not event.pressed: _select_at_screen(event.position)
		elif event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_by(.08)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_by(-.08)
	elif event is InputEventMouseMotion and mouse_dragging:
		camera.position-=event.relative/zoom_value
		_clamp_camera()

func _facility_payload(name:String,meta:Dictionary) -> Dictionary:
	var facility_id:=str(meta.get("facility_id",""))
	var facility:Dictionary=GameState.facilities.get(facility_id,{}).duplicate(true)
	facility["name"]=name
	facility["type"]=str(meta.get("type",facility.get("type","facility")))
	var leased:Array=GameState.player_company.get("leased_facility_ids",[])
	if facility_id in leased:
		facility["status"]="Leased by TCH Maritime Co. — activity increased"
	elif facility_id=="facility_liverpool_quay":
		facility["status"]="Public quay — lease it to speed cargo loading"
	elif facility_id=="facility_warehouse_3":
		facility["status"]="Available warehouse — lease it for faster cargo handling"
	return facility

func _select_at_screen(screen_pos:Vector2) -> void:
	var world_pos:=get_viewport().get_canvas_transform().affine_inverse()*screen_pos
	for key in hotspots.keys():
		var meta:Dictionary=hotspots[key]
		var rect:Rect2=meta["rect"]
		if rect.has_point(world_pos):
			selection_changed.emit(str(key),_facility_payload(str(key),meta))
			return
	selection_changed.emit("LIVERPOOL PORT",{
		"name":"Liverpool Port",
		"type":"port",
		"year":int(GameState.world.get("year",1750)),
		"berths":int(GameState.ports.get("port_liverpool",{}).get("berths",2)),
		"status":"Harbor operating — vessels, cargo carts and dock labor continue while management panels are open"
	})
