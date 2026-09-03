extends Control

enum Screen { SPLASH, MENU, GAME }

const NAV := ["COMPANY", "PORT", "FLEET", "CONTRACTS", "CREW", "SUPPLY", "SHIPYARD", "RESEARCH", "FINANCE"]
const C_BG := Color("#07141c")
const C_PANEL := Color("#0c2029")
const C_PANEL2 := Color("#102a34")
const C_LINE := Color("#35505b")
const C_GOLD := Color("#c4a35a")
const C_TEXT := Color("#e7e1cf")
const C_MUTED := Color("#92a6aa")
const C_WATER := Color("#174c61")
const C_WATER2 := Color("#1f6077")
const C_ROAD := Color("#464a4a")
const C_ROOF := Color("#6f3f33")
const C_WALL := Color("#b7a079")
const C_GREEN := Color("#65b96c")

var screen := Screen.SPLASH
var tab := "PORT"
var elapsed := 0.0
var splash_t := 0.0
var date_day := 14
var date_month := 6
var date_year := 1872
var sim_speed := 1
var cash := 18500
var reputation := 8
var company_name := "Harbor & Crown Co."
var home_port := "Liverpool"
var owned_ships := 0
var chartered_ships := 1
var crew_count := 16
var captains := 1
var warehouse_level := 1
var yard_owned := false
var current_contract := "Liverpool → Dublin • General cargo"
var contract_days := 4
var contract_reward := 640
var notifications := ["Chartered brig 'Mercy' is loading at Berth 2.", "Coal prices eased 3% this week.", "A shipwright is seeking employment in Liverpool."]

var menu_buttons: Array[Button] = []
var action_buttons: Array[Button] = []
var start_button: Button
var continue_button: Button
var title_label: Label
var hint_label: Label
var modal: Panel
var modal_title: Label
var modal_body: Label
var modal_action: Button

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_ui()
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta * sim_speed
    if screen == Screen.SPLASH:
        splash_t += delta
        if splash_t > 3.1:
            screen = Screen.MENU
            _sync_ui()
    elif screen == Screen.GAME and elapsed >= 18.0:
        elapsed = 0.0
        _advance_day()
    queue_redraw()

func _build_ui() -> void:
    title_label = Label.new()
    title_label.text = "LOGISTICS INC"
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 48)
    title_label.add_theme_color_override("font_color", C_TEXT)
    add_child(title_label)
    hint_label = Label.new()
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.add_theme_font_size_override("font_size", 18)
    hint_label.add_theme_color_override("font_color", C_MUTED)
    add_child(hint_label)
    start_button = _make_button("NEW COMPANY", _on_new_company)
    add_child(start_button)
    continue_button = _make_button("CONTINUE", _on_continue)
    add_child(continue_button)
    for name in NAV:
        var b := _make_button(name, _set_tab.bind(name))
        menu_buttons.append(b)
        add_child(b)
    for i in range(6):
        var b := _make_button("", _handle_action.bind(i))
        action_buttons.append(b)
        add_child(b)
    modal = Panel.new()
    modal.visible = false
    add_child(modal)
    modal_title = Label.new()
    modal_title.add_theme_font_size_override("font_size", 25)
    modal_title.add_theme_color_override("font_color", C_GOLD)
    modal.add_child(modal_title)
    modal_body = Label.new()
    modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    modal_body.add_theme_font_size_override("font_size", 18)
    modal_body.add_theme_color_override("font_color", C_TEXT)
    modal.add_child(modal_body)
    modal_action = _make_button("CLOSE", _close_modal)
    modal.add_child(modal_action)
    _sync_ui()

func _make_button(text: String, cb: Callable) -> Button:
    var b := Button.new()
    b.text = text
    b.focus_mode = Control.FOCUS_ALL
    b.add_theme_font_size_override("font_size", 16)
    b.add_theme_color_override("font_color", C_TEXT)
    b.add_theme_color_override("font_pressed_color", C_GOLD)
    b.pressed.connect(cb)
    return b

