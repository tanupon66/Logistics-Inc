extends Control

const MAP_ART = preload("res://assets/world_map_v05.svg")

var map_rect := Rect2(175,85,930,540)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func _process(_delta:float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#061119"),true)
	var tex_size := MAP_ART.get_size()
	var scale_v := minf(map_rect.size.x/tex_size.x,map_rect.size.y/tex_size.y)
	var dest_size := tex_size*scale_v
	var dest := Rect2(map_rect.position+(map_rect.size-dest_size)*0.5,dest_size)
	draw_texture_rect(MAP_ART,dest,false)
	_draw_title()
	_draw_active_voyages(dest)

func _draw_title() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(175,72),"WORLD TRADE — 1750",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("#e8c770"))

func _map_point(port_id:String,dest:Rect2) -> Vector2:
	var source := Vector2(900,520)
	var port:Dictionary = GameState.ports.get(port_id,{})
	var p:Vector2 = port.get("map_pos",Vector2(430,120))
	return dest.position+Vector2(p.x/source.x*dest.size.x,p.y/source.y*dest.size.y)

func _draw_active_voyages(dest:Rect2) -> void:
	for voyage_id in GameState.voyages.keys():
		var voyage:Dictionary = GameState.voyages[voyage_id]
		if str(voyage.get("status","")) != "en_route":
			continue
		var a := _map_point(str(voyage.get("origin_port_id","")),dest)
		var b := _map_point(str(voyage.get("destination_port_id","")),dest)
		draw_dashed_line(a,b,Color("#e3c55f"),2.0,8.0)
		var progress := float(voyage.get("progress",0.0))
		var pos := a.lerp(b,progress)
		draw_circle(pos,8.0,Color("#f2d16f"))
		draw_circle(pos,4.0,Color("#14384b"))
		var ship_id := str(voyage.get("ship_id",""))
		var ship:Dictionary = GameState.ships.get(ship_id,{})
		draw_string(ThemeDB.fallback_font,pos+Vector2(12,-8),str(ship.get("name","Vessel")),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#f4e5bd"))
		var pct := int(round(progress*100.0))
		draw_string(ThemeDB.fallback_font,pos+Vector2(12,8),"%d%%"%pct,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#8fdb9d"))
