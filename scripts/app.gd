extends Control

const PORT = preload("res://assets/port_backdrop_v04.svg")
const MAP = preload("res://assets/world_map_v04.svg")
const SPLASH = preload("res://assets/studio_splash.png")

var cash:int=180000
var income:int=12450
var day:int=12
var year:int=1873
var speed:int=1
var sim:float=0.0
var tick:float=0.0
var route:float=-1.0
var build_name:String=""
var build_progress:float=0.0
var selected:String="PORT"
var ship_condition:int=98
var cargo:int=1200
var coal:int=78
var facilities:Dictionary={"Berth":2,"Warehouse":2,"Rail":1,"Dry Dock":0,"Shipyard":0}
var game:Control
var living:LivingLayer
var cash_label:Label
var date_label:Label
var info_title:Label
var info:RichTextLabel
var toast:Label
var map_layer:Control

func _ready()->void:
	get_window().mode=Window.MODE_FULLSCREEN
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	get_window().content_scale_size=Vector2i(1280,720)
	var root:Control=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var bg:ColorRect=ColorRect.new()
	bg.color=Color("#050b10")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var logo:TextureRect=TextureRect.new()
	logo.texture=SPLASH
	logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(logo)
	var timer:SceneTreeTimer=get_tree().create_timer(1.4)
	timer.timeout.connect(func(): root.queue_free(); _build_game())

func _build_game()->void:
	game=Control.new()
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game)
	var art:TextureRect=TextureRect.new()
	art.texture=PORT
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_SCALE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.add_child(art)
	living=LivingLayer.new()
	living.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.add_child(living)
	_build_hotspots()
	_build_top()
	_build_nav()
	_build_info()
	_build_bottom()
	_build_toast()
	_refresh()
	_show("Living Port running — ships, trains, trucks, cranes and construction continue while you manage.")

func _build_top()->void:
	var p:PanelContainer=PanelContainer.new()
	p.anchor_right=1.0
	p.offset_bottom=58
	p.add_theme_stylebox_override("panel",_panel(Color(0.01,0.04,0.06,0.96),Color("#b89545")))
	game.add_child(p)
	var r:HBoxContainer=HBoxContainer.new()
	r.add_theme_constant_override("separation",8)
	p.add_child(r)
	var brand:Label=_label("⚓ LOGISTICS INC.",24,Color("#f2cf79"))
	brand.custom_minimum_size.x=240
	r.add_child(brand)
	var studio:Label=_label("TCH STUDIO",14,Color("#c9d4d8"))
	studio.custom_minimum_size.x=110
	r.add_child(studio)
	date_label=_label("",15,Color.WHITE)
	date_label.custom_minimum_size.x=165
	r.add_child(date_label)
	for data:Array in [["Ⅱ",0],["▶",1],["▶▶",4]]:
		var b:Button=_btn(str(data[0]),14)
		b.custom_minimum_size.x=48
		b.pressed.connect(_set_speed.bind(int(data[1])))
		r.add_child(b)
	cash_label=_label("",21,Color("#f4d06f"))
	cash_label.custom_minimum_size.x=180
	r.add_child(cash_label)
	var inc:Label=_label("+£%s/week"%_money(income),14,Color("#6ce47f"))
	inc.custom_minimum_size.x=150
	r.add_child(inc)
	r.add_child(_label("🙂 72%",15,Color("#f2d66e")))

func _build_nav()->void:
	var p:PanelContainer=PanelContainer.new()
	p.anchor_top=.09
	p.anchor_bottom=.82
	p.offset_left=6
	p.offset_right=145
	p.add_theme_stylebox_override("panel",_panel(Color(0.01,0.04,0.06,0.94),Color("#806a37")))
	game.add_child(p)
	var v:VBoxContainer=VBoxContainer.new()
	v.add_theme_constant_override("separation",4)
	p.add_child(v)
	for name:String in ["COMPANY","WORLD MAP","PORT","FLEET","CONTRACTS","SHIPYARD","RESEARCH","PERSONNEL","FINANCE","MARKET"]:
		var b:Button=_btn(_icon(name)+"  "+name,12)
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y=42
		b.pressed.connect(_nav.bind(name))
		v.add_child(b)