func _sync_ui() -> void:
    var w := size.x
    var h := size.y
    title_label.visible = screen != Screen.GAME
    hint_label.visible = screen != Screen.GAME
    start_button.visible = screen == Screen.MENU
    continue_button.visible = screen == Screen.MENU
    for b in menu_buttons: b.visible = screen == Screen.GAME
    for b in action_buttons: b.visible = screen == Screen.GAME
    if screen == Screen.SPLASH:
        title_label.position = Vector2(w*0.2, h*0.38)
        title_label.size = Vector2(w*0.6, 70)
        hint_label.position = Vector2(w*0.2, h*0.49)
        hint_label.size = Vector2(w*0.6, 40)
        hint_label.text = "A maritime company through the age of sail, steam and industry"
    elif screen == Screen.MENU:
        title_label.position = Vector2(w*0.18, h*0.24)
        title_label.size = Vector2(w*0.64, 80)
        hint_label.position = Vector2(w*0.18, h*0.37)
        hint_label.size = Vector2(w*0.64, 50)
        hint_label.text = "Build a shipping company. Lease first. Own the sea later."
        start_button.position = Vector2(w*0.38, h*0.50)
        start_button.size = Vector2(w*0.24, 56)
        continue_button.position = Vector2(w*0.38, h*0.60)
        continue_button.size = Vector2(w*0.24, 56)
    else:
        var bw := (w - 24.0) / NAV.size()
        for i in range(NAV.size()):
            menu_buttons[i].position = Vector2(12 + bw*i, 70)
            menu_buttons[i].size = Vector2(bw-4, 46)
        _layout_actions()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and is_instance_valid(title_label): _sync_ui()

func _layout_actions() -> void:
    var labels := _action_labels()
    var x := size.x - 320.0
    var y := 502.0
    for i in range(action_buttons.size()):
        var b := action_buttons[i]
        b.text = labels[i]
        b.position = Vector2(x + (i%2)*150, y + int(i/2)*58)
        b.size = Vector2(140, 48)
        b.disabled = labels[i] == "—"

func _action_labels() -> Array[String]:
    match tab:
        "COMPANY": return ["Company profile", "Rename", "Reputation", "Milestones", "Ledger", "—"]
        "PORT": return ["Lease warehouse", "Buy supplies", "Hire stevedores", "Dock services", "Port contract", "Expand office"]
        "FLEET": return ["Charter vessel", "Buy vessel", "Ship details", "Assign captain", "Insurance", "Lay up ship"]
        "CONTRACTS": return ["Accept Dublin", "Accept London", "Market board", "Active jobs", "Cargo rates", "Cancel job"]
        "CREW": return ["Hire captain", "Hire crew", "Roster", "Wages", "Training", "Shore leave"]
        "SUPPLY": return ["Buy food", "Buy water", "Buy coal", "Spare parts", "Medical", "Inventory"]
        "SHIPYARD": return ["Rent dry dock", "Repair ship", "Retrofit", "Buy shipyard", "Build ship", "Tender board"]
        "RESEARCH": return ["Hull research", "Steam tech", "Navigation", "Materials", "Hire engineer", "Patents"]
        "FINANCE": return ["Cash flow", "Loan", "Insurance", "Assets", "Tax", "Investors"]
    return ["—","—","—","—","—","—"]

func _on_new_company() -> void:
    cash = 18500; reputation = 8; owned_ships = 0; chartered_ships = 1; crew_count = 16; captains = 1; warehouse_level = 1; yard_owned = false
    date_day = 14; date_month = 6; date_year = 1872; tab = "PORT"; screen = Screen.GAME
    _sync_ui()

func _on_continue() -> void:
    screen = Screen.GAME
    _sync_ui()

func _set_tab(name: String) -> void:
    tab = name
    _layout_actions()

func _handle_action(index: int) -> void:
    match tab:
        "PORT": _port_action(index)
        "FLEET": _fleet_action(index)
        "CONTRACTS": _contract_action(index)
        "CREW": _crew_action(index)
        "SUPPLY": _supply_action(index)
        "SHIPYARD": _yard_action(index)
        "RESEARCH": _research_action(index)
        "FINANCE": _finance_action(index)
        _: _show_modal("MANAGEMENT", "This module is connected to the company simulation. More controls unlock as the company expands.")

