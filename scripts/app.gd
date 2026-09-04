extends Control

const PortViewScript = preload("res://scripts/port_view.gd")
const STUDIO_SPLASH = preload("res://assets/studio_splash.png")

const SAVE_PATH := "user://logistics_inc_save_v03.json"

var state := {}
var current_page := "PORT"
var game_running := false
var time_speed := 1
var day_accumulator := 0.0
var notification_text := ""
var pending_event := {}
var event_modal: PanelContainer
var event_title: Label
var event_body: Label
var top_cash: Label
var top_date: Label
var top_company: Label
var top_status: Label
var side_title: Label
var side_body: RichTextLabel
var action_box: VBoxContainer
var port_view: Control
var root_game: Control
var menu_root: Control
var splash_root: Control
var music_enabled := true
var sound_enabled := true
var ambience_enabled := true
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var fx_player: AudioStreamPlayer
var studio_player: AudioStreamPlayer
var toast: Label
var intro_elapsed := 0.0
var intro_can_skip := false

var contract_templates := [
	{"id":"dublin","from":"Liverpool","to":"Dublin","cargo":"Wool & manufactured goods","reward":1850,"days":5,"risk":0.06},
	{"id":"london","from":"Liverpool","to":"London","cargo":"Machinery & tools","reward":2750,"days":7,"risk":0.08},
	{"id":"lisbon","from":"Liverpool","to":"Lisbon","cargo":"Textiles","reward":4400,"days":13,"risk":0.12},
	{"id":"cadiz","from":"Liverpool","to":"Cadiz","cargo":"Ironware","reward":5200,"days":16,"risk":0.15}
]

func _ready() -> void:
	get_window().mode = Window.MODE_FULLSCREEN
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_window().content_scale_size = Vector2i(1280, 720)
	set_process(true)
	_build_audio()
	_build_splash()

func _build_audio() -> void:
	studio_player = AudioStreamPlayer.new()
	studio_player.stream = _make_audio_stream("studio", 2.5, false)
	studio_player.volume_db = -7
	add_child(studio_player)
	fx_player = AudioStreamPlayer.new()
	fx_player.volume_db = -7
	add_child(fx_player)
	music_player = AudioStreamPlayer.new()
	music_player.stream = _make_audio_stream("music", 8.0, true)
	music_player.volume_db = -22
	add_child(music_player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.stream = _make_audio_stream("harbor", 6.0, true)
	ambience_player.volume_db = -18
	add_child(ambience_player)

func _make_audio_stream(kind:String, duration:float, looped:bool) -> AudioStreamWAV:
	var sample_rate := 11025
	var frames := int(duration * sample_rate)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var seed := 1234567
	for i in range(frames):
		var t := float(i) / float(sample_rate)
		var v := 0.0
		if kind == "studio":
			for note in [[0.05,392.0],[0.42,523.25],[0.84,659.25]]:
				var dt:float = t - float(note[0])
				if dt >= 0.0:
					v += 0.22 * exp(-2.8 * dt) * (sin(TAU * float(note[1]) * dt) + 0.25 * sin(TAU * float(note[1]) * 2.0 * dt))
		elif kind == "click":
			v = 0.26 * exp(-38.0 * t) * (sin(TAU * 680.0 * t) + 0.35 * sin(TAU * 1020.0 * t))
		elif kind == "event":
			var f := 440.0 if t < 0.18 else 554.37
			v = 0.18 * exp(-5.0 * fposmod(t, 0.18)) * sin(TAU * f * t)
		elif kind == "harbor":
			seed = int((1103515245 * seed + 12345) & 0x7fffffff)
			var noise := (float(seed % 2000) / 1000.0) - 1.0
			v = 0.016 * noise + 0.012 * sin(TAU * 47.0 * t) + 0.006 * sin(TAU * 94.0 * t)
			var bell_phase := fposmod(t, 3.0)
			if bell_phase < 0.28:
				v += 0.025 * exp(-9.0 * bell_phase) * sin(TAU * 720.0 * bell_phase)
		elif kind == "music":
			var chord_index := int(t / 2.0) % 4
			var roots := [130.81, 110.0, 87.31, 98.0]
			var root:float = roots[chord_index]
			v = 0.025 * sin(TAU * root * t) + 0.018 * sin(TAU * root * 1.25 * t) + 0.015 * sin(TAU * root * 1.5 * t)
			var step := int(t * 2.0) % 8
			var melody := [261.63,329.63,392.0,329.63,293.66,329.63,349.23,293.66]
			v += 0.012 * sin(TAU * float(melody[step]) * t)
		var sample := int(clamp(v, -0.95, 0.95) * 32767.0)
		bytes.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = frames
	return stream

func _build_splash() -> void:
	splash_root = Control.new(); splash_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(splash_root)
	var bg := ColorRect.new(); bg.color = Color("#071018"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); splash_root.add_child(bg)
	var tex := TextureRect.new(); tex.texture = STUDIO_SPLASH; tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); splash_root.add_child(tex)
	var hint := Label.new(); hint.text = "TCH STUDIO  •  PRESENTS"; hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hint.add_theme_font_size_override("font_size", 18); hint.add_theme_color_override("font_color", Color("#b8c8d0")); hint.anchor_left = 0.2; hint.anchor_right = 0.8; hint.anchor_top = 0.88; hint.anchor_bottom = 0.95; splash_root.add_child(hint)
	studio_player.play()
	intro_elapsed = 0.0
	intro_can_skip = false

