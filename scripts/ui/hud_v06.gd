extends CanvasLayer

signal speed_requested(value:int)
signal zoom_requested(delta:float)
signal reset_camera_requested()
signal view_requested(view_name:String)

var cash_label:Label
var date_label:Label
var speed_label:Label
var toast:Label
var toast_timer:float = 0.0
var drawer:PanelContainer
var drawer_title:Label
var drawer_list:VBoxContainer
var selected_ship_id:String = ""
var current_view:String = "port"

func _ready() -> void:
	_build_ui()
	EventBus.vessel_chartered.connect(func(ship_id:String): selected_ship_id=ship_id; _open_fleet(); show_message("Chartered "+str(GameState.ships[ship_id].get("name","vessel"))))
	EventBus.vessel_purchased.connect(func(ship_id:String): selected_ship_id=ship_id; _open_fleet(); show_message("Purchased "+str(GameState.ships[ship_id].get("name","vessel"))))
	EventBus.voyage_event_requested.connect(_on_voyage_event)
	EventBus.vessel_arrived.connect(func(ship_id:String,_port_id:String): selected_ship_id=ship_id; show_message(str(GameState.ships[ship_id].get("name","Vessel"))+" arrived"))
	EventBus.contract_completed.connect(func(_id:String): show_message("Freight contract completed — payment received"))
	set_process(true)

func _process(delta:float) -> void:
	_refresh_top()
	if toast_timer>0.0:
		toast_timer-=delta
		toast.visible=true
	else:
		toast.visible=false

func _panel(bg:Color,border:Color) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=bg; s.border_color=border; s.set_border_width_all(1)
	s.corner_radius_top_left=4; s.corner_radius_top_right=4; s.corner_radius_bottom_left=4; s.corner_radius_bottom_right=4
	s.content_margin_left=10; s.content_margin_right=10; s.content_margin_top=8; s.content_margin_bottom=8
	return s

func _button(text_value:String,size_v:int=12) -> Button:
	var b:=Button.new()
	b.text=text_value
	b.add_theme_font_size_override("font_size",size_v)
	b.add_theme_color_override("font_color",Color("#e9ddbd"))
	b.add_theme_stylebox_override("normal",_panel(Color(0.02,0.07,0.09,0.96),Color("#6e5a35")))
	b.add_theme_stylebox_override("hover",_panel(Color(0.05,0.13,0.16,0.98),Color("#c69a4a")))
	b.add_theme_stylebox_override("pressed",_panel(Color(0.08,0.18,0.21,0.98),Color("#e1b65f")))
	return b

func _label(text_value:String,size_v:int=13,color:=Color("#e9ddbd")) -> Label:
	var l:=Label.new(); l.text=text_value; l.add_theme_font_size_override("font_size",size_v); l.add_theme_color_override("font_color",color); return l

func _build_ui() -> void:
	_build_top()
	_build_nav()
	_build_bottom()
	_build_drawer()
	_build_toast()

func _build_top() -> void:
	var p:=PanelContainer.new(); p.anchor_right=1.0; p.offset_bottom=52; p.add_theme_stylebox_override("panel",_panel(Color(0.01,0.04,0.055,0.97),Color("#8f713a"))); add_child(p)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",16); p.add_child(row)
	var brand:=_label("⚓ LOGISTICS INC.   •   TCH STUDIO",20,Color("#e5bd66")); brand.custom_minimum_size.x=355; row.add_child(brand)
	date_label=_label("",14); date_label.custom_minimum_size.x=190; row.add_child(date_label)
	cash_label=_label("",17,Color("#74e08d")); cash_label.custom_minimum_size.x=180; row.add_child(cash_label)
	speed_label=_label("",14); speed_label.custom_minimum_size.x=80; row.add_child(speed_label)
	row.add_child(_label("Reputation 10",14,Color("#e4d39d")))

func _build_nav() -> void:
	var p:=PanelContainer.new(); p.anchor_top=.09; p.anchor_bottom=.78; p.offset_left=8; p.offset_right=116; p.add_theme_stylebox_override("panel",_panel(Color(0.01,0.04,0.055,.93),Color("#806634"))); add_child(p)
	var col:=VBoxContainer.new(); col.add_theme_constant_override("separation",5); p.add_child(col)
	for item in [["⚓\nPORT","port"],["⛵\nFLEET","fleet"],["▤\nCONTRACTS","contracts"],["♙\nPEOPLE","people"],["£\nMARKET","market"],["⌂\nSHIPYARD","shipyard"],["◎\nWORLD","world"]]:
		var b:=_button(str(item[0]),10); b.custom_minimum_size=Vector2(88,53); b.pressed.connect(_nav.bind(str(item[1]))); col.add_child(b)