func _port_action(i:int) -> void:
    if i == 0:
        if cash >= 900:
            cash -= 900; warehouse_level += 1; notifications.push_front("Warehouse lease expanded.")
            _show_modal("LEASE SIGNED", "Additional warehouse space secured for £900. Cargo handling capacity increased.")
        else: _not_enough_cash()
    elif i == 4: _show_modal("PORT AGREEMENT", "Liverpool grants commercial berth access. Reputation unlocks long-term berth and terminal concessions.")
    else: _show_modal("PORT SERVICES", "You are a tenant. Services are paid to the port operator until you obtain your own facilities.")

func _fleet_action(i:int) -> void:
    if i == 0:
        if cash >= 1200:
            cash -= 1200; chartered_ships += 1; _show_modal("VESSEL CHARTERED", "Brig 'North Star' joins for 90 days. Charter fee: £1,200.")
        else: _not_enough_cash()
    elif i == 1:
        if cash >= 14500:
            cash -= 14500; owned_ships += 1; _show_modal("VESSEL PURCHASED", "You now own a 320-ton coastal steamer. Ownership removes charter cost but adds maintenance and depreciation.")
        else: _show_modal("VESSEL MARKET", "A suitable coastal steamer costs £14,500. Current cash: £%d." % cash)
    else: _show_modal("FLEET MANAGEMENT", "Owned and chartered vessels, condition, insurance and captain assignment are managed here.")

func _contract_action(i:int) -> void:
    if i == 0:
        current_contract = "Liverpool → Dublin • Machinery"; contract_days = 5; contract_reward = 780
        _show_modal("CONTRACT ACCEPTED", "Cargo: Machinery\nRoute: Liverpool → Dublin\nDeadline: 5 days\nGross reward: £780")
    elif i == 1:
        current_contract = "Liverpool → London • Cotton goods"; contract_days = 7; contract_reward = 1150
        _show_modal("CONTRACT ACCEPTED", "Cargo: Cotton goods\nRoute: Liverpool → London\nDeadline: 7 days\nGross reward: £1,150")
    else: _show_modal("CONTRACT MARKET", "Contracts vary by cargo demand, distance, deadlines, risk, port access and reputation.")

func _crew_action(i:int) -> void:
    if i == 0:
        if cash >= 350: cash -= 350; captains += 1; _show_modal("CAPTAIN HIRED", "Captain Edward Hale joined. Strong navigation lets you delegate more voyage events.")
        else: _not_enough_cash()
    elif i == 1:
        if cash >= 180: cash -= 180; crew_count += 6; _show_modal("CREW HIRED", "6 sailors signed on. Payroll rises, but another small vessel can be crewed.")
        else: _not_enough_cash()
    else: _show_modal("PERSONNEL", "Captains, engineers and senior crew have skills, traits, wages and loyalty. Rivals can recruit your best people.")

func _supply_action(i:int) -> void:
    var costs := [90, 35, 220, 140, 55]
    if i < 5:
        if cash >= costs[i]: cash -= costs[i]; _show_modal("SUPPLIES PURCHASED", "Supplies loaded into company inventory. Voyage planners reserve them before departure.")
        else: _not_enough_cash()
    else: _show_modal("INVENTORY", "Food 18 days • water 23 days • coal 41 t • spare parts 7 crates • medical 3 crates")

func _yard_action(i:int) -> void:
    if i == 0: _show_modal("DRY DOCK QUOTE", "Mersey Iron Works offers Dry Dock No. 3 for £85/day. Queue: 4 days.")
    elif i == 3:
        if cash >= 48000: cash -= 48000; yard_owned = true; _show_modal("SHIPYARD ACQUIRED", "A small riverside yard is yours. Repair company ships, accept outside work and unlock construction.")
        else: _show_modal("SHIPYARD FOR SALE", "Riverside Works\nPrice: £48,000\nSlipway, workshop, stores and 34 workers.\nCurrent cash: £%d" % cash)
    elif i == 4:
        if yard_owned: _show_modal("SHIP DESIGN", "Select hull, propulsion, cargo arrangement and build standard. Engineers determine cost, reliability and delivery time.")
        else: _show_modal("LOCKED", "Acquire or construct a shipyard before building your own vessels.")
    elif i == 5: _show_modal("TENDER BOARD", "Companies and governments issue vessel tenders. Price, delivery, capacity, reputation and technology determine the winner.")
    else: _show_modal("SHIPYARD", "Use outside yards now; later vertical integration turns repair expenses into revenue.")

