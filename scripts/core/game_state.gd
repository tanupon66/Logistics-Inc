extends Node

const SAVE_VERSION := 2

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
var markets:Dictionary = {}
var random_seed:int = 1750

func new_game() -> void:
	world = {
		"day":1,"month":1,"year":1750,"hour":8,
		"weather":"clear","home_port_id":"port_liverpool"
	}
	player_company = {
		"id":"company_player","name":"TCH Maritime Co.","cash":12000.0,
		"reputation":10.0,"home_port_id":"port_liverpool",
		"owned_ship_ids":[],"chartered_ship_ids":[],"leased_facility_ids":[]
	}
	companies = {"company_player":player_company.duplicate(true)}
	ports = {
		"port_liverpool":{"id":"port_liverpool","name":"Liverpool","country":"Great Britain","berths":2,"warehouse_capacity":800,"congestion":0.12,"map_pos":Vector2(430,120),"service_prices":{"berth_day":12.0,"repair_hour":4.0,"water":1.0,"food":1.5},"facility_ids":["facility_royal_shipyard","facility_eastern_warehouse","facility_warehouse_3","facility_old_dry_dock","facility_liverpool_quay"]},
		"port_lisbon":{"id":"port_lisbon","name":"Lisbon","country":"Portugal","berths":2,"warehouse_capacity":500,"congestion":0.08,"map_pos":Vector2(420,185)},
		"port_amsterdam":{"id":"port_amsterdam","name":"Amsterdam","country":"Netherlands","berths":2,"warehouse_capacity":650,"congestion":0.10,"map_pos":Vector2(448,112)},
		"port_bordeaux":{"id":"port_bordeaux","name":"Bordeaux","country":"France","berths":1,"warehouse_capacity":420,"congestion":0.06,"map_pos":Vector2(415,158)}
	}
	facilities = {
		"facility_royal_shipyard":{"id":"facility_royal_shipyard","name":"Royal Shipyard","type":"shipyard","port_id":"port_liverpool","owner_id":"npc_royal_yard","level":1,"workers":42,"capacity":2,"status":"Building merchant hull"},
		"facility_eastern_warehouse":{"id":"facility_eastern_warehouse","name":"Eastern Trading Co.","type":"warehouse","port_id":"port_liverpool","owner_id":"npc_eastern_trading","level":1,"capacity":800,"status":"Cargo handling"},
		"facility_warehouse_3":{"id":"facility_warehouse_3","name":"Warehouse No.3","type":"warehouse","port_id":"port_liverpool","owner_id":"npc_port_authority","level":1,"capacity":520,"status":"Available for lease","lease_cost":140.0,"weekly_cost":22.0},
		"facility_old_dry_dock":{"id":"facility_old_dry_dock","name":"Old Dry Dock","type":"dry_dock","port_id":"port_liverpool","owner_id":"npc_port_authority","level":1,"capacity":1,"status":"External repair yard"},
		"facility_liverpool_quay":{"id":"facility_liverpool_quay","name":"Liverpool Quay","type":"berth","port_id":"port_liverpool","owner_id":"npc_port_authority","level":1,"berths":2,"status":"Busy","lease_cost":90.0,"weekly_cost":14.0}
	}
	ships = {
		"ambient_sloop_01":{"id":"ambient_sloop_01","owner_id":"npc_merchant","class":"sloop","port_id":"port_liverpool","state":"harbor_transit","route_progress":0.05},
		"ambient_sloop_02":{"id":"ambient_sloop_02","owner_id":"npc_merchant","class":"brig","port_id":"port_liverpool","state":"harbor_transit","route_progress":0.42},
		"ambient_sloop_03":{"id":"ambient_sloop_03","owner_id":"npc_merchant","class":"cutter","port_id":"port_liverpool","state":"harbor_transit","route_progress":0.73}
	}
	people = {
		"captain_hawke":{"id":"captain_hawke","name":"Edward Hawke","role":"captain","navigation":62,"leadership":55,"weather":58,"daily_wage":4.0,"signing_cost":40.0,"status":"available","trait":"Steady Hand","trait_desc":"Keeps crew and cargo steady on long passages."},
		"captain_reed":{"id":"captain_reed","name":"Thomas Reed","role":"captain","navigation":74,"leadership":67,"weather":72,"daily_wage":6.0,"signing_cost":75.0,"status":"available","trait":"Storm Reader","trait_desc":"Excellent at reading weather and protecting the ship."},
		"captain_finch":{"id":"captain_finch","name":"Samuel Finch","role":"captain","navigation":51,"leadership":70,"weather":45,"daily_wage":3.0,"signing_cost":30.0,"status":"available","trait":"Crew Favorite","trait_desc":"Strong morale and loyalty among ordinary sailors."}
	}
	contracts = {
		"contract_lisbon_cotton":{"id":"contract_lisbon_cotton","name":"Cotton to Lisbon","cargo":"Cotton Bales","amount":130,"origin_port_id":"port_liverpool","destination_port_id":"port_lisbon","days":12,"reward":950.0,"status":"offered"},
		"contract_amsterdam_tools":{"id":"contract_amsterdam_tools","name":"Tools to Amsterdam","cargo":"Iron Tools","amount":175,"origin_port_id":"port_liverpool","destination_port_id":"port_amsterdam","days":9,"reward":1120.0,"status":"offered"},
		"contract_bordeaux_wool":{"id":"contract_bordeaux_wool","name":"Wool to Bordeaux","cargo":"Wool","amount":100,"origin_port_id":"port_liverpool","destination_port_id":"port_bordeaux","days":8,"reward":760.0,"status":"offered"},
		"contract_lisbon_wine_return":{"id":"contract_lisbon_wine_return","name":"Wine to Liverpool","cargo":"Portuguese Wine","amount":95,"origin_port_id":"port_lisbon","destination_port_id":"port_liverpool","days":11,"reward":870.0,"status":"offered"},
		"contract_amsterdam_spices_return":{"id":"contract_amsterdam_spices_return","name":"Spices to Liverpool","cargo":"Spice Chests","amount":145,"origin_port_id":"port_amsterdam","destination_port_id":"port_liverpool","days":9,"reward":1040.0,"status":"offered"},
		"contract_bordeaux_wine_return":{"id":"contract_bordeaux_wine_return","name":"Claret to Liverpool","cargo":"Claret Barrels","amount":105,"origin_port_id":"port_bordeaux","destination_port_id":"port_liverpool","days":8,"reward":820.0,"status":"offered"}
	}
	markets = {
		"charter_offers":{
			"charter_mersey_sloop":{"id":"charter_mersey_sloop","name":"Mersey Belle","class":"Sloop","capacity":180,"min_crew":5,"speed":7.5,"deposit":600.0,"daily_rate":9.0,"available":true},
			"charter_north_star_brig":{"id":"charter_north_star_brig","name":"North Star","class":"Brig","capacity":320,"min_crew":8,"speed":8.0,"deposit":1100.0,"daily_rate":14.0,"available":true}
		},
		"ship_sale_offers":{
			"sale_used_sloop":{"id":"sale_used_sloop","name":"Providence","class":"Sloop","capacity":190,"min_crew":5,"speed":7.2,"price":7200.0,"condition":86,"available":true}
		}
	}
	voyages.clear()
	research={"points":0,"completed":[]}
	events.clear()

