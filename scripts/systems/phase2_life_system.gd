extends Node

const CAPTAIN_TRAITS := {
	"captain_hawke": {"name":"Steady Hand", "morale_daily":0.45, "cargo_protection":0.05},
	"captain_reed": {"name":"Storm Reader", "morale_daily":0.25, "cargo_protection":0.12},
	"captain_finch": {"name":"Crew Favorite", "morale_daily":0.80, "cargo_protection":0.03}
}

func _ready() -> void:
	EventBus.vessel_chartered.connect(_on_vessel_added)
	EventBus.vessel_purchased.connect(_on_vessel_added)
	EventBus.captain_hired.connect(_on_captain_hired)
	EventBus.contract_accepted.connect(_on_contract_accepted)
	EventBus.contract_completed.connect(_on_contract_completed)
	EventBus.day_advanced.connect(_on_day_advanced)
	_ensure_all_player_ships()

func _ensure_all_player_ships() -> void:
	for ship_id in GameState.player_ship_ids():
		_ensure_ship_fields(str(ship_id))

func _ensure_ship_fields(ship_id:String) -> void:
	if not GameState.ships.has(ship_id):
		return
	var ship:Dictionary = GameState.ships[ship_id]
	if str(ship.get("owner_id","")) != "company_player":
		return
	if not ship.has("morale"): ship["morale"] = 72.0
	if not ship.has("crew_health"): ship["crew_health"] = 100.0
	if not ship.has("cargo_condition"): ship["cargo_condition"] = 100.0
	if not ship.has("cargo_loaded"): ship["cargo_loaded"] = 0.0
	if not ship.has("cargo_target"): ship["cargo_target"] = 0.0
	if not ship.has("loading_progress"): ship["loading_progress"] = 0.0
	if not ship.has("captain_trait"): ship["captain_trait"] = ""
	GameState.ships[ship_id] = ship

func _on_vessel_added(ship_id:String) -> void:
	_ensure_ship_fields(ship_id)

func _on_captain_hired(person_id:String, ship_id:String) -> void:
	_ensure_ship_fields(ship_id)
	if not GameState.ships.has(ship_id):
		return
	var ship:Dictionary = GameState.ships[ship_id]
	var captain_trait_data:Dictionary = CAPTAIN_TRAITS.get(person_id,{})
	ship["captain_trait"] = str(captain_trait_data.get("name","Experienced Mariner"))
	GameState.ships[ship_id] = ship

func _on_contract_accepted(contract_id:String) -> void:
	if not GameState.contracts.has(contract_id):
		return
	var contract:Dictionary = GameState.contracts[contract_id]
	var ship_id := str(contract.get("assigned_ship_id",""))
	if ship_id == "" or not GameState.ships.has(ship_id):
		return
	_ensure_ship_fields(ship_id)
	var ship:Dictionary = GameState.ships[ship_id]
	ship["state"] = "loading"
	ship["cargo_loaded"] = 0.0
	ship["cargo_target"] = float(contract.get("amount",0))
	ship["loading_progress"] = 0.0
	ship["cargo_condition"] = 100.0
	GameState.ships[ship_id] = ship
	EventBus.cargo_loading_started.emit(ship_id,contract_id)
	EventBus.cargo_loading_progress.emit(ship_id,0.0)

func _on_day_advanced(_day:int, _month:int, _year:int) -> void:
	for ship_id_value in GameState.player_ship_ids():
		var ship_id := str(ship_id_value)
		_ensure_ship_fields(ship_id)
		if not GameState.ships.has(ship_id):
			continue
		var ship:Dictionary = GameState.ships[ship_id]
		match str(ship.get("state","")):
			"loading":
				_progress_loading(ship_id)
			"en_route":
				_update_shipboard_life(ship_id)