func _research_action(i:int) -> void:
    var topics := ["Iron hull construction", "Compound steam engine", "Marine chronometer practice", "Improved riveting", "Engineer recruitment", "Patent exchange"]
    _show_modal("R&D • " + topics[i], "Research is limited by era, engineers, facilities, budget and technologies licensed or acquired from rivals.")

func _finance_action(i:int) -> void:
    if i == 1: _show_modal("BANKING", "Liverpool Commercial Bank offers a £10,000 secured loan at 6.8% annual interest.")
    else: _show_modal("FINANCE", "Cash £%d\nAssets £%d\nWeekly payroll £%d\nCharter obligations £%d" % [cash, 7400 + owned_ships*14500, 210 + crew_count*3, chartered_ships*96])

func _not_enough_cash() -> void:
    _show_modal("INSUFFICIENT FUNDS", "The company does not have enough available cash for this decision.")

func _show_modal(title:String, body:String) -> void:
    modal.visible = true
    modal.position = Vector2(size.x*0.27, size.y*0.24)
    modal.size = Vector2(size.x*0.46, size.y*0.42)
    modal_title.position = Vector2(24, 22); modal_title.size = Vector2(modal.size.x-48, 40); modal_title.text = title
    modal_body.position = Vector2(24, 72); modal_body.size = Vector2(modal.size.x-48, modal.size.y-145); modal_body.text = body
    modal_action.position = Vector2(modal.size.x-150, modal.size.y-60); modal_action.size = Vector2(125, 42)

func _close_modal() -> void: modal.visible = false

func _advance_day() -> void:
    date_day += 1
    contract_days = max(contract_days - 1, 0)
    if contract_days == 0 and current_contract != "":
        cash += contract_reward; reputation += 1; notifications.push_front("Contract delivered. £%d received." % contract_reward); current_contract = ""
    if date_day > 30:
        date_day = 1; date_month += 1
        if date_month > 12: date_month = 1; date_year += 1

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), C_BG)
    if screen == Screen.SPLASH: _draw_splash()
    elif screen == Screen.MENU: _draw_menu_scene()
    else: _draw_game()

func _draw_splash() -> void:
    var w := size.x; var h := size.y
    _draw_sky(Rect2(0,0,w,h*0.56)); draw_rect(Rect2(0,h*0.56,w,h*0.44), C_WATER)
    for i in range(14):
        var yy := h*0.59 + i*18; draw_line(Vector2(0,yy), Vector2(w,yy+sin(elapsed*2+i)*4), C_WATER2, 2)
    var ship_x := lerp(-220.0, w+120.0, clamp(splash_t/3.2,0.0,1.0)); _draw_steamship(Vector2(ship_x,h*0.61), 1.5)
    _text("EST. 1750", Vector2(w*0.46,h*0.56), 18, C_GOLD)

func _draw_menu_scene() -> void:
    var w := size.x; var h := size.y
    _draw_sky(Rect2(0,0,w,h*0.50)); _draw_harbor(Rect2(0,h*0.45,w,h*0.55), true); draw_rect(Rect2(0,0,w,h), Color(0.02,0.05,0.07,0.32))

func _draw_game() -> void:
    _draw_topbar(); _draw_harbor(Rect2(12,126,size.x-350, size.y-142), false); _draw_right_panel(); _draw_bottom_status()

func _draw_topbar() -> void:
    draw_rect(Rect2(0,0,size.x,62), Color("#091920")); draw_line(Vector2(0,61),Vector2(size.x,61),C_GOLD,2)
    _text(company_name, Vector2(18,14), 26, C_TEXT); _text("%02d %02d %d" % [date_day,date_month,date_year], Vector2(size.x*0.30,18), 19, C_MUTED)
    _text("£%s" % _money(cash), Vector2(size.x*0.47,15), 26, C_GOLD); _text("REP %d" % reputation, Vector2(size.x*0.63,18), 19, C_MUTED); _text("x%d" % sim_speed, Vector2(size.x-86,18), 19, C_TEXT)