func _unhandled_input(event:InputEvent) -> void:
	if splash_root != null and is_instance_valid(splash_root):
		if intro_can_skip and ((event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed) or event.is_action_pressed("ui_accept")):
			_finish_intro()

func _process(delta:float) -> void:
	if splash_root != null and is_instance_valid(splash_root):
		intro_elapsed += delta
		intro_can_skip = intro_elapsed > 0.55
		if intro_elapsed > 2.6:
			_finish_intro()
		return
	if not game_running or state.is_empty() or not pending_event.is_empty():
		return
	var days_per_second := 0.22 * float(time_speed)
	day_accumulator += delta * days_per_second
	while day_accumulator >= 1.0:
		day_accumulator -= 1.0
		_advance_day()

func _finish_intro() -> void:
	if splash_root == null or not is_instance_valid(splash_root): return
	splash_root.queue_free(); splash_root = null
	_build_main_menu()

func _build_main_menu() -> void:
	menu_root = Control.new(); menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(menu_root)
	var bg := MainMenuArt.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu_root.add_child(bg)
	var shade := ColorRect.new(); shade.color = Color(0.015,0.025,0.035,0.38); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu_root.add_child(shade)
	var panel := PanelContainer.new(); panel.anchor_left=0.055; panel.anchor_top=0.09; panel.anchor_right=0.39; panel.anchor_bottom=0.91; panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025,0.07,0.095,0.95), Color("#b88b37"), 2)); menu_root.add_child(panel)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 12); panel.add_child(vb)
	var brand := _label("LOGISTICS INC.", 42, Color("#f1cf77")); brand.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(brand)
	var sub := _label("MARITIME BUSINESS SIMULATOR", 16, Color("#b9cbd4")); sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(sub)
	var era := _label("1750  →  FUTURE", 14, Color("#8ea9b6")); era.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(era)
	vb.add_child(HSeparator.new())
	var continue_btn := _button("CONTINUE", 18)
	continue_btn.disabled = not FileAccess.file_exists(SAVE_PATH)
	continue_btn.pressed.connect(_menu_continue)
	vb.add_child(continue_btn)
	var new_btn := _button("NEW COMPANY", 18)
	new_btn.pressed.connect(_menu_new)
	vb.add_child(new_btn)
	var load_btn := _button("LOAD GAME", 18)
	load_btn.disabled = not FileAccess.file_exists(SAVE_PATH)
	load_btn.pressed.connect(_menu_continue)
	vb.add_child(load_btn)
	var options_btn := _button("OPTIONS", 18)
	options_btn.pressed.connect(_menu_options)
	vb.add_child(options_btn)
	var credits_btn := _button("CREDITS", 18)
	credits_btn.pressed.connect(_menu_credits)
	vb.add_child(credits_btn)
	var studio := _label("TCH STUDIO", 20, Color("#f0cf7b")); studio.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; studio.size_flags_vertical=Control.SIZE_EXPAND_FILL; studio.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM; vb.add_child(studio)
	var version := _label("ALPHA v0.3.0 • ORIGINAL AUDIO & ART", 12, Color("#829aa7")); version.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(version)

func _menu_continue() -> void:
	_click()
	_load_game()

func _menu_new() -> void:
	_click()
	_new_game()

func _menu_options() -> void:
	_click()
	_show_menu_options()

func _menu_credits() -> void:
	_click()
	_show_menu_credits()

func _close_popup(p:PanelContainer) -> void:
	_click()
	if is_instance_valid(p):
		p.queue_free()

func _cleanup_overlay(overlay:ColorRect) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()

func _save_pressed() -> void:
	_click()
	_save_game()

func _clear_toast_if_matches(expected:String) -> void:
	if is_instance_valid(toast) and toast.text == expected:
		toast.text = ""

func _show_menu_options() -> void:
	var p := _popup_panel("OPTIONS")
	var box := p.get_meta("box") as VBoxContainer
	var m := CheckButton.new(); m.text="Music"; m.button_pressed=music_enabled; m.toggled.connect(func(v): music_enabled=v); box.add_child(m)
	var a := CheckButton.new(); a.text="Harbor ambience"; a.button_pressed=ambience_enabled; a.toggled.connect(func(v): ambience_enabled=v); box.add_child(a)
	var s := CheckButton.new(); s.text="Sound effects"; s.button_pressed=sound_enabled; s.toggled.connect(func(v): sound_enabled=v); box.add_child(s)
	var close := _button("CLOSE",16)
	close.pressed.connect(_close_popup.bind(p))
	box.add_child(close)

