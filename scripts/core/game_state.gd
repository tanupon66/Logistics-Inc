extends Node

const SAVE_VERSION := 1

var world:Dictionary = {}
var player_company:Dictionary = {}
var companies:Dictionary = {}
var ports:Dictionary = {}
var ships:Dictionary = {}
var voyages:Dictionary = {}
var people:Dictionary = {}
var contracts:Dictionary = {}
var research:Dictionary = {}
var events:Dictionary = {}
var facilities:Dictionary = {}
var random_seed:int = 1750

func new_game() -> void:
	world = {
		"day": 1,
		"month": 1,
		"year": 1750,
		"hour": 8,
		"weather": "clear",
		"home_port_id": "port_liverpool"
	}
	player_company = {
		"id": "company_player",
		"name": "TCH Maritime Co.",
		"cash": 12000.0,
		"reputation": 10.0,
		"home_port_id": "port_liverpool",
		"owned_ship_ids": [],
		"leased_facility_ids": []
	}
	companies = {"company_player": player_company.duplicate(true)}
	ports = {
		"port_liverpool": {
			"id": "port_liverpool",
			"name": "Liverpool",
			"country": "Great Britain",
			"berths": 2,
			"warehouse_capacity": 800,
			"congestion": 0.12,
			"service_prices": {"berth_day": 12.0, "repair_hour": 4.0, "water": 1.0, "food": 1.5},
			"facility_ids": ["facility_royal_shipyard","facility_eastern_warehouse","facility_warehouse_3","facility_old_dry_dock","facility_liverpool_quay"]
		}
	}
	facilities = {
		"facility_royal_shipyard": {
			"id":"facility_royal_shipyard", "name":"Royal Shipyard", "type":"shipyard", "port_id":"port_liverpool",
			"owner_id":"npc_royal_yard", "level":1, "workers":42, "capacity":2, "status":"Building merchant hull"
		},
		"facility_eastern_warehouse": {
			"id":"facility_eastern_warehouse", "name":"Eastern Trading Co.", "type":"warehouse", "port_id":"port_liverpool",
			"owner_id":"npc_eastern_trading", "level":1, "capacity":800, "status":"Cargo handling"
		},
		"facility_warehouse_3": {
			"id":"facility_warehouse_3", "name":"Warehouse No.3", "type":"warehouse", "port_id":"port_liverpool",
			"owner_id":"npc_port_authority", "level":1, "capacity":520, "status":"Available for lease"
		},
		"facility_old_dry_dock": {
			"id":"facility_old_dry_dock", "name":"Old Dry Dock", "type":"dry_dock", "port_id":"port_liverpool",
			"owner_id":"npc_port_authority", "level":1, "capacity":1, "status":"External repair yard"
		},
		"facility_liverpool_quay": {
			"id":"facility_liverpool_quay", "name":"Liverpool Quay", "type":"berth", "port_id":"port_liverpool",
			"owner_id":"npc_port_authority", "level":1, "berths":2, "status":"Busy"
		}
	}
	ships = {
		"ambient_sloop_01": {"id":"ambient_sloop_01","owner_id":"npc_merchant","class":"sloop","port_id":"port_liverpool","state":"harbor_transit","route_progress":0.05},
		"ambient_sloop_02": {"id":"ambient_sloop_02","owner_id":"npc_merchant","class":"brig","port_id":"port_liverpool","state":"harbor_transit","route_progress":0.42},
		"ambient_sloop_03": {"id":"ambient_sloop_03","owner_id":"npc_merchant","class":"cutter","port_id":"port_liverpool","state":"harbor_transit","route_progress":0.73}
	}
	voyages.clear()
	people.clear()
	contracts.clear()
	research = {"points": 0, "completed": []}
	events.clear()

func get_cash() -> float:
	return float(player_company.get("cash", 0.0))

func change_cash(delta:float, reason:String = "") -> bool:
	var current := get_cash()
	if delta < 0.0 and current + delta < 0.0:
		return false
	player_company["cash"] = current + delta
	companies["company_player"] = player_company.duplicate(true)
	EventBus.cash_changed.emit(get_cash(), delta, reason)
	return true

func get_facility(facility_id:String) -> Dictionary:
	return facilities.get(facility_id, {}).duplicate(true)

func serialize() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"world": world,
		"player_company": player_company,
		"companies": companies,
		"ports": ports,
		"ships": ships,
		"voyages": voyages,
		"people": people,
		"contracts": contracts,
		"research": research,
		"events": events,
		"facilities": facilities,
		"random_seed": random_seed
	}

func deserialize(data:Dictionary) -> bool:
	if int(data.get("save_version", -1)) != SAVE_VERSION:
		return false
	world = data.get("world", {}).duplicate(true)
	player_company = data.get("player_company", {}).duplicate(true)
	companies = data.get("companies", {}).duplicate(true)
	ports = data.get("ports", {}).duplicate(true)
	ships = data.get("ships", {}).duplicate(true)
	voyages = data.get("voyages", {}).duplicate(true)
	people = data.get("people", {}).duplicate(true)
	contracts = data.get("contracts", {}).duplicate(true)
	research = data.get("research", {}).duplicate(true)
	events = data.get("events", {}).duplicate(true)
	facilities = data.get("facilities", {}).duplicate(true)
	random_seed = int(data.get("random_seed", 1750))
	return true