func _build_info()->void:
	var p:PanelContainer=PanelContainer.new()
	p.anchor_left=.795
	p.anchor_right=.995
	p.anchor_top=.09
	p.anchor_bottom=.82
	p.add_theme_stylebox_override("panel",_panel(Color(0.01,0.04,0.06,0.94),Color("#806a37")))
	game.add_child(p)
	var v:VBoxContainer=VBoxContainer.new()
	p.add_child(v)
	info_title=_label("LONDON PORT",18,Color("#f0cb72"))
	info_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(info_title)
	v.add_child(HSeparator.new())
	info=RichTextLabel.new()
	info.bbcode_enabled=true
	info.size_flags_vertical=Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("normal_font_size",14)
	v.add_child(info)
	var act:Button=_btn("PRIMARY ACTION",13)
	act.pressed.connect(_primary)
	v.add_child(act)

func _build_bottom()->void:
	var p:PanelContainer=PanelContainer.new()
	p.anchor_left=.145
	p.anchor_right=.79
	p.anchor_top=.83
	p.anchor_bottom=.995
	p.add_theme_stylebox_override("panel",_panel(Color(0.01,0.04,0.06,0.96),Color("#806a37")))
	game.add_child(p)
	var v:VBoxContainer=VBoxContainer.new()
	p.add_child(v)
	v.add_child(_label("BUILD & OPERATE — visible directly in the port",14,Color("#f0cb72")))
	var row:HBoxContainer=HBoxContainer.new()
	row.add_theme_constant_override("separation",5)
	v.add_child(row)
	for data:Array in [["BERTH",15000],["WAREHOUSE",12000],["RAIL",25000],["DRY DOCK",75000],["SHIPYARD",120000],["SUPPLY",2500],["SET ROUTE",0]]:
		var name:String=str(data[0])
		var price:int=int(data[1])
		var txt:String=name
		if price>0:
			txt+="\n£"+_money(price)
		var b:Button=_btn(txt,11)
		b.custom_minimum_size=Vector2(95,78)
		if name=="SUPPLY":
			b.pressed.connect(_supply)
		elif name=="SET ROUTE":
			b.pressed.connect(_route)
		else:
			b.pressed.connect(_build.bind(name,price))
		row.add_child(b)

func _build_hotspots()->void:
	var points:Array=[["WAREHOUSE",Vector2(500,260),Vector2(310,140)],["SHIPYARD",Vector2(900,355),Vector2(300,180)],["DRY DOCK",Vector2(170,360),Vector2(260,150)],["RAIL",Vector2(250,130),Vector2(500,100)],["PORT",Vector2(420,370),Vector2(420,200)]]
	for data:Array in points:
		var b:Button=Button.new()
		b.flat=true
		b.text=""
		b.position=data[1]
		b.size=data[2]
		b.modulate=Color(1,1,1,.01)
		b.pressed.connect(_select.bind(str(data[0])))
		game.add_child(b)

func _build_toast()->void:
	toast=Label.new()
	toast.anchor_left=.22
	toast.anchor_right=.78
	toast.anchor_top=.095
	toast.anchor_bottom=.15
	toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size",14)
	toast.add_theme_color_override("font_color",Color("#fff0ba"))
	toast.add_theme_stylebox_override("normal",_panel(Color(0.01,0.04,0.06,.94),Color("#b89545")))
	toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
	game.add_child(toast)