func _draw_right_panel() -> void:
    var x := size.x-330.0; var y := 126.0
    draw_rect(Rect2(x,y,318,size.y-y-14), C_PANEL); draw_rect(Rect2(x,y,318,44), C_PANEL2); _text(tab, Vector2(x+14,y+11), 21, C_GOLD)
    var yy := y+62.0
    for s in _panel_lines(): _text(s, Vector2(x+14,yy), 16, C_TEXT if not s.begins_with("•") else C_MUTED); yy += 26
    draw_line(Vector2(x+12,478),Vector2(x+304,478),C_LINE,1); _text("ACTIONS", Vector2(x+14,484), 16, C_MUTED)

func _panel_lines() -> Array[String]:
    match tab:
        "PORT": return ["Liverpool, England", "Commercial berth: ACTIVE", "Warehouse: Level %d" % warehouse_level, "Office: Rented", "Shipyard: %s" % ("OWNED" if yard_owned else "External"), "", "Traffic today: 27 vessels", "Berth wait: 6h"]
        "FLEET": return ["Owned vessels: %d" % owned_ships, "Chartered: %d" % chartered_ships, "At sea: 1", "In port: %d" % max(0,owned_ships+chartered_ships-1), "", "Mercy • Brig • 86%", "North Star • charter option"]
        "CONTRACTS": return ["ACTIVE", current_contract if current_contract != "" else "No active voyage", "Deadline: %d days" % contract_days, "", "MARKET", "Dublin • Machinery • £780", "London • Cotton • £1,150"]
        "CREW": return ["Captains: %d" % captains, "Crew employed: %d" % crew_count, "Weekly payroll: £%d" % (210+crew_count*3), "", "Morale: 78%", "Fatigue: Low", "Open positions: 4"]
        "SUPPLY": return ["Company stores", "Food: 18 days", "Water: 23 days", "Coal: 41 tons", "Spare parts: 7 crates", "Medical: 3 crates", "", "Prices: Stable"]
        "SHIPYARD": return ["Own yard: %s" % ("YES" if yard_owned else "NO"), "Mersey Iron Works: available", "Dry-dock queue: 4 days", "Repair rate: £85/day", "", "Riverside Works for sale", "Asking price: £48,000"]
        "RESEARCH": return ["ERA: Early Industrial", "Current year: %d" % date_year, "", "Iron Hulls: 12%", "Steam Efficiency: 21%", "Navigation: 34%", "Materials: 9%", "Researchers: 0"]
        "FINANCE": return ["Cash: £%s" % _money(cash), "Assets: £%s" % _money(7400+owned_ships*14500), "Debt: £0", "", "Weekly revenue: £610", "Weekly costs: £438", "Net: +£172"]
        "COMPANY": return [company_name, "Home: %s" % home_port, "Founded: 1872", "Reputation: %d" % reputation, "", "Business: Shipping", "Stage: Independent trader"]
    return ["Management module"]

func _draw_bottom_status() -> void:
    var y := size.y-38.0; draw_rect(Rect2(12,y,size.x-362,28),Color("#0a1b22"))
    var status := current_contract if current_contract != "" else "No active contract — browse the contract market"
    _text(status,Vector2(22,y+5),14,C_MUTED); _text("LIVE PORT • ships, cranes, trains & traffic simulated",Vector2(size.x*0.50,y+5),14,C_GREEN)

