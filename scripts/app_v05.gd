extends Control

const PortWorld = preload("res://scripts/world/port_world.gd")
const HudV05 = preload("res://scripts/ui/hud_v05.gd")
const SPLASH = preload("res://assets/studio_splash.png")

var world
var hud

func _ready() -> void:
	get_window().mode = Window.MODE_FULLSCREEN
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_window().content_scale_size = Vector2i(1280,720)
	if GameState.world.is_empty():
		GameState.new_game()
	_show_studio_intro()

func _show_studio_intro() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color("#020508")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var logo := TextureRect.new()
	logo.texture = SPLASH
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo.modulate.a = 0.0
	overlay.add_child(logo)
	var tw := create_tween()
	tw.tween_property(logo,"modulate:a",1.0,0.35)
	tw.tween_interval(0.45)
	tw.tween_property(overlay,"modulate:a",0.0,0.35)
	tw.finished.connect(func(): overlay.queue_free(); _enter_port())

func _enter_port() -> void:
	world = PortWorld.new()
	add_child(world)
	hud = HudV05.new()
	add_child(hud)
	world.selection_changed.connect(hud.set_selection)
	hud.speed_requested.connect(_set_speed)
	hud.zoom_requested.connect(world.zoom_by)
	hud.reset_camera_requested.connect(world.reset_camera)
	TimeSystem.set_speed(1)
	hud.show_message("Liverpool, 1750 — drag to explore the living harbor. Tap a facility for details.")

func _set_speed(value: int) -> void:
	TimeSystem.set_speed(value)