func _process(delta:float)->void:
	if living==null:
		return
	sim+=delta
	living.t=sim
	living.build_name=build_name
	living.build_progress=build_progress
	living.route=route
	living.queue_redraw()
	if speed>0:
		tick+=delta*float(speed)*.18
		if tick>=1.0:
			tick-=1.0
			day+=1
			if day>30:
				day=1
			if day%7==0:
				cash+=income
			_refresh()
	if build_name!="":
		build_progress+=delta*.0045*float(max(1,speed))
		if build_progress>=1.0:
			var done:String=build_name
			facilities[done]=int(facilities.get(done,0))+1
			build_name=""
			build_progress=0
			income+=450
			_show(done+" completed and is now operating.")
			_refresh()
	if route>=0.0:
		route+=delta*.0075*float(max(1,speed))
		if route>=1.0:
			route=-1.0
			cash+=24600
			cargo=0
			income+=800
			_show("SS Oceanic arrived New York. Contract +£24,600")
			_refresh()
	if map_layer!=null:
		var marker:Control=map_layer.get_node_or_null("Ship") as Control
		if marker!=null and route>=0.0:
			marker.position=Vector2(550,250).lerp(Vector2(260,190),route)

func _nav(name:String)->void:
	selected=name
	if name=="WORLD MAP":
		_world_map()
	else:
		_close_map()
		_refresh_info()

func _select(name:String)->void:
	selected=name
	_refresh_info()
	_show("Selected "+name)

func _set_speed(value:int)->void:
	speed=value
	_refresh()

func _primary()->void:
	if selected=="FLEET" and ship_condition<100 and cash>=8500:
		cash-=8500
		ship_condition=min(100,ship_condition+12)
		_show("SS Oceanic entered dry dock for service.")
	elif selected=="CONTRACTS":
		_route()
	elif selected=="SHIPYARD":
		_build("SHIPYARD",120000)
	else:
		_show(selected+" management active. Port simulation remains unpaused.")
	_refresh()

func _build(name:String,price:int)->void:
	if build_name!="":
		_show("Construction crew busy: %s %d%%"%[build_name,int(build_progress*100)])
		return
	if cash<price:
		_show("Insufficient capital.")
		return
	cash-=price
	build_name=name
	build_progress=.01
	selected="CONSTRUCTION"
	_show("Construction started: "+name)
	_refresh()

func _supply()->void:
	if cash<2500:
		_show("Insufficient cash.")
		return
	cash-=2500
	coal=min(100,coal+18)
	cargo=min(1800,cargo+220)
	_show("Coal, provisions and cargo loaded.")
	_refresh()

func _route()->void:
	if route<0.0:
		route=.02
		cargo=max(cargo,1200)
		_show("SS Oceanic departed London → New York.")
	_world_map()
	_refresh()

func _world_map()->void:
	if map_layer!=null:
		return
	map_layer=Control.new()
	map_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_layer.z_index=4
	game.add_child(map_layer)
	var shade:ColorRect=ColorRect.new()
	shade.color=Color(0.01,0.025,0.035,.9)
	shade.anchor_left=.145
	shade.anchor_right=.79
	shade.anchor_top=.09
	shade.anchor_bottom=.82
	map_layer.add_child(shade)
	var tex:TextureRect=TextureRect.new()
	tex.texture=MAP
	tex.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.anchor_left=.19
	tex.anchor_right=.76
	tex.anchor_top=.15
	tex.anchor_bottom=.72
	map_layer.add_child(tex)
	var marker:ShipDot=ShipDot.new()
	marker.name="Ship"
	marker.position=Vector2(550,250)
	marker.size=Vector2(42,25)
	map_layer.add_child(marker)
	var b:Button=_btn("RETURN TO PORT",13)
	b.position=Vector2(820,535)
	b.size=Vector2(160,44)
	b.pressed.connect(_close_map)
	map_layer.add_child(b)
	selected="WORLD MAP"
	_refresh_info()

func _close_map()->void:
	if map_layer!=null and is_instance_valid(map_layer):
		map_layer.queue_free()
	map_layer=null

func _refresh()->void:
	if cash_label==null:
		return
	cash_label.text="£ "+_money(cash)
	date_label.text="%02d Apr %04d  •  x%d"%[day,year,speed]
	_refresh_info()