func _draw_harbor(r: Rect2, decorative: bool) -> void:
    var x := r.position.x; var y := r.position.y; var w := r.size.x; var h := r.size.y
    draw_rect(r, Color("#43604b")); var water := Rect2(x+w*0.47,y+h*0.18,w*0.53,h*0.82); draw_rect(water,C_WATER)
    for i in range(15):
        var yy := water.position.y+10+i*20; var off := fmod(elapsed*18+i*9,72.0); draw_line(Vector2(water.position.x+off,yy),Vector2(min(water.position.x+water.size.x,water.position.x+off+26),yy),C_WATER2,1)
    draw_rect(Rect2(x,y+h*0.08,w*0.50,34),C_ROAD); draw_rect(Rect2(x+w*0.06,y+h*0.23,w*0.39,22),Color("#595a55"))
    for k in range(2):
        var ry := y+h*0.30+k*13; draw_line(Vector2(x,ry),Vector2(x+w*0.47,ry),Color("#252b2d"),3)
        for t in range(0,int(w*0.47),20): draw_line(Vector2(x+t,ry-4),Vector2(x+t,ry+4),Color("#7b6b51"),1)
    for i in range(6): _draw_building(Vector2(x+28+i*76,y+h*0.39+(i%2)*20), Vector2(60,44), i%3)
    _draw_factory(Vector2(x+w*0.24,y+h*0.56)); _draw_tanks(Vector2(x+34,y+h*0.60))
    draw_rect(Rect2(x+w*0.42,y+h*0.43,w*0.09,h*0.55),Color("#5b584c")); draw_rect(Rect2(x+w*0.28,y+h*0.84,w*0.32,h*0.12),Color("#59584d"))
    for i in range(4): _draw_crane(Vector2(x+w*0.44+i*34,y+h*0.70),0.85)
    for i in range(3): _draw_crane(Vector2(x+w*0.32+i*48,y+h*0.91),0.72)
    var ship1x := water.position.x + fmod(elapsed*26, max(120.0,water.size.x-120)); _draw_cargo_ship(Vector2(ship1x, water.position.y+water.size.y*0.28),0.72)
    var ship2x := water.position.x+water.size.x - fmod(elapsed*17+160, max(100.0,water.size.x-100)); _draw_tug(Vector2(ship2x,water.position.y+water.size.y*0.66),0.8)
    _draw_steamship(Vector2(water.position.x+water.size.x*0.23, water.position.y+water.size.y*0.49),0.68)
    var carx := x + fmod(elapsed*42,w*0.46); draw_rect(Rect2(carx,y+h*0.095,14,7),Color("#a74d35"))
    var truckx := x+w*0.45-fmod(elapsed*30,w*0.42); draw_rect(Rect2(truckx,y+h*0.115,21,8),Color("#d1b15d"))
    var trainx := x+fmod(elapsed*34,w*0.40)
    for c in range(5): draw_rect(Rect2(trainx-c*24,y+h*0.285,21,9),Color("#273d50"))
    for j in range(7):
        var puff_y := y+h*0.49-fmod(elapsed*13+j*11,80.0); var puff_x := x+w*0.37+sin(elapsed+j)*8; draw_circle(Vector2(puff_x,puff_y),4+(j%3),Color(0.65,0.67,0.64,0.38))
    if not decorative:
        _tag(Vector2(x+34,y+h*0.36),"LEASED WAREHOUSE L%d" % warehouse_level); _tag(Vector2(x+w*0.29,y+h*0.78),"MERSEY IRON WORKS"); _tag(Vector2(x+w*0.68,y+h*0.12),"RIVER TRAFFIC")

func _tag(pos:Vector2,text:String) -> void:
    var width := max(130.0,text.length()*8.5); draw_rect(Rect2(pos,Vector2(width,27)),Color(0.03,0.08,0.10,0.90)); draw_rect(Rect2(pos,Vector2(width,27)),C_GOLD,false,1); _text(text,pos+Vector2(8,5),13,C_TEXT)

func _draw_building(pos:Vector2, sz:Vector2, variant:int) -> void:
    draw_rect(Rect2(pos,sz),C_WALL); var roof := C_ROOF if variant != 2 else Color("#3f5867"); draw_colored_polygon(PackedVector2Array([pos+Vector2(-4,0),pos+Vector2(sz.x*0.5,-13),pos+Vector2(sz.x+4,0)]),roof)
    for xx in range(8,int(sz.x)-6,15):
        for yy in range(12,int(sz.y)-6,17): draw_rect(Rect2(pos+Vector2(xx,yy),Vector2(6,7)),Color("#263943"))

func _draw_factory(pos:Vector2) -> void:
    draw_rect(Rect2(pos,Vector2(130,66)),Color("#94866e"))
    for i in range(3):
        var px := pos.x+20+i*38; draw_rect(Rect2(px,pos.y-62,15,62),Color("#6d655a")); draw_rect(Rect2(px-3,pos.y-64,21,7),Color("#443d38"))
    draw_colored_polygon(PackedVector2Array([pos,pos+Vector2(25,-14),pos+Vector2(52,0),pos+Vector2(78,-14),pos+Vector2(105,0),pos+Vector2(130,0)]),Color("#65483e"))

