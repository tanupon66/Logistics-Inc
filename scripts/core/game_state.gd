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
		"weather": "clear"
	}
	player_company = {
		"id": "company_player",
		"name": "TCH Maritime Co.",
		"cash": 12000.0,
		"reputation": 10.0,
		"home_port_id": "port_liverpool"
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
			"service_prices": {"berth_day": 12.0, "repair_hour": 4.0, "water": 1.0, "food": 1.5}
		}
	}
	ships.clear()
	voyages.clear()
	people.clear()
	contracts.clear()
	research = {"points": 0, "completed": []}
	events.clear()
	facilities.clear()

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
