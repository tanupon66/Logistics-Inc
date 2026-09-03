extends Control

var cash := 25000
var day := 1
var running := true
var city: Control
var page_title: Label
var page_body: Label
var cash_label: Label
var day_label: Label

func _ready():
	get_window().mode = Window.MODE_FULLSCREEN
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_build()
	set_process(true)

func _build():
	var bg=ColorRect.new(); bg.color=Color("#101820"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var root=VBoxContainer.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_theme_constant_override("separation",0); add_child(root)
	var top=PanelContainer.new(); top.custom_minimum_size=Vector2(0,70); top.add_theme_stylebox_override("panel",_box("#172532")); root.add_child(top)
	var th=HBoxContainer.new(); th.add_theme_constant_override("separation",18); top.add_child(th)
	var title=_label("LOGISTICS INC  •  1750",26,Color("#f1d28a")); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; th.add_child(title)
	day_label=_label("DAY 1",18,Color.WHITE); th.add_child(day_label)
	cash_label=_label("£25,000",20,Color("#79d69d")); th.add_child(cash_label)
	var pause=_btn("Ⅱ / ▶"); pause.pressed.connect(func(): running=!running); th.add_child(pause)

	var tabs=HBoxContainer.new(); tabs.custom_minimum_size=Vector2(0,58); tabs.add_theme_constant_override("separation",4); root.add_child(tabs)
	for n in ["PORT","FLEET","CONTRACTS","CREW","SUPPLY","SHIPYARD","RESEARCH","FINANCE"]:
		var b=_btn(n); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.pressed.connect(_open.bind(n)); tabs.add_child(b)

	var body=HBoxContainer.new(); body.size_flags_vertical=Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",8); root.add_child(body)
	city=PortScene.new(); city.size_flags_horizontal=Control.SIZE_EXPAND_FILL; city.size_flags_vertical=Control.SIZE_EXPAND_FILL; body.add_child(city)
	var panel=PanelContainer.new(); panel.custom_minimum_size=Vector2(360,0); panel.add_theme_stylebox_override("panel",_box("#162633")); body.add_child(panel)
	var pv=VBoxContainer.new(); pv.add_theme_constant_override("separation",12); panel.add_child(pv)
	page_title=_label("PORT OFFICE",24,Color("#f1d28a")); pv.add_child(page_title)
	page_body=_label("Liverpool Harbour\n\nLease: Pier 3\nWarehouse: rented\nShipyard: not owned\n\nThe harbour remains active while you manage the company.",17,Color("#d8e3e8")); page_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; page_body.size_flags_vertical=Control.SIZE_EXPAND_FILL; pv.add_child(page_body)
	var act=_btn("LEASE WAREHOUSE  £2,500"); act.pressed.connect(func(): _spend(2500)); pv.add_child(act)
	var ship=_btn("CHARTER COASTAL SHIP  £6,000"); ship.pressed.connect(func(): _spend(6000)); pv.add_child(ship)

func _open(n:String):
	page_title.text=n
	var text={
	"PORT":"Liverpool Harbour\nLease berths, warehouses and terminals. Grow from tenant to port operator.",
	"FLEET":"No owned vessels.\nChartered vessel available for early contracts.\nBuy ships when capital permits.",
	"CONTRACTS":"Liverpool → Dublin  General cargo  £1,850\nLiverpool → London  Machinery  £2,700\nLiverpool → Lisbon  Textiles  £4,400",
	"CREW":"Captain: vacancy\nChief Mate: vacancy\nEngineer: vacancy\nDeck crew: 0/12\n\nHire a captain to delegate voyage events.",
	"SUPPLY":"Food • Fresh water • Coal • Medical stores • Spare parts\n\nWithout a captain, voyage provisioning and events are managed by you.",
	"SHIPYARD":"No shipyard owned.\nUse commercial yards for repair/refit now.\nLater acquire a yard to repair, design and build ships for yourself or tenders.",
	"RESEARCH":"Era: Age of Sail\nNaval architecture • Rigging • Hull construction • Navigation\nRecruit engineers and researchers to accelerate technology.",
	"FINANCE":"Cash £%s\nAssets: leased office\nDebt: £0\nOwned ships: 0\nOwned yards: 0" % _money(cash)}
	page_body.text=text[n]

func _process(delta):
	if running:
		city.t += delta
		city.queue_redraw()

func _spend(v:int):
	if cash>=v: cash-=v
	cash_label.text="£"+_money(cash)

func _money(v:int)->String:
	var s=str(v); var o=""
	while s.length()>3: o=","+s.right(3)+o; s=s.left(s.length()-3)
	return s+o

func _label(t:String,sz:int,c:Color)->Label:
	var l=Label.new(); l.text=t; l.add_theme_font_size_override("font_size",sz); l.add_theme_color_override("font_color",c); return l
func _btn(t:String)->Button:
	var b=Button.new(); b.text=t; b.custom_minimum_size=Vector2(0,48); b.add_theme_font_size_override("font_size",15); return b
func _box(c:String)->StyleBoxFlat:
	var s=StyleBoxFlat.new(); s.bg_color=Color(c); s.content_margin_left=14; s.content_margin_right=14; s.content_margin_top=10; s.content_margin_bottom=10; return s

class PortScene extends Control:
	var t:=0.0
	func _ready(): mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw():
		var w=size.x; var h=size.y
		draw_rect(Rect2(0,0,w,h*.42),Color("#78909c"))
		draw_rect(Rect2(0,h*.42,w,h*.58),Color("#24566d"))
		# industrial waterfront
		for i in range(8):
			var x=30.0+i*92.0
			draw_rect(Rect2(x,h*.25,70,105),Color("#8a6747")); draw_rect(Rect2(x+8,h*.22,14,25),Color("#3f4142"))
		for i in range(5):
			var x=25.0+i*150.0
			draw_rect(Rect2(x,h*.43,125,32),Color("#66533d")); draw_line(Vector2(x+18,h*.43),Vector2(x+60,h*.31),Color("#d9a441"),7); draw_line(Vector2(x+60,h*.31),Vector2(x+105,h*.43),Color("#d9a441"),5)
		# moving ships
		for i in range(5):
			var x=fposmod(t*(24.0+i*4.0)+i*190.0,w+180.0)-120.0
			var y=h*(.55+i*.075)
			draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x+115,y),Vector2(x+96,y+20),Vector2(x+15,y+20)]),Color("#2c2c31"))
			draw_rect(Rect2(x+48,y-18,38,18),Color("#e5d9bd")); draw_rect(Rect2(x+58,y-30,8,12),Color("#8c3f2c"))
		# tugboats opposite direction
		for i in range(3):
			var x=w-fposmod(t*36.0+i*230.0,w+100.0)
			var y=h*(.50+i*.13)
			draw_rect(Rect2(x,y,52,13),Color("#b44b35")); draw_rect(Rect2(x+17,y-14,22,14),Color("#eee0bd"))
		# water movement
		for i in range(22):
			var yy=h*.46+i*15.0; var xx=fposmod(i*73.0+t*12.0,max(1.0,w)); draw_line(Vector2(xx,yy),Vector2(min(w,xx+38),yy),Color(0.55,0.78,0.84,.35),2)