func _draw_tanks(pos:Vector2) -> void:
    for i in range(3): draw_rect(Rect2(pos+Vector2(i*40,0),Vector2(30,42)),Color("#a5aaa5")); draw_arc(pos+Vector2(i*40+15,0),15,PI,TAU,18,Color("#d1d2c6"),4)

func _draw_crane(pos:Vector2, sc:float) -> void:
    var c := Color("#d2a93b"); draw_line(pos,pos+Vector2(0,-70)*sc,c,5*sc); draw_line(pos+Vector2(0,-67)*sc,pos+Vector2(48,-67)*sc,c,5*sc); draw_line(pos+Vector2(0,-67)*sc,pos+Vector2(-12,-25)*sc,c,4*sc)
    var hookx := 32 + sin(elapsed*0.8+pos.x)*8; draw_line(pos+Vector2(hookx,-65)*sc,pos+Vector2(hookx,-22)*sc,Color("#2a2b28"),2); draw_rect(Rect2(pos+Vector2(hookx-5,-22)*sc,Vector2(10,5)*sc),Color("#302e29"))

func _draw_cargo_ship(pos:Vector2, sc:float) -> void:
    draw_colored_polygon(PackedVector2Array([pos+Vector2(-80,0)*sc,pos+Vector2(70,0)*sc,pos+Vector2(58,18)*sc,pos+Vector2(-65,18)*sc]),Color("#432f2e"));
    for i in range(5): draw_rect(Rect2(pos+Vector2(-50+i*21,-13)*sc,Vector2(18,13)*sc),Color("#89613d"))
    draw_rect(Rect2(pos+Vector2(35,-26)*sc,Vector2(25,26)*sc),Color("#d8d2be")); draw_rect(Rect2(pos+Vector2(43,-36)*sc,Vector2(5,10)*sc),Color("#303438"))

func _draw_tug(pos:Vector2, sc:float) -> void:
    draw_colored_polygon(PackedVector2Array([pos+Vector2(-34,0)*sc,pos+Vector2(30,0)*sc,pos+Vector2(20,13)*sc,pos+Vector2(-25,13)*sc]),Color("#8b4330")); draw_rect(Rect2(pos+Vector2(-6,-20)*sc,Vector2(26,20)*sc),Color("#d8c99f")); draw_rect(Rect2(pos+Vector2(2,-29)*sc,Vector2(4,9)*sc),Color("#242b30"))

func _draw_steamship(pos:Vector2, sc:float) -> void:
    draw_colored_polygon(PackedVector2Array([pos+Vector2(-86,0)*sc,pos+Vector2(76,0)*sc,pos+Vector2(60,20)*sc,pos+Vector2(-72,20)*sc]),Color("#222d32")); draw_rect(Rect2(pos+Vector2(-42,-22)*sc,Vector2(84,22)*sc),Color("#d2c8a8"))
    for i in range(2): draw_rect(Rect2(pos+Vector2(-18+i*30,-48)*sc,Vector2(13,26)*sc),Color("#5b3027")); draw_rect(Rect2(pos+Vector2(-20+i*30,-49)*sc,Vector2(17,5)*sc),Color("#20252a"))
    draw_line(pos+Vector2(50,-20)*sc,pos+Vector2(50,-66)*sc,Color("#ded4b8"),2)

func _draw_sky(r:Rect2) -> void:
    for i in range(12):
        var t := float(i)/12.0; var c := Color("#7796a1").lerp(Color("#d8b778"),t); draw_rect(Rect2(r.position+Vector2(0,r.size.y*t),Vector2(r.size.x,r.size.y/12.0+2)),c)

func _text(text:String, pos:Vector2, font_size:int, color:Color) -> void:
    draw_string(ThemeDB.fallback_font,pos+Vector2(0,font_size),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _money(v:int) -> String:
    var s := str(v); var out := ""
    while s.length() > 3:
        out = "," + s.substr(s.length()-3,3) + out; s = s.substr(0,s.length()-3)
    return s + out