func _show_menu_credits() -> void:
	var p := _popup_panel("CREDITS")
	var box := p.get_meta("box") as VBoxContainer
	var l := _label("LOGISTICS INC.\n\nDeveloped by TCH Studio\nGame design: Maritime management simulation\nAudio: Original procedural compositions created for this project\nVisual direction: Original pixel-art inspired management interface\n\nNo third-party commercial audio is bundled in this build.", 16, Color("#dbe6e9")); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.size_flags_vertical=Control.SIZE_EXPAND_FILL; box.add_child(l)
	var close := _button("CLOSE",16)
	close.pressed.connect(_close_popup.bind(p))
	box.add_child(close)

func _popup_panel(title:String) -> PanelContainer:
	var overlay := ColorRect.new(); overlay.color=Color(0,0,0,0.58); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu_root.add_child(overlay)
	var p := PanelContainer.new(); p.anchor_left=.31; p.anchor_top=.18; p.anchor_right=.69; p.anchor_bottom=.82; p.add_theme_stylebox_override("panel",_panel_style(Color("#0c1d27"),Color("#b88b37"),2)); overlay.add_child(p)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation",14); p.add_child(box); p.set_meta("box",box)
	var t := _label(title,28,Color("#f1cf77")); t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; box.add_child(t)
	p.tree_exiting.connect(_cleanup_overlay.bind(overlay))
	return p

func _default_state() -> Dictionary:
	return {
		"company":"TCH Maritime Co.", "cash":12000, "day":1, "month":1, "year":1750,
		"reputation":12, "research":20, "port_level":1, "warehouse":false, "berth_lease":true,
		"yard_owned":false, "yard_progress":0, "yard_job":"", "yard_job_days":0,
		"chartered":false, "fleet":[], "captain":false, "mate":false, "carpenter":false, "crew":0,
		"food":35, "water":35, "spares":12, "medical":6, "morale":72,
		"active_contract":{}, "completed_contracts":0, "weekly_profit":0, "last_expense":0,
		"technologies":[], "notifications":["Welcome to Liverpool. Your company leases a modest office and one berth."],
		"tutorial_step":0
	}

func _new_game() -> void:
	state = _default_state()
	_start_game()
	_show_toast("New company founded. Start by chartering or buying a vessel.")

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_new_game(); return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		state = parsed
	else:
		state = _default_state()
	_start_game()
	_show_toast("Save loaded.")

func _save_game() -> void:
	if state.is_empty(): return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(state))
	_show_toast("Game saved.")

func _start_game() -> void:
	if menu_root and is_instance_valid(menu_root): menu_root.queue_free(); menu_root=null
	game_running = true
	_build_game_ui()
	if music_enabled: music_player.play()
	if ambience_enabled: ambience_player.play()
	_refresh_all()

func _build_game_ui() -> void:
	root_game = Control.new(); root_game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(root_game)
	var bg := ColorRect.new(); bg.color=Color("#07131b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root_game.add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left",10); margin.add_theme_constant_override("margin_right",10); margin.add_theme_constant_override("margin_top",8); margin.add_theme_constant_override("margin_bottom",8); root_game.add_child(margin)
	var root := VBoxContainer.new(); root.add_theme_constant_override("separation",6); margin.add_child(root)
	var top := PanelContainer.new(); top.custom_minimum_size=Vector2(0,58); top.add_theme_stylebox_override("panel",_panel_style(Color("#102531"),Color("#735d36"),1)); root.add_child(top)
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation",18); top.add_child(hb)
	top_company=_label("TCH Maritime Co.",20,Color("#f1d28a")); top_company.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hb.add_child(top_company)
	top_date=_label("",15,Color("#d5e1e5")); hb.add_child(top_date)
	top_cash=_label("",19,Color("#77d493")); hb.add_child(top_cash)
	top_status=_label("",13,Color("#9eb3bd")); hb.add_child(top_status)
	for pair in [["Ⅱ",0],["▶",1],["▶▶",2],["▶▶▶",4]]:
		var b:=_button(str(pair[0]),14); b.custom_minimum_size=Vector2(48,38); b.pressed.connect(_set_speed.bind(int(pair[1]))); hb.add_child(b)
	var save := _button("SAVE",13)
	save.pressed.connect(_save_pressed)
	hb.add_child(save)
	var menu := _button("MENU",13); menu.pressed.connect(_return_to_menu); hb.add_child(menu)
	var nav := HBoxContainer.new(); nav.custom_minimum_size=Vector2(0,48); nav.add_theme_constant_override("separation",4); root.add_child(nav)
	for n in ["PORT","FLEET","CONTRACTS","CREW","SUPPLY","SHIPYARD","RESEARCH","FINANCE"]:
		var b:=_button(n,13); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.pressed.connect(_open_page.bind(n)); nav.add_child(b)
	var body := HBoxContainer.new(); body.size_flags_vertical=Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",7); root.add_child(body)
	var viewport_panel := PanelContainer.new(); viewport_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL; viewport_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL; viewport_panel.add_theme_stylebox_override("panel",_panel_style(Color("#101a20"),Color("#604d31"),1)); body.add_child(viewport_panel)
	port_view = PortViewScript.new(); port_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); viewport_panel.add_child(port_view)
	var side := PanelContainer.new(); side.custom_minimum_size=Vector2(355,0); side.add_theme_stylebox_override("panel",_panel_style(Color("#0d202a"),Color("#735d36"),1)); body.add_child(side)
	var side_margin:=MarginContainer.new(); side_margin.add_theme_constant_override("margin_left",12); side_margin.add_theme_constant_override("margin_right",12); side_margin.add_theme_constant_override("margin_top",10); side_margin.add_theme_constant_override("margin_bottom",10); side.add_child(side_margin)
	var sv:=VBoxContainer.new(); sv.add_theme_constant_override("separation",9); side_margin.add_child(sv)
	side_title=_label("PORT",24,Color("#f1d28a")); sv.add_child(side_title)
	side_body=RichTextLabel.new(); side_body.bbcode_enabled=true; side_body.fit_content=false; side_body.scroll_active=true; side_body.size_flags_vertical=Control.SIZE_EXPAND_FILL; side_body.add_theme_font_size_override("normal_font_size",15); side_body.add_theme_color_override("default_color",Color("#dbe5e8")); sv.add_child(side_body)
	action_box=VBoxContainer.new(); action_box.add_theme_constant_override("separation",7); sv.add_child(action_box)
	toast=_label("",13,Color("#f1d28a")); toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; toast.custom_minimum_size=Vector2(0,26); root.add_child(toast)
	_build_event_modal()