func _build_bottom() -> void:
	var p:=PanelContainer.new(); p.anchor_left=.34; p.anchor_right=.66; p.anchor_top=.89; p.anchor_bottom=.985; p.add_theme_stylebox_override("panel",_panel(Color(0.01,0.04,0.055,.95),Color("#806634"))); add_child(p)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",6); p.add_child(row)
	for data in [["Ⅱ",0],["▶",1],["▶▶",4]]:
		var b:=_button(str(data[0]),14); b.custom_minimum_size=Vector2(55,46); b.pressed.connect(_set_speed.bind(int(data[1]))); row.add_child(b)
	var minus:=_button("−",20); minus.custom_minimum_size=Vector2(48,46); minus.pressed.connect(func(): zoom_requested.emit(-.12)); row.add_child(minus)
	var center:=_button("CENTER",10); center.custom_minimum_size=Vector2(82,46); center.pressed.connect(func(): reset_camera_requested.emit()); row.add_child(center)
	var plus:=_button("+",20); plus.custom_minimum_size=Vector2(48,46); plus.pressed.connect(func(): zoom_requested.emit(.12)); row.add_child(plus)

func _build_drawer() -> void:
	drawer=PanelContainer.new(); drawer.anchor_left=.72; drawer.anchor_right=.992; drawer.anchor_top=.09; drawer.anchor_bottom=.86; drawer.add_theme_stylebox_override("panel",_panel(Color(0.01,0.04,0.055,.96),Color("#9b7839"))); drawer.visible=false; add_child(drawer)
	var root:=VBoxContainer.new(); drawer.add_child(root)
	var head:=HBoxContainer.new(); root.add_child(head)
	drawer_title=_label("MANAGEMENT",17,Color("#e5bd66")); drawer_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; head.add_child(drawer_title)
	var close:=_button("×",17); close.custom_minimum_size=Vector2(38,32); close.pressed.connect(func(): drawer.visible=false); head.add_child(close)
	root.add_child(HSeparator.new())
	var scroll:=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(scroll)
	drawer_list=VBoxContainer.new(); drawer_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; drawer_list.add_theme_constant_override("separation",7); scroll.add_child(drawer_list)

func _build_toast() -> void:
	toast=Label.new(); toast.anchor_left=.22; toast.anchor_right=.70; toast.anchor_top=.085; toast.anchor_bottom=.14; toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; toast.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size",13); toast.add_theme_color_override("font_color",Color("#f7e7b4")); toast.add_theme_stylebox_override("normal",_panel(Color(0.01,0.04,0.055,.94),Color("#ad8742"))); toast.mouse_filter=Control.MOUSE_FILTER_IGNORE; toast.visible=false; add_child(toast)

func _clear_drawer() -> void:
	for child in drawer_list.get_children(): child.queue_free()
	drawer.visible=true

func _nav(name:String) -> void:
	match name:
		"port":
			current_view="port"; view_requested.emit("port"); drawer.visible=false
		"world":
			current_view="world"; view_requested.emit("world"); _open_world_status()
		"fleet": _open_fleet()
		"contracts": _open_contracts()
		"people": _open_people()
		"market": _open_market()
		"shipyard": _open_shipyard()