func _loading_throughput(ship:Dictionary) -> float:
	var throughput := 48.0
	var leased:Array = GameState.player_company.get("leased_facility_ids",[])
	if "facility_liverpool_quay" in leased:
		throughput += 24.0
	if "facility_warehouse_3" in leased:
		throughput += 18.0
	var captain_id := str(ship.get("captain_id",""))
	if captain_id != "" and GameState.people.has(captain_id):
		throughput += float(GameState.people[captain_id].get("leadership",50)) / 12.0
	return throughput

func _progress_loading(ship_id:String) -> void:
	if not GameState.ships.has(ship_id):
		return
	var ship:Dictionary = GameState.ships[ship_id]
	var target := maxf(1.0,float(ship.get("cargo_target",0.0)))
	var loaded := float(ship.get("cargo_loaded",0.0))
	loaded = minf(target,loaded + _loading_throughput(ship))
	ship["cargo_loaded"] = loaded
	ship["loading_progress"] = clampf(loaded / target,0.0,1.0)
	if loaded >= target:
		ship["state"] = "in_port"
	GameState.ships[ship_id] = ship
	EventBus.cargo_loading_progress.emit(ship_id,float(ship["loading_progress"]))
	if loaded >= target:
		EventBus.cargo_loading_completed.emit(ship_id)

func _update_shipboard_life(ship_id:String) -> void:
	if not GameState.ships.has(ship_id):
		return
	var ship:Dictionary = GameState.ships[ship_id]
	var morale := float(ship.get("morale",72.0))
	var health := float(ship.get("crew_health",100.0))
	var cargo_condition := float(ship.get("cargo_condition",100.0))
	var stores := int(ship.get("provisions_days",0))
	var hull := float(ship.get("condition",100))
	var captain_id := str(ship.get("captain_id",""))
	var leadership := 0.0
	var captain_trait_data:Dictionary = {}
	if captain_id != "" and GameState.people.has(captain_id):
		leadership = float(GameState.people[captain_id].get("leadership",0))
		captain_trait_data = CAPTAIN_TRAITS.get(captain_id,{})

	morale -= 0.20
	morale += leadership / 260.0
	morale += float(captain_trait_data.get("morale_daily",0.0))
	if stores <= 4:
		morale -= 2.4
		health -= 1.6
	elif stores <= 8:
		morale -= 0.7
		health -= 0.35
	else:
		health += 0.15
	if hull < 70.0:
		morale -= 0.8
		cargo_condition -= (70.0 - hull) * 0.035
	if morale < 45.0:
		cargo_condition -= 0.45
	if health < 75.0:
		cargo_condition -= 0.30
	var protection := float(captain_trait_data.get("cargo_protection",0.0))
	cargo_condition += protection

	morale = clampf(morale,0.0,100.0)
	health = clampf(health,0.0,100.0)
	cargo_condition = clampf(cargo_condition,55.0,100.0)
	ship["morale"] = morale
	ship["crew_health"] = health
	ship["cargo_condition"] = cargo_condition
	GameState.ships[ship_id] = ship
	EventBus.ship_welfare_changed.emit(ship_id,morale,health)
	EventBus.cargo_condition_changed.emit(ship_id,cargo_condition)

func _on_contract_completed(contract_id:String) -> void:
	if not GameState.contracts.has(contract_id):
		return
	var contract:Dictionary = GameState.contracts[contract_id]
	var ship_id := str(contract.get("assigned_ship_id",""))
	if ship_id == "" or not GameState.ships.has(ship_id):
		return
	_ensure_ship_fields(ship_id)
	var ship:Dictionary = GameState.ships[ship_id]
	var condition := float(ship.get("cargo_condition",100.0))
	if condition < 98.0:
		var damage_ratio := (100.0 - condition) / 100.0
		var claim := float(contract.get("reward",0.0)) * damage_ratio * 0.45
		if claim > 0.5:
			GameState.change_cash(-claim,"Cargo damage claim")
			EventBus.cargo_claim_paid.emit(ship_id,claim,condition)
	ship["cargo_loaded"] = 0.0
	ship["cargo_target"] = 0.0
	ship["loading_progress"] = 0.0
	ship["cargo_condition"] = 100.0
	GameState.ships[ship_id] = ship