func _build_event_modal() -> void:
	event_modal=PanelContainer.new(); event_modal.anchor_left=.25; event_modal.anchor_top=.25; event_modal.anchor_right=.75; event_modal.anchor_bottom=.76; event_modal.visible=false; event_modal.add_theme_stylebox_override("panel",_panel_style(Color("#0b1b24"),Color("#c19242"),3)); root_game.add_child(event_modal)
	var vb:=VBoxContainer.new(); vb.add_theme_constant_override("separation",12); event_modal.add_child(vb)
	event_title=_label("VOYAGE EVENT",25,Color("#f1c96b")); event_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(event_title)
	event_body=_label("",16,Color("#e2e7e8")); event_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; event_body.size_flags_vertical=Control.SIZE_EXPAND_FILL; vb.add_child(event_body)
	var actions:=HBoxContainer.new(); actions.add_theme_constant_override("separation",8); vb.add_child(actions)
	for i in range(3):
		var b:=_button("",14); b.name="Choice%d"%i; b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.pressed.connect(_resolve_event.bind(i)); actions.add_child(b)

func _return_to_menu() -> void:
	_click(); _save_game(); game_running=false
	music_player.stop(); ambience_player.stop()
	if root_game and is_instance_valid(root_game): root_game.queue_free(); root_game=null
	_build_main_menu()

func _set_speed(v:int) -> void:
	_click(); time_speed=v
	_refresh_top()

func _open_page(n:String) -> void:
	_click(); current_page=n; _refresh_side()

func _advance_day() -> void:
	state["day"] = int(state["day"]) + 1
	if int(state["day"]) > 30:
		state["day"] = 1; state["month"] = int(state["month"]) + 1
		if int(state["month"]) > 12:
			state["month"] = 1; state["year"] = int(state["year"]) + 1
	state["research"] = int(state["research"]) + 1
	if int(state["day"]) % 7 == 0:
		var expense := _weekly_expense()
		state["cash"] = int(state["cash"]) - expense
		state["last_expense"] = expense
		state["weekly_profit"] = -expense
		_push_notification("Weekly operating costs: £%s" % _money(expense))
	if not (state["active_contract"] as Dictionary).is_empty():
		var c:Dictionary = state["active_contract"]
		c["remaining"] = int(c["remaining"]) - 1
		state["food"] = max(0, int(state["food"]) - 1)
		state["water"] = max(0, int(state["water"]) - 1)
		if int(state["food"]) < 5 or int(state["water"]) < 5:
			state["morale"] = max(10, int(state["morale"]) - 3)
		if pending_event.is_empty() and randf() < float(c["risk"]) * (0.75 if bool(state["captain"]) else 1.35):
			_trigger_random_event()
		if int(c["remaining"]) <= 0 and pending_event.is_empty():
			_complete_contract()
	if int(state["yard_job_days"]) > 0:
		state["yard_job_days"] = int(state["yard_job_days"]) - 1
		if int(state["yard_job_days"]) <= 0:
			_complete_yard_job()
	_refresh_all()

func _weekly_expense() -> int:
	var v:=38
	if bool(state["warehouse"]): v += 24
	if bool(state["chartered"]): v += 126
	v += int(state["crew"]) * 3
	if bool(state["captain"]): v += 12
	if bool(state["mate"]): v += 8
	if bool(state["carpenter"]): v += 7
	v += (state["fleet"] as Array).size() * 18
	if bool(state["yard_owned"]): v += 70
	return v