func _open_fleet() -> void:
	_clear_drawer(); drawer_title.text="FLEET"
	var ids:=GameState.player_ship_ids()
	if ids.is_empty():
		drawer_list.add_child(_label("You own no vessel yet.\nOpen MARKET to charter a ship and begin trading.",13,Color("#c9d2d0"))); return
	for sid in ids:
		if not GameState.ships.has(sid): continue
		var ship:Dictionary=GameState.ships[sid]
		var active:=str(sid)==selected_ship_id
		var text:="%s%s\n%s • %dt • %s\nCrew %d/%d • Stores %d days • Hull %d%%"%[("▶ " if active else ""),str(ship.get("name","Vessel")),str(ship.get("class","Ship")),int(ship.get("capacity",0)),str(ship.get("state","in_port")).replace("_"," ").capitalize(),int(ship.get("crew_count",0)),int(ship.get("min_crew",0)),int(ship.get("provisions_days",0)),int(ship.get("condition",100))]
		var b:=_button(text,11); b.alignment=HORIZONTAL_ALIGNMENT_LEFT; b.pressed.connect(_select_ship.bind(str(sid))); drawer_list.add_child(b)
	if selected_ship_id!="" and GameState.ships.has(selected_ship_id):
		var ship:Dictionary=GameState.ships[selected_ship_id]
		drawer_list.add_child(HSeparator.new())
		var needed:=maxi(0,int(ship.get("min_crew",0))-int(ship.get("crew_count",0)))
		if needed>0:
			var crew:=_button("HIRE %d CREW   £%d"%[needed,needed*6],11); crew.pressed.connect(_hire_crew.bind(needed)); drawer_list.add_child(crew)
		var stores:=_button("LOAD 14 DAYS PROVISIONS",11); stores.pressed.connect(_load_stores.bind(14)); drawer_list.add_child(stores)
		if int(ship.get("condition",100))<100 and str(ship.get("port_id",""))=="port_liverpool":
			var repair:=_button("REPAIR AT OLD DRY DOCK",11); repair.pressed.connect(_repair_selected); drawer_list.add_child(repair)
		if str(ship.get("assigned_contract_id",""))!="" and str(ship.get("state",""))=="in_port":
			var depart:=_button("DEPART ON ASSIGNED CONTRACT",11); depart.pressed.connect(_depart_selected); drawer_list.add_child(depart)

func _open_contracts() -> void:
	_clear_drawer(); drawer_title.text="FREIGHT CONTRACTS"
	if selected_ship_id=="": drawer_list.add_child(_label("Select or charter a vessel first.",12,Color("#d7b96c")))
	for cid in GameState.contracts.keys():
		var c:Dictionary=GameState.contracts[cid]
		if str(c.get("status",""))!="offered": continue
		var from_name:=str(GameState.ports.get(c.get("origin_port_id",""),{}).get("name","?"))
		var to_name:=str(GameState.ports.get(c.get("destination_port_id",""),{}).get("name","?"))
		var b:=_button("%s\n%s → %s • %dt • %d days\nReward £%d"%[str(c.get("cargo","Cargo")),from_name,to_name,int(c.get("amount",0)),int(c.get("days",0)),int(c.get("reward",0))],11)
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT; b.disabled=selected_ship_id==""; b.pressed.connect(_assign_contract.bind(str(cid))); drawer_list.add_child(b)
	if _active_voyage_id()!="": _add_active_voyage_card(_active_voyage_id())

func _open_people() -> void:
	_clear_drawer(); drawer_title.text="CAPTAINS & CREW"
	if selected_ship_id=="": drawer_list.add_child(_label("Select a vessel in FLEET before hiring a captain.",12,Color("#d7b96c")))
	for pid in GameState.people.keys():
		var p:Dictionary=GameState.people[pid]
		if str(p.get("role",""))!="captain" or str(p.get("status",""))!="available": continue
		var b:=_button("%s\nNavigation %d • Leadership %d • Weather %d\n£%d sign • £%d/day"%[str(p.get("name","Captain")),int(p.get("navigation",0)),int(p.get("leadership",0)),int(p.get("weather",0)),int(p.get("signing_cost",0)),int(p.get("daily_wage",0))],11)
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT; b.disabled=selected_ship_id==""; b.pressed.connect(_hire_captain.bind(str(pid))); drawer_list.add_child(b)