func _refresh_info()->void:
	if info==null:
		return
	match selected:
		"PORT":
			info_title.text="LONDON PORT"
			info.text="[b]Major Port[/b]\nReputation 72%\n\nBerths %d\nWarehouse Lv.%d\nRail Lv.%d\nWorkers 1,245\nEfficiency 86%%\n\n[b]LIVE[/b]\nShips berth and depart\nTrains haul freight\nTrucks feed warehouses\nCranes work continuously"%[facilities["Berth"],facilities["Warehouse"],facilities["Rail"]]
		"FLEET":
			info_title.text="ACTIVE FLEET"
			info.text="[b]SS Oceanic[/b]\nSteam Cargo Ship\n5,210 DWT\nCondition [color=#62e783]%d%%[/color]\nCargo %d/1800 t\nCoal %d%%\nStatus: %s\n\nSS Mercantile — In Port\nSS Pioneer — At Sea\nSS Atlantic — Repair"%[ship_condition,cargo,coal,("At Sea" if route>=0 else "London")]
		"CONTRACTS":
			info_title.text="FREIGHT CONTRACTS"
			info.text="[b]London → New York[/b]\nGeneral Goods £24,600\n18 days\n\nLiverpool → Cape Town £22,100\nSingapore → Shanghai £16,300\n\nPRIMARY ACTION dispatches the vessel."
		"SHIPYARD":
			info_title.text="SHIPYARD"
			info.text="Dry Dock Lv.%d\nShipyard Lv.%d\n\n%s\n\nConstruction and repairs remain visible in the yard."%[facilities["Dry Dock"],facilities["Shipyard"],_build_status()]
		"WAREHOUSE":
			info_title.text="WAREHOUSE"
			info.text="Level %d\nStorage 68%%\nInbound 420 t/day\nOutbound 387 t/day\n\nRoad and rail freight moves continuously."%facilities["Warehouse"]
		"RAIL":
			info_title.text="RAIL TERMINAL"
			info.text="Freight trains 7/day\nCapacity 2,400 t/day\nUtilization 74%"
		"DRY DOCK":
			info_title.text="DRY DOCK"
			info.text="Level %d\nSB-001 repair 42%%\nSS Pioneer waiting\n\nOwn capacity cuts outside repair cost."%facilities["Dry Dock"]
		"WORLD MAP":
			info_title.text="WORLD TRADE"
			info.text="London → New York\n3,460 nm\nFreight £24,600\nVoyage %d%%\nWeather Moderate\nCaptain A. Sterling"%int(max(0.0,route)*100.0)
		"CONSTRUCTION":
			info_title.text="CONSTRUCTION"
			info.text="%s\nProgress [color=#f2d66e]%d%%[/color]\n\nWorkers and cranes are active on site."%[build_name,int(build_progress*100)]
		_:
			info_title.text=selected
			info.text="This department uses the same continuous simulation. The living port keeps running while you manage it."

func _build_status()->String:
	if build_name=="":
		return "No active construction"
	return "%s — %d%%"%[build_name,int(build_progress*100)]

func _show(message:String)->void:
	if toast==null:
		return
	toast.text=message
	var timer:SceneTreeTimer=get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		if toast!=null and toast.text==message:
			toast.text=""
	)

func _money(value:int)->String:
	var s:String=str(value)
	var out:String=""
	while s.length()>3:
		out=","+s.substr(s.length()-3,3)+out
		s=s.substr(0,s.length()-3)
	return s+out

func _icon(name:String)->String:
	return {"COMPANY":"▦","WORLD MAP":"🌍","PORT":"⚓","FLEET":"🚢","CONTRACTS":"▤","SHIPYARD":"🏗","RESEARCH":"⚗","PERSONNEL":"👥","FINANCE":"£","MARKET":"⇅"}.get(name,"•")

func _label(text_value:String,size_value:int,color_value:Color)->Label:
	var l:Label=Label.new()
	l.text=text_value
	l.add_theme_font_size_override("font_size",size_value)
	l.add_theme_color_override("font_color",color_value)
	return l

func _btn(text_value:String,size_value:int)->Button:
	var b:Button=Button.new()
	b.text=text_value
	b.add_theme_font_size_override("font_size",size_value)
	b.add_theme_color_override("font_color",Color("#e9e4cf"))
	b.add_theme_stylebox_override("normal",_panel(Color(0.02,0.07,0.09,.94),Color("#6f5a32")))
	b.add_theme_stylebox_override("hover",_panel(Color(0.05,0.12,0.14,.98),Color("#d2a84b")))
	return b