func _trigger_random_event() -> void:
	var events := [
		{"title":"GALE AHEAD","body":"A fast-moving Atlantic gale crosses the route. Canvas and spars are under strain.","choices":["Reduce sail • +1 day","Use spares • £180","Press on • risk damage"],"type":"storm"},
		{"title":"SICK CREWMEN","body":"Several sailors report fever. The voyage can continue, but morale is slipping.","choices":["Use medicine","Divert • +2 days","Continue cautiously"],"type":"sickness"},
		{"title":"RIGGING DAMAGE","body":"A stay has snapped and the foremast rigging needs attention.","choices":["Repair with spares","Slow down • +1 day","Risk temporary fix"],"type":"rigging"},
		{"title":"CREW DISPUTE","body":"A pay dispute is spreading among deck crew after a difficult watch.","choices":["Pay £120 bonus","Captain intervenes","Ignore complaints"],"type":"morale"}
	]
	pending_event = events[randi()%events.size()].duplicate(true)
	if bool(state["captain"]) and pending_event["type"] in ["morale","sickness"]:
		_auto_resolve_event(); return
	fx_player.stream = _make_audio_stream("event", 0.42, false)
	if sound_enabled: fx_player.play()
	event_title.text=str(pending_event["title"])
	event_body.text=str(pending_event["body"]) + "\n\nNo senior captain is handling this automatically. Choose how the company responds."
	var actions:=event_modal.get_child(0).get_child(2) as HBoxContainer
	for i in range(3): (actions.get_child(i) as Button).text=str((pending_event["choices"] as Array)[i])
	event_modal.visible=true

func _auto_resolve_event() -> void:
	var typ:=str(pending_event["type"])
	if typ=="sickness" and int(state["medical"])>0: state["medical"]=max(0,int(state["medical"])-1)
	state["morale"]=min(100,int(state["morale"])+1)
	_push_notification("Captain resolved a minor voyage event: %s" % str(pending_event["title"]))
	pending_event={}

func _resolve_event(choice:int) -> void:
	_click()
	var typ:=str(pending_event.get("type",""))
	var c:Dictionary=state["active_contract"]
	if typ=="storm":
		if choice==0: c["remaining"]=int(c["remaining"])+1
		elif choice==1: state["cash"]=int(state["cash"])-180; state["spares"]=max(0,int(state["spares"])-2)
		else:
			state["morale"] = max(10, int(state["morale"]) - 7)
			if randf() < 0.35:
				c["remaining"] = int(c["remaining"]) + 2
	elif typ=="sickness":
		if choice==0 and int(state["medical"])>0: state["medical"]=int(state["medical"])-1
		elif choice==1: c["remaining"]=int(c["remaining"])+2; state["cash"]=int(state["cash"])-90
		else: state["morale"]=max(10,int(state["morale"])-5)
	elif typ=="rigging":
		if choice==0 and int(state["spares"])>=2: state["spares"]=int(state["spares"])-2
		elif choice==1: c["remaining"]=int(c["remaining"])+1
		else:
			state["morale"] = max(10, int(state["morale"]) - 4)
			if randf() < 0.30:
				c["remaining"] = int(c["remaining"]) + 2
	elif typ=="morale":
		if choice==0: state["cash"]=int(state["cash"])-120; state["morale"]=min(100,int(state["morale"])+8)
		elif choice==1 and bool(state["captain"]): state["morale"]=min(100,int(state["morale"])+5)
		else: state["morale"]=max(10,int(state["morale"])-8)
	pending_event={}; event_modal.visible=false
	if not c.is_empty() and int(c["remaining"])<=0: _complete_contract()
	_refresh_all()

func _complete_contract() -> void:
	var c:Dictionary=state["active_contract"]
	if c.is_empty(): return
	var reward:=int(c["reward"])
	state["cash"]=int(state["cash"])+reward
	state["weekly_profit"]=int(state["weekly_profit"])+reward
	state["reputation"]=min(100,int(state["reputation"])+2)
	state["completed_contracts"]=int(state["completed_contracts"])+1
	state["active_contract"]={}
	_push_notification("Contract completed at %s. Received £%s." % [str(c["to"]),_money(reward)])
	_show_toast("Cargo delivered • £%s received" % _money(reward))

func _accept_contract(index:int) -> void:
	_click()
	if not (state["active_contract"] as Dictionary).is_empty(): _show_toast("Finish the current voyage first."); return
	if not _has_vessel(): _show_toast("Charter or buy a vessel first."); return
	if int(state["food"]) < 10 or int(state["water"]) < 10: _show_toast("Provision at least 10 days of food and water."); return
	var c:Dictionary=contract_templates[index].duplicate(true); c["remaining"]=int(c["days"])
	state["active_contract"]=c
	_push_notification("Voyage departed: %s → %s (%s)." % [c["from"],c["to"],c["cargo"]])
	_show_toast("Voyage underway. Events may occur en route.")
	_refresh_all()

func _has_vessel() -> bool:
	return bool(state["chartered"]) or (state["fleet"] as Array).size()>0

func _buy_charter() -> void:
	_click()
	if bool(state["chartered"]):
		_show_toast("A charter vessel is already active.")
		return
	if _pay(850):
		state["chartered"] = true
		_push_notification("Chartered coastal brig 'Mercury' for £850 deposit.")
		_refresh_all()

func _buy_ship() -> void:
	_click()
	if _pay(8500):
		(state["fleet"] as Array).append({"name":"MV Endeavour","type":"Merchant Schooner","condition":100,"capacity":180,"owned":true})
		_push_notification("Purchased MV Endeavour for £8,500."); _refresh_all()

