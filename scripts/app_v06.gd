extends Control

const PortWorld=preload("res://scripts/world/port_world_v061.gd")
const WorldMapView=preload("res://scripts/world/world_map_view.gd")
const HudV06=preload("res://scripts/ui/hud_v06.gd")
const VoyageStatusOverlay=preload("res://scripts/ui/voyage_status_overlay.gd")
const SPLASH=preload("res://assets/studio_splash.png")

var port_world
var world_map
var status_overlay
var hud

func _ready() -> void:
	get_window().mode=Window.MODE_FULLSCREEN
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	get_window().content_scale_size=Vector2i(1280,720)
	if GameState.world.is_empty(): GameState.new_game()
	_show_studio_intro()

func _show_studio_intro() -> void:
	var overlay:=ColorRect.new()
	overlay.color=Color("#020508")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var logo:=TextureRect.new()
	logo.texture=SPLASH
	logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo.modulate.a=0.0
	overlay.add_child(logo)
	var tw:=create_tween()
	tw.tween_property(logo,"modulate:a",1.0,.3)
	tw.tween_interval(.35)
	tw.tween_property(overlay,"modulate:a",0.0,.3)
	tw.finished.connect(func(): overlay.queue_free(); _enter_game())

func _enter_game() -> void:
	port_world=PortWorld.new()
	add_child(port_world)
	world_map=WorldMapView.new()
	world_map.visible=false
	add_child(world_map)
	status_overlay=VoyageStatusOverlay.new()
	add_child(status_overlay)
	hud=HudV06.new()
	add_child(hud)
	port_world.selection_changed.connect(hud.set_selection)
	hud.speed_requested.connect(TimeSystem.set_speed)
	hud.zoom_requested.connect(port_world.zoom_by)
	hud.reset_camera_requested.connect(port_world.reset_camera)
	hud.view_requested.connect(_switch_view)
	TimeSystem.set_speed(1)
	hud.show_message("Liverpool, 1750 — cargo now loads visibly at the berth. Lease quay/warehouse space to accelerate operations.")

func _switch_view(view_name:String) -> void:
	if view_name=="world":
		port_world.visible=false
		world_map.visible=true
	else:
		world_map.visible=false
		port_world.visible=true