func _panel(fill:Color,border:Color)->StyleBoxFlat:
	var s:StyleBoxFlat=StyleBoxFlat.new()
	s.bg_color=fill
	s.border_color=border
	s.set_border_width_all(1)
	s.corner_radius_top_left=4
	s.corner_radius_top_right=4
	s.corner_radius_bottom_left=4
	s.corner_radius_bottom_right=4
	s.content_margin_left=8
	s.content_margin_right=8
	s.content_margin_top=6
	s.content_margin_bottom=6
	return s

class LivingLayer extends Control:
	var t:float=0.0
	var build_name:String=""
	var build_progress:float=0.0
	var route:float=-1.0
	func _draw()->void:
		for i:int in range(18):
			var x:float=fposmod(float(i*91)+t*22.0,1280.0)
			var y:float=500.0+float((i*37)%190)
			draw_line(Vector2(x,y),Vector2(x+18,y-4),Color(0.7,0.9,1,.35),1)
		_boat(Vector2(fposmod(t*36+60,1450)-80,610),.72,Color("#f0b84a"))
		_boat(Vector2(1280-fposmod(t*29+180,1450),535),.55,Color("#d74a35"))
		_boat(Vector2(fposmod(t*22+420,1500)-100,665),.46,Color("#f4e7c4"))
		var train_x:float=fposmod(t*42,1700)-350
		for c:int in range(7):
			draw_rect(Rect2(Vector2(train_x+c*38,186),Vector2(32,10)),Color("#b13b32") if c%2==0 else Color("#315b86"))
		for q:int in range(5):
			var truck_x:float=fposmod(t*(28+q*4)+q*220,1500)-100
			draw_rect(Rect2(Vector2(truck_x,292+(q%2)*16),Vector2(22,8)),Color("#e6e1c9"))
		for crane_x:float in [420.0,515.0,700.0,905.0]:
			var hook_y:float=330+24*sin(t*1.4+crane_x)
			draw_line(Vector2(crane_x,300),Vector2(crane_x,hook_y),Color("#25292a"),2)
			draw_rect(Rect2(Vector2(crane_x-5,hook_y),Vector2(10,8)),Color("#d8a72f"))
		for q:int in range(8):
			var life:float=fposmod(t*.18+q*.13,1.0)
			draw_circle(Vector2(680+sin(q*2.2)*18+life*14,85-life*78),8+life*14,Color(.9,.9,.88,.42*(1-life)))
		if build_name!="":
			var center:Vector2=Vector2(1040,470)
			draw_circle(center,42,Color(1,.7,.1,.12))
			draw_arc(center,42,-PI/2,-PI/2+TAU*build_progress,48,Color("#ffd15b"),5)
			draw_rect(Rect2(center+Vector2(-28,28),Vector2(56*build_progress,7)),Color("#6fe17f"))
	func _boat(pos:Vector2,scale_value:float,hull:Color)->void:
		draw_colored_polygon(PackedVector2Array([pos+Vector2(-28,-5)*scale_value,pos+Vector2(24,-5)*scale_value,pos+Vector2(32,0)*scale_value,pos+Vector2(20,7)*scale_value,pos+Vector2(-24,7)*scale_value]),hull)
		draw_rect(Rect2(pos+Vector2(-6,-14)*scale_value,Vector2(16,10)*scale_value),Color("#f4eee0"))
		draw_line(pos+Vector2(-40,2)*scale_value,pos+Vector2(-72,4)*scale_value,Color(.8,.95,1,.4),2)

class ShipDot extends Control:
	func _draw()->void:
		draw_colored_polygon(PackedVector2Array([Vector2(2,11),Vector2(30,11),Vector2(36,15),Vector2(28,19),Vector2(4,19)]),Color("#d54b35"))
		draw_rect(Rect2(Vector2(10,3),Vector2(14,9)),Color("#f2ead6"))