func _hire_role(role:String) -> void:
	_click()
	var costs={"captain":450,"mate":280,"carpenter":240}
	if bool(state[role]): _show_toast("Position already filled."); return
	if _pay(int(costs[role])): state[role]=true; _push_notification("Hired %s."%role.capitalize()); _refresh_all()

func _hire_crew() -> void:
	_click()
	if int(state["crew"]) >= 12:
		_show_toast("Deck crew is full.")
		return
	if _pay(160):
		state["crew"] = min(12, int(state["crew"]) + 4)
		_refresh_all()

func _buy_supply(kind:String, amount:int, cost:int) -> void:
	_click()
	if _pay(cost):
		state[kind] = int(state[kind]) + amount
		_refresh_all()

func _lease_warehouse() -> void:
	_click()
	if bool(state["warehouse"]):
		return
	if _pay(1200):
		state["warehouse"] = true
		state["port_level"] = max(2, int(state["port_level"]))
		_push_notification("Warehouse lease secured at Liverpool.")
		_refresh_all()

func _external_repair() -> void:
	_click()
	if not _has_vessel():
		_show_toast("No vessel needs service.")
		return
	if _pay(650):
		_push_notification("Commercial yard completed routine maintenance.")
		_show_toast("Fleet condition restored.")

func _buy_yard() -> void:
	_click()
	if bool(state["yard_owned"]):
		return
	if _pay(65000):
		state["yard_owned"] = true
		state["port_level"] = max(3, int(state["port_level"]))
		_push_notification("TCH Shipyard acquired. You can now repair and build in-house.")
		_refresh_all()

func _start_build_ship(for_sale:bool) -> void:
	_click()
	if not bool(state["yard_owned"]):
		_show_toast("Acquire a shipyard first.")
		return
	if int(state["yard_job_days"]) > 0:
		_show_toast("Shipyard is already busy.")
		return
	if _pay(9000):
		state["yard_job"] = "sale" if for_sale else "fleet"
		state["yard_job_days"] = 30
		_push_notification("Keel laid for a new merchant schooner.")
		_refresh_all()

func _complete_yard_job() -> void:
	var job:=str(state["yard_job"]); state["yard_job"]=""
	if job=="sale": state["cash"]=int(state["cash"])+12500; _push_notification("Newbuild delivered to customer for £12,500.")
	elif job=="fleet": (state["fleet"] as Array).append({"name":"TCH Pioneer %d"%((state["fleet"] as Array).size()+1),"type":"Yard-built Schooner","condition":100,"capacity":220,"owned":true}); _push_notification("New ship joined the company fleet.")

func _research(name:String,cost:int) -> void:
	_click()
	if (state["technologies"] as Array).has(name):
		return
	if int(state["research"]) < cost:
		_show_toast("Not enough research points.")
		return
	state["research"] = int(state["research"]) - cost
	(state["technologies"] as Array).append(name)
	_push_notification("Research completed: %s." % name)
	_refresh_all()

func _pay(cost:int) -> bool:
	if int(state["cash"]) < cost: _show_toast("Insufficient cash • need £%s"%_money(cost)); return false
	state["cash"]=int(state["cash"])-cost; return true

func _refresh_all() -> void:
	if root_game==null or not is_instance_valid(root_game): return
	_refresh_top(); _refresh_side()
	var activity:=0.7 + float((state["fleet"] as Array).size())*.18 + (0.18 if bool(state["warehouse"]) else 0.0) + float(int(state["completed_contracts"]))*.015
	port_view.set_business_state(int(state["port_level"]),bool(state["yard_owned"]),activity)

func _refresh_top() -> void:
	top_company.text=str(state["company"])
	top_cash.text="£"+_money(int(state["cash"]))
	top_date.text="%02d/%02d/%04d"%[int(state["day"]),int(state["month"]),int(state["year"])]
	var era:="AGE OF SAIL" if int(state["year"])<1815 else "STEAM TRANSITION"
	top_status.text="%s • REP %d • RP %d • %s"%[era,int(state["reputation"]),int(state["research"]),"PAUSED" if time_speed==0 else "x%d"%time_speed]

func _clear_actions() -> void:
	for c in action_box.get_children(): c.queue_free()

func _add_action(text:String,callback:Callable,disabled:=false) -> void:
	var b:=_button(text,14); b.disabled=disabled; b.pressed.connect(callback); action_box.add_child(b)

