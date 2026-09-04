extends CanvasLayer

var panel:PanelContainer
var title:Label
var body:Label
var refresh_clock:float = 0.0
var flash_clock:float = 0.0
var flash_text:String = ""

func _ready() -> void:
	_build_ui()
	EventBus.cargo_loading_started.connect(func(ship_id:String,_contract_id:String): _flash(_ship_name(ship_id)+" loading cargo"))
	EventBus.cargo_loading_completed.connect(func(ship_id:String): _flash(_ship_name(ship_id)+" ready to sail"))
	EventBus.vessel_departed.connect(func(ship_id:String,_a:String,_b:String): _flash(_ship_name(ship_id)+" departed"))
	EventBus.vessel_arrived.connect(func(ship_id:String,_port:String): _flash(_ship_name(ship_id)+" arrived"))
	EventBus.cargo_claim_paid.connect(func(ship_id:String,amount:float,_condition:float): _flash(_ship_name(ship_id)+" cargo claim £%d"%int(amount)))
	set_process(true)
	_refresh()

func _panel_style(bg:Color,border:Color) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=bg
	s.border_color=border
	s.set_border_width_all(1)
	s.corner_radius_top_left=3
	s.corner_radius_top_right=3
	s.corner_radius_bottom_left=3
	s.corner_radius_bottom_right=3
	s.content_margin_left=9
	s.content_margin_right=9
	s.content_margin_top=7
	s.content_margin_bottom=7
	return s

func _build_ui() -> void:
	panel=PanelContainer.new()
	panel.anchor_left=.105
	panel.anchor_right=.335
	panel.anchor_top=.76
	panel.anchor_bottom=.975
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",_panel_style(Color(0.01,0.035,0.05,.93),Color("#806634")))
	add_child(panel)
	var box:=VBoxContainer.new()
	box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	title=Label.new()
	title.text="COMPANY VESSELS"
	title.add_theme_font_size_override("font_size",12)
	title.add_theme_color_override("font_color",Color("#e5bd66"))
	box.add_child(title)
	body=Label.new()
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size",10)
	body.add_theme_color_override("font_color",Color("#d7d2c4"))
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(body)

func _process(delta:float) -> void:
	refresh_clock += delta
	if refresh_clock >= .22:
		refresh_clock=0.0
		_refresh()
	if flash_clock > 0.0:
		flash_clock -= delta
		title.text=flash_text
		title.add_theme_color_override("font_color",Color("#7fe79a"))
	else:
		title.text="COMPANY VESSELS"
		title.add_theme_color_override("font_color",Color("#e5bd66"))

func _ship_name(ship_id:String) -> String:
	return str(GameState.ships.get(ship_id,{}).get("name","Vessel"))

func _flash(text_value:String) -> void:
	flash_text=text_value
	flash_clock=2.8

func _refresh() -> void:
	var ids:Array=GameState.player_ship_ids()
	if ids.is_empty():
		body.text="No company vessel.\nCharter one from MARKET to start trading."
		return
	var blocks:Array=[]
	for i in range(mini(ids.size(),2)):
		var ship_id:=str(ids[i])
		if not GameState.ships.has(ship_id):
			continue
		var ship:Dictionary=GameState.ships[ship_id]
		var state:=str(ship.get("state","in_port")).replace("_"," ").capitalize()
		var line1:="%s  •  %s"%[str(ship.get("name","Vessel")),state]
		var line2:="Crew %d  Stores %dd  Hull %d%%"%[int(ship.get("crew_count",0)),int(ship.get("provisions_days",0)),int(ship.get("condition",100))]
		var line3:="Morale %d  Health %d  Cargo %d%%"%[int(float(ship.get("morale",72.0))),int(float(ship.get("crew_health",100.0))),int(float(ship.get("cargo_condition",100.0)))]
		var progress_text:=""
		if str(ship.get("state",""))=="loading":
			progress_text="Loading %d%%  %.0f/%.0ft"%[int(float(ship.get("loading_progress",0.0))*100.0),float(ship.get("cargo_loaded",0.0)),float(ship.get("cargo_target",0.0))]
		elif str(ship.get("state",""))=="en_route":
			var voyage_id:=str(ship.get("active_voyage_id",""))
			var voyage:Dictionary=GameState.voyages.get(voyage_id,{})
			progress_text="Voyage %d%%  Day %d/%d"%[int(float(voyage.get("progress",0.0))*100.0),int(voyage.get("days_elapsed",0)),int(voyage.get("days_total",0))+int(voyage.get("delay_days",0))]
		var block:=line1+"\n"+line2+"\n"+line3
		if progress_text!="": block += "\n"+progress_text
		blocks.append(block)
	body.text="\n\n".join(blocks)