func _open_market() -> void:
	_clear_drawer(); drawer_title.text="VESSEL & PORT MARKET"
	drawer_list.add_child(_label("CHARTER VESSELS",12,Color("#e5bd66")))
	var charters:Dictionary=GameState.markets.get("charter_offers",{})
	for oid in charters.keys():
		var o:Dictionary=charters[oid]
		if not bool(o.get("available",false)): continue
		var b:=_button("CHARTER  %s — %s\n%dt capacity • crew %d • £%d deposit • £%d/day"%[str(o.get("name","Vessel")),str(o.get("class","Ship")),int(o.get("capacity",0)),int(o.get("min_crew",0)),int(o.get("deposit",0)),int(o.get("daily_rate",0))],11)
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT; b.pressed.connect(_charter.bind(str(oid))); drawer_list.add_child(b)
	drawer_list.add_child(HSeparator.new()); drawer_list.add_child(_label("VESSELS FOR SALE",12,Color("#e5bd66")))
	var sales:Dictionary=GameState.markets.get("ship_sale_offers",{})
	for oid in sales.keys():
		var o:Dictionary=sales[oid]
		if not bool(o.get("available",false)): continue
		var b:=_button("BUY  %s — %s\n%dt • condition %d%% • £%d"%[str(o.get("name","Vessel")),str(o.get("class","Ship")),int(o.get("capacity",0)),int(o.get("condition",100)),int(o.get("price",0))],11)
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT; b.pressed.connect(_buy_ship.bind(str(oid))); drawer_list.add_child(b)
	drawer_list.add_child(HSeparator.new()); drawer_list.add_child(_label("LEASE PORT FACILITIES",12,Color("#e5bd66")))
	for fid in ["facility_warehouse_3","facility_liverpool_quay"]:
		var f:Dictionary=GameState.facilities[fid]
		var leased:=fid in GameState.player_company.get("leased_facility_ids",[])
		var b:=_button("%s%s\n£%d upfront • £%d/week"%[("✓ " if leased else ""),str(f.get("name","Facility")),int(f.get("lease_cost",0)),int(f.get("weekly_cost",0))],11)
		b.disabled=leased; b.pressed.connect(_lease.bind(fid)); drawer_list.add_child(b)

func _open_shipyard() -> void:
	_clear_drawer(); drawer_title.text="OLD DRY DOCK / ROYAL SHIPYARD"
	drawer_list.add_child(_label("You do not own a yard yet. Liverpool provides external repair and construction services.\n\nPhase 2 uses the Old Dry Dock for paid repairs. Ownership, retrofit and ship construction unlock in the Shipyard phase.",12,Color("#c9d2d0")))
	if selected_ship_id!="" and GameState.ships.has(selected_ship_id):
		var repair:=_button("REPAIR SELECTED VESSEL",11); repair.pressed.connect(_repair_selected); drawer_list.add_child(repair)

func _open_world_status() -> void:
	_clear_drawer(); drawer_title.text="WORLD VOYAGES"
	var active:=0
	for vid in GameState.voyages.keys():
		if str(GameState.voyages[vid].get("status",""))=="en_route": active+=1; _add_active_voyage_card(str(vid))
	if active==0: drawer_list.add_child(_label("No company vessel is currently at sea.\nAssign a freight contract and depart from Liverpool.",12,Color("#c9d2d0")))

func _add_active_voyage_card(vid:String) -> void:
	if not GameState.voyages.has(vid): return
	var v:Dictionary=GameState.voyages[vid]; var ship:Dictionary=GameState.ships.get(v.get("ship_id",""),{})
	var dest:Dictionary=GameState.ports.get(v.get("destination_port_id",""),{})
	drawer_list.add_child(HSeparator.new()); drawer_list.add_child(_label("%s → %s\nProgress %d%% • Stores %d days"%[str(ship.get("name","Vessel")),str(dest.get("name","Destination")),int(float(v.get("progress",0))*100.0),int(ship.get("provisions_days",0))],12,Color("#8fdb9d")))

func _select_ship(ship_id:String) -> void:
	selected_ship_id=ship_id; _open_fleet()

func _charter(offer_id:String) -> void:
	if ShippingSystem.charter_ship(offer_id)=="": show_message("Unable to charter: check available cash")

func _buy_ship(offer_id:String) -> void:
	if ShippingSystem.buy_ship(offer_id)=="": show_message("Unable to purchase vessel")

func _hire_crew(amount:int) -> void:
	if not ShippingSystem.hire_crew(selected_ship_id,amount): show_message("Crew hire failed")
	_open_fleet()

func _load_stores(days:int) -> void:
	if not ShippingSystem.load_provisions(selected_ship_id,days): show_message("Could not load provisions")
	_open_fleet()

func _hire_captain(person_id:String) -> void:
	if ShippingSystem.hire_captain(person_id,selected_ship_id): show_message("Captain appointed")
	else: show_message("Captain hire failed")
	_open_people()