func _refresh_side() -> void:
	_clear_actions(); side_title.text=current_page
	var voyage:Dictionary=state["active_contract"]
	if current_page=="PORT":
		side_body.text="[b]Liverpool Harbour[/b]\nCompany status: Tenant operator\nPort development: Level %d\nBerth lease: Active\nWarehouse: %s\nOwned shipyard: %s\n\nYour infrastructure becomes visible in the living port scene as the company grows. Ships, tugs, rail traffic, cranes and factories continue moving while you manage."%[int(state["port_level"]),"Leased" if bool(state["warehouse"]) else "None","Yes" if bool(state["yard_owned"]) else "No"]
		_add_action("LEASE WAREHOUSE • £1,200",_lease_warehouse,bool(state["warehouse"]))
		_add_action("COMMERCIAL YARD SERVICE • £650",_external_repair,false)
		_add_action("ACQUIRE TCH SHIPYARD • £65,000",_buy_yard,bool(state["yard_owned"]))
	elif current_page=="FLEET":
		var txt="[b]Fleet & Charter Desk[/b]\nChartered vessel: %s\nOwned ships: %d\n\n"%["Brig Mercury" if bool(state["chartered"]) else "None",(state["fleet"] as Array).size()]
		for ship in (state["fleet"] as Array): txt += "• %s — %s — %d tons\n"%[ship["name"],ship["type"],int(ship["capacity"])]
		if (state["fleet"] as Array).is_empty(): txt += "You can begin without owning a ship. Charter capacity, earn cash, then purchase your first vessel."
		side_body.text=txt
		_add_action("CHARTER COASTAL BRIG • £850",_buy_charter,bool(state["chartered"]))
		_add_action("BUY MERCHANT SCHOONER • £8,500",_buy_ship,false)
	elif current_page=="CONTRACTS":
		if not voyage.is_empty():
			side_body.text="[b]ACTIVE VOYAGE[/b]\n%s → %s\n%s\nReward £%s\nRemaining: %d days\nRisk: %d%%\n\n%s"%[voyage["from"],voyage["to"],voyage["cargo"],_money(int(voyage["reward"])),int(voyage["remaining"]),int(float(voyage["risk"])*100.0),"Captain is handling routine events." if bool(state["captain"]) else "You must personally resolve voyage events."]
		else:
			side_body.text="[b]AVAILABLE FREIGHT[/b]\nChoose work freely. Better routes pay more but expose the ship and crew to longer voyages."
			for i in range(contract_templates.size()):
				var c:Dictionary=contract_templates[i]; _add_action("%s → %s • £%s • %dd"%[c["from"],c["to"],_money(int(c["reward"])),int(c["days"])],_accept_contract.bind(i),false)
	elif current_page=="CREW":
		side_body.text="[b]Personnel[/b]\nCaptain: %s\nChief Mate: %s\nShip Carpenter: %s\nDeck crew: %d/12\nMorale: %d%%\n\nA skilled captain reduces your micromanagement: routine incidents can be resolved automatically. Without one, important voyage events wait for your decision."%["Hired" if bool(state["captain"]) else "Vacant","Hired" if bool(state["mate"]) else "Vacant","Hired" if bool(state["carpenter"]) else "Vacant",int(state["crew"]),int(state["morale"])]
		_add_action("HIRE CAPTAIN • £450",_hire_role.bind("captain"),bool(state["captain"]))
		_add_action("HIRE CHIEF MATE • £280",_hire_role.bind("mate"),bool(state["mate"]))
		_add_action("HIRE SHIP CARPENTER • £240",_hire_role.bind("carpenter"),bool(state["carpenter"]))
		_add_action("HIRE 4 DECK CREW • £160",_hire_crew,int(state["crew"])>=12)
	elif current_page=="SUPPLY":
		side_body.text="[b]Voyage Stores[/b]\nFood: %d days\nFresh water: %d days\nSpare materials: %d\nMedical stores: %d\n\nLong voyages consume food and water each day. Under-provisioning lowers morale and can turn a manageable delay into a crisis."%[int(state["food"]),int(state["water"]),int(state["spares"]),int(state["medical"])]
		_add_action("BUY FOOD +15 • £150",_buy_supply.bind("food",15,150),false)
		_add_action("BUY WATER +15 • £90",_buy_supply.bind("water",15,90),false)
		_add_action("BUY SPARES +8 • £220",_buy_supply.bind("spares",8,220),false)
		_add_action("BUY MEDICAL +4 • £180",_buy_supply.bind("medical",4,180),false)
	elif current_page=="SHIPYARD":
		if bool(state["yard_owned"]):
			side_body.text="[b]TCH Shipyard — Liverpool[/b]\nStatus: Owned\nDry dock: Operational\nSlipway: Operational\nCurrent job: %s\nDays remaining: %d\n\nBuild vessels for your fleet or for sale. Future versions will add competitive tenders, custom ship classes and government contracts."%[str(state["yard_job"]) if str(state["yard_job"])!="" else "Idle",int(state["yard_job_days"])]
			_add_action("BUILD FOR OWN FLEET • £9,000",_start_build_ship.bind(false),int(state["yard_job_days"])>0)
			_add_action("BUILD FOR SALE • £9,000 → £12,500",_start_build_ship.bind(true),int(state["yard_job_days"])>0)
		else:
			side_body.text="[b]No shipyard owned[/b]\nUse commercial yards to repair and refit vessels. When capital reaches £65,000 you may acquire a local yard, making repair and construction part of your own business."
			_add_action("ACQUIRE SHIPYARD • £65,000",_buy_yard,false)
	elif current_page=="RESEARCH":
		var techs:Array=state["technologies"]
		side_body.text="[b]Research & Engineering[/b]\nResearch points: %d\nUnlocked: %s\n\nTechnology advances with the era. This alpha begins in the Age of Sail; later progression will move through steam, steel, diesel, containerization and modern automation."%[int(state["research"]),", ".join(techs) if not techs.is_empty() else "None"]
		_add_action("COPPER SHEATHING • 40 RP",_research.bind("Copper Sheathing",40),techs.has("Copper Sheathing"))
		_add_action("IMPROVED RIGGING • 60 RP",_research.bind("Improved Rigging",60),techs.has("Improved Rigging"))
		_add_action("MARINE CHRONOMETER • 100 RP",_research.bind("Marine Chronometer",100),techs.has("Marine Chronometer"))
	elif current_page=="FINANCE":
		var notices:Array=state["notifications"]
		var ntext=""
		for i in range(min(5,notices.size())): ntext += "• "+str(notices[notices.size()-1-i])+"\n"
		side_body.text="[b]Finance Office[/b]\nCash: £%s\nWeekly operating cost: £%s\nLast weekly result: £%s\nCompleted contracts: %d\nReputation: %d\n\n[b]Recent company log[/b]\n%s"%[_money(int(state["cash"])),_money(_weekly_expense()),_signed_money(int(state["weekly_profit"])),int(state["completed_contracts"]),int(state["reputation"]),ntext]
		_add_action("SAVE COMPANY",_save_game,false)