func get_cash() -> float:
	return float(player_company.get("cash",0.0))

func change_cash(delta:float,reason:String="") -> bool:
	var current:=get_cash()
	if delta<0.0 and current+delta<0.0:
		return false
	player_company["cash"]=current+delta
	companies["company_player"]=player_company.duplicate(true)
	EventBus.cash_changed.emit(get_cash(),delta,reason)
	return true

func get_facility(facility_id:String) -> Dictionary:
	return facilities.get(facility_id,{}).duplicate(true)

func player_ship_ids() -> Array:
	var ids:Array=[]
	ids.append_array(player_company.get("owned_ship_ids",[]))
	ids.append_array(player_company.get("chartered_ship_ids",[]))
	return ids

func serialize() -> Dictionary:
	return {"save_version":SAVE_VERSION,"world":world,"player_company":player_company,"companies":companies,"ports":ports,"ships":ships,"voyages":voyages,"people":people,"contracts":contracts,"research":research,"events":events,"facilities":facilities,"markets":markets,"random_seed":random_seed}

func deserialize(data:Dictionary) -> bool:
	if int(data.get("save_version",-1))!=SAVE_VERSION:
		return false
	world=data.get("world",{}).duplicate(true)
	player_company=data.get("player_company",{}).duplicate(true)
	companies=data.get("companies",{}).duplicate(true)
	ports=data.get("ports",{}).duplicate(true)
	ships=data.get("ships",{}).duplicate(true)
	voyages=data.get("voyages",{}).duplicate(true)
	people=data.get("people",{}).duplicate(true)
	contracts=data.get("contracts",{}).duplicate(true)
	research=data.get("research",{}).duplicate(true)
	events=data.get("events",{}).duplicate(true)
	facilities=data.get("facilities",{}).duplicate(true)
	markets=data.get("markets",{}).duplicate(true)
	random_seed=int(data.get("random_seed",1750))
	return true