func _assign_contract(contract_id:String) -> void:
	if ShippingSystem.accept_contract(contract_id,selected_ship_id): show_message("Contract assigned. Prepare ship, then depart from FLEET.")
	else: show_message("Cannot assign: check ship capacity/location")
	_open_contracts()

func _depart_selected() -> void:
	var vid:=ShippingSystem.depart_ship(selected_ship_id)
	if vid=="": show_message("Departure blocked: minimum crew, stores and contract are required")
	else: show_message("Vessel departed Liverpool"); current_view="world"; view_requested.emit("world"); _open_world_status()

func _repair_selected() -> void:
	if ShippingSystem.repair_ship(selected_ship_id): show_message("Repair completed at Old Dry Dock")
	else: show_message("Repair unavailable or insufficient funds")
	_open_fleet()

func _lease(facility_id:String) -> void:
	if ShippingSystem.lease_facility(facility_id): show_message("Lease signed")
	else: show_message("Lease failed")
	_open_market()

func _active_voyage_id() -> String:
	if selected_ship_id!="" and GameState.ships.has(selected_ship_id): return str(GameState.ships[selected_ship_id].get("active_voyage_id",""))
	return ""

func _on_voyage_event(voyage_id:String,event_id:String) -> void:
	_clear_drawer(); drawer_title.text="VOYAGE DECISION"
	if event_id=="heavy_weather":
		drawer_list.add_child(_label("⚠ HEAVY WEATHER\nA hard squall is crossing the route. Without an experienced captain, you must issue orders.",13,Color("#f0b36a")))
		var safe:=_button("HEAVE TO — lose 2 days, protect hull",11); safe.pressed.connect(_resolve_event.bind(voyage_id,"heave_to")); drawer_list.add_child(safe)
		var fast:=_button("PRESS ON — no delay, risk 12% hull damage",11); fast.pressed.connect(_resolve_event.bind(voyage_id,"press_on")); drawer_list.add_child(fast)
	elif event_id=="low_stores":
		drawer_list.add_child(_label("⚠ LOW PROVISIONS\nFood and fresh water are running dangerously low.",13,Color("#f0b36a")))
		var ration:=_button("RATION STORES — stretch supplies 2 days",11); ration.pressed.connect(_resolve_event.bind(voyage_id,"ration")); drawer_list.add_child(ration)
		var buy:=_button("BUY EMERGENCY STORES — £80",11); buy.pressed.connect(_resolve_event.bind(voyage_id,"buy_emergency")); drawer_list.add_child(buy)
	show_message("Voyage needs your decision")

func _resolve_event(voyage_id:String,choice:String) -> void:
	if ShippingSystem.resolve_event(voyage_id,choice): show_message("Order issued")
	_open_world_status()

func set_selection(_kind:String,data:Dictionary) -> void:
	_clear_drawer(); drawer_title.text=str(data.get("name","PORT ASSET")).to_upper()
	var text:="Type: %s\n"%str(data.get("type","facility")).capitalize()
	if data.has("level"): text+="Level: %s\n"%str(data["level"])
	if data.has("workers"): text+="Workers: %s\n"%str(data["workers"])
	if data.has("capacity"): text+="Capacity: %s t\n"%str(data["capacity"])
	if data.has("berths"): text+="Berths: %s\n"%str(data["berths"])
	text+="\n%s"%str(data.get("status","Operating"))
	drawer_list.add_child(_label(text,12,Color("#c9d2d0")))

func _refresh_top() -> void:
	if GameState.world.is_empty(): return
	date_label.text="%02d/%02d/%04d  %02d:00"%[int(GameState.world.get("day",1)),int(GameState.world.get("month",1)),int(GameState.world.get("year",1750)),int(GameState.world.get("hour",8))]
	cash_label.text="£ "+_money(int(GameState.get_cash()))
	speed_label.text="x%d"%TimeSystem.speed

func _money(value:int) -> String:
	var s:=str(abs(value)); var out:=""
	while s.length()>3: out=","+s.right(3)+out; s=s.left(s.length()-3)
	return ("-" if value<0 else "")+s+out

func _set_speed(value:int) -> void:
	speed_requested.emit(value); show_message("Simulation speed x%d"%value)

func show_message(message:String) -> void:
	toast.text=message; toast_timer=2.8; toast.visible=true