func _push_notification(t:String) -> void:
	var a:Array = state["notifications"]
	a.append(t)
	while a.size() > 30:
		a.pop_front()

func _show_toast(t:String) -> void:
	if toast==null or not is_instance_valid(toast): return
	toast.text=t
	var expected:=t
	get_tree().create_timer(3.0).timeout.connect(_clear_toast_if_matches.bind(expected))

func _click() -> void:
	if not sound_enabled: return
	fx_player.stream = _make_audio_stream("click", 0.09, false)
	fx_player.play()

func _money(v:int) -> String:
	var negative:=v<0; var s:=str(abs(v)); var out:=""
	while s.length()>3:
		out=","+s.right(3)+out; s=s.left(s.length()-3)
	return ("-" if negative else "")+s+out

func _signed_money(v:int) -> String:
	return ("+" if v>=0 else "-")+_money(abs(v))

func _label(text:String, size_v:int, color:Color) -> Label:
	var l:=Label.new(); l.text=text; l.add_theme_font_size_override("font_size",size_v); l.add_theme_color_override("font_color",color); return l

func _button(text:String, size_v:int) -> Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size=Vector2(0,42); b.add_theme_font_size_override("font_size",size_v); b.add_theme_color_override("font_color",Color("#dce5e7")); b.add_theme_color_override("font_hover_color",Color("#f4d17b")); b.add_theme_stylebox_override("normal",_panel_style(Color("#152b36"),Color("#4e6570"),1)); b.add_theme_stylebox_override("hover",_panel_style(Color("#1d3945"),Color("#b88b37"),1)); b.add_theme_stylebox_override("pressed",_panel_style(Color("#0b1b23"),Color("#e1b755"),2)); return b

func _panel_style(bg:Color,border:Color,width:int) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border; s.set_border_width_all(width); s.corner_radius_top_left=4; s.corner_radius_top_right=4; s.corner_radius_bottom_left=4; s.corner_radius_bottom_right=4; s.content_margin_left=10; s.content_margin_right=10; s.content_margin_top=7; s.content_margin_bottom=7; return s

class MainMenuArt extends Control:
	var t:=0.0
	func _ready(): mouse_filter=Control.MOUSE_FILTER_IGNORE; set_process(true)
	func _process(delta): t+=delta; queue_redraw()
	func _draw():
		var w=size.x; var h=size.y
		draw_rect(Rect2(0,0,w,h*.38),Color("#577f98")); draw_rect(Rect2(0,h*.38,w,h*.62),Color("#17455d"))
		for i in range(18):
			var x = i * w / 18.0
			var bh = 45 + ((i * 37) % 110)
			draw_rect(Rect2(x, h * .38 - bh, w / 20.0, bh), Color("#5f5143"))
			if i % 4 == 0:
				draw_rect(Rect2(x + w / 40.0, h * .38 - bh - 35, 10, 35), Color("#303638"))
		for i in range(7):
			var x=fposmod(t*(15+i*3)+i*180,w+220)-100; var y=h*(.50+(i%4)*.10); draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x+130,y),Vector2(x+108,y+22),Vector2(x+18,y+22)]),Color("#252c31") if i%2==0 else Color("#733a30")); draw_rect(Rect2(x+50,y-22,44,22),Color("#e5dcc5")); draw_rect(Rect2(x+64,y-38,9,16),Color("#7f3b2d"))
		for i in range(5):
			var px=420+i*165.0; draw_rect(Rect2(px,h*.44,130,26),Color("#5b4934")); draw_line(Vector2(px+30,h*.44),Vector2(px+30,h*.31),Color("#d1a03c"),6); draw_line(Vector2(px+30,h*.31),Vector2(px+88,h*.35),Color("#d1a03c"),5)
		draw_circle(Vector2(w*.88,h*.16),38,Color("#e3c471"))
