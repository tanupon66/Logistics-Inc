extends Node

var _voyage_serial:int = 1

func _ready() -> void:
	EventBus.day_advanced.connect(_on_day_advanced)

func charter_ship(offer_id:String) -> String:
	var offers:Dictionary = GameState.markets.get("charter_offers",{})
	if not offers.has(offer_id):
		return ""
	var offer:Dictionary = offers[offer_id]
	if not bool(offer.get("available",false)):
		return ""
	var deposit := float(offer.get("deposit",0.0))
	if not GameState.change_cash(-deposit,"Charter deposit: "+str(offer.get("name","Vessel"))):
		return ""
	var ship_id := "player_"+offer_id
	GameState.ships[ship_id] = {
		"id":ship_id,"name":offer.get("name","Chartered Vessel"),"class":offer.get("class","Sloop"),
		"owner_id":"company_player","ownership":"charter","charter_offer_id":offer_id,
		"capacity":int(offer.get("capacity",150)),"min_crew":int(offer.get("min_crew",5)),"speed":float(offer.get("speed",7.0)),
		"daily_rate":float(offer.get("daily_rate",8.0)),"condition":100,"crew_count":0,"captain_id":"",
		"provisions_days":0,"port_id":"port_liverpool","state":"in_port","assigned_contract_id":"","active_voyage_id":""
	}
	var ids:Array = GameState.player_company.get("chartered_ship_ids",[])
	ids.append(ship_id)
	GameState.player_company["chartered_ship_ids"] = ids
	GameState.companies["company_player"] = GameState.player_company.duplicate(true)
	offer["available"] = false
	offers[offer_id] = offer
	GameState.markets["charter_offers"] = offers
	EventBus.vessel_chartered.emit(ship_id)
	return ship_id

func buy_ship(offer_id:String) -> String:
	var offers:Dictionary = GameState.markets.get("ship_sale_offers",{})
	if not offers.has(offer_id):
		return ""
	var offer:Dictionary = offers[offer_id]
	if not bool(offer.get("available",false)):
		return ""
	var price := float(offer.get("price",0.0))
	if not GameState.change_cash(-price,"Purchased vessel: "+str(offer.get("name","Vessel"))):
		return ""
	var ship_id := "owned_"+offer_id
	GameState.ships[ship_id] = {
		"id":ship_id,"name":offer.get("name","Owned Vessel"),"class":offer.get("class","Sloop"),
		"owner_id":"company_player","ownership":"owned","capacity":int(offer.get("capacity",180)),
		"min_crew":int(offer.get("min_crew",5)),"speed":float(offer.get("speed",7.0)),"condition":int(offer.get("condition",85)),
		"crew_count":0,"captain_id":"","provisions_days":0,"port_id":"port_liverpool","state":"in_port",
		"assigned_contract_id":"","active_voyage_id":""
	}
	var ids:Array = GameState.player_company.get("owned_ship_ids",[])
	ids.append(ship_id)
	GameState.player_company["owned_ship_ids"] = ids
	GameState.companies["company_player"] = GameState.player_company.duplicate(true)
	offer["available"] = false
	offers[offer_id] = offer
	GameState.markets["ship_sale_offers"] = offers
	EventBus.vessel_purchased.emit(ship_id)
	return ship_id

func hire_captain(person_id:String, ship_id:String) -> bool:
	if not GameState.people.has(person_id) or not GameState.ships.has(ship_id):
		return false
	var person:Dictionary = GameState.people[person_id]
	var ship:Dictionary = GameState.ships[ship_id]
	if str(person.get("status","")) != "available" or str(ship.get("owner_id","")) != "company_player":
		return false
	if str(ship.get("captain_id","")) != "":
		return false
	var signing := float(person.get("signing_cost",0.0))
	if not GameState.change_cash(-signing,"Captain signing fee"):
		return false
	person["status"] = "employed"
	person["employer_id"] = "company_player"
	person["ship_id"] = ship_id
	ship["captain_id"] = person_id
	GameState.people[person_id] = person
	GameState.ships[ship_id] = ship
	EventBus.captain_hired.emit(person_id,ship_id)
	return true

func hire_crew(ship_id:String, amount:int) -> bool:
	if not GameState.ships.has(ship_id) or amount <= 0:
		return false
	var ship:Dictionary = GameState.ships[ship_id]
	if str(ship.get("owner_id","")) != "company_player":
		return false
	var cost := float(amount) * 6.0
	if not GameState.change_cash(-cost,"Crew hiring and advance wages"):
		return false
	ship["crew_count"] = int(ship.get("crew_count",0)) + amount
	GameState.ships[ship_id] = ship
	EventBus.crew_hired.emit(ship_id,amount)
	return true

func load_provisions(ship_id:String, days:int) -> bool:
	if not GameState.ships.has(ship_id) or days <= 0:
		return false
	var ship:Dictionary = GameState.ships[ship_id]
	var crew := maxi(int(ship.get("crew_count",0)),1)
	var cost := float(days * crew) * 0.55
	if not GameState.change_cash(-cost,"Food, water and stores"):
		return false
	ship["provisions_days"] = int(ship.get("provisions_days",0)) + days
	GameState.ships[ship_id] = ship
	EventBus.provisions_loaded.emit(ship_id,days)
	return true

func accept_contract(contract_id:String, ship_id:String) -> bool:
	if not GameState.contracts.has(contract_id) or not GameState.ships.has(ship_id):
		return false
	var contract:Dictionary = GameState.contracts[contract_id]
	var ship:Dictionary = GameState.ships[ship_id]
	if str(contract.get("status","")) != "offered":
		return false
	if int(contract.get("amount",0)) > int(ship.get("capacity",0)):
		return false
	if str(ship.get("state","")) != "in_port" or str(ship.get("assigned_contract_id","")) != "":
		return false
	if str(ship.get("port_id","")) != str(contract.get("origin_port_id","")):
		return false
	contract["status"] = "assigned"
	contract["assigned_ship_id"] = ship_id
	ship["assigned_contract_id"] = contract_id
	GameState.contracts[contract_id] = contract
	GameState.ships[ship_id] = ship
	EventBus.contract_accepted.emit(contract_id)
	return true

func depart_ship(ship_id:String) -> String:
	if not GameState.ships.has(ship_id):
		return ""
	var ship:Dictionary = GameState.ships[ship_id]
	var contract_id := str(ship.get("assigned_contract_id",""))
	if contract_id == "" or not GameState.contracts.has(contract_id):
		return ""
	if str(ship.get("state","")) != "in_port":
		return ""
	if int(ship.get("crew_count",0)) < int(ship.get("min_crew",1)):
		return ""
	var contract:Dictionary = GameState.contracts[contract_id]
	var required_stores := maxi(5,int(ceil(float(contract.get("days",8)) * 0.65)))
	if int(ship.get("provisions_days",0)) < required_stores:
		return ""
	var voyage_id := "voyage_%04d" % _voyage_serial
	_voyage_serial += 1
	var voyage := {
		"id":voyage_id,"ship_id":ship_id,"contract_id":contract_id,
		"origin_port_id":contract.get("origin_port_id","port_liverpool"),"destination_port_id":contract.get("destination_port_id",""),
		"days_total":int(contract.get("days",8)),"days_elapsed":0,"progress":0.0,"delay_days":0,
		"pending_event":"","weather_event_done":false,"supply_event_done":false,"status":"en_route"
	}
	GameState.voyages[voyage_id] = voyage
	ship["state"] = "en_route"
	ship["active_voyage_id"] = voyage_id
	ship["port_id"] = ""
	GameState.ships[ship_id] = ship
	contract["status"] = "active"
	GameState.contracts[contract_id] = contract
	EventBus.vessel_departed.emit(ship_id,str(voyage["origin_port_id"]),str(voyage["destination_port_id"]))
	EventBus.voyage_started.emit(voyage_id)
	return voyage_id

func resolve_event(voyage_id:String, choice:String) -> bool:
	if not GameState.voyages.has(voyage_id):
		return false
	var voyage:Dictionary = GameState.voyages[voyage_id]
	var event_id := str(voyage.get("pending_event",""))
	if event_id == "":
		return false
	var ship_id := str(voyage.get("ship_id",""))
	var ship:Dictionary = GameState.ships.get(ship_id,{})
	match event_id:
		"heavy_weather":
			if choice == "heave_to":
				voyage["delay_days"] = int(voyage.get("delay_days",0)) + 2
			elif choice == "press_on":
				ship["condition"] = maxi(45,int(ship.get("condition",100))-12)
		"low_stores":
			if choice == "ration":
				ship["provisions_days"] = int(ship.get("provisions_days",0)) + 2
			elif choice == "buy_emergency":
				if GameState.change_cash(-80.0,"Emergency provisions at sea"):
					ship["provisions_days"] = int(ship.get("provisions_days",0)) + 7
	voyage["pending_event"] = ""
	GameState.voyages[voyage_id] = voyage
	GameState.ships[ship_id] = ship
	EventBus.voyage_event_resolved.emit(voyage_id,event_id,choice)
	return true

func repair_ship(ship_id:String) -> bool:
	if not GameState.ships.has(ship_id):
		return false
	var ship:Dictionary = GameState.ships[ship_id]
	if str(ship.get("state","")) != "in_port" or str(ship.get("port_id","")) != "port_liverpool":
		return false
	var missing := 100 - int(ship.get("condition",100))
	if missing <= 0:
		return true
	var cost := float(missing) * 3.0
	if not GameState.change_cash(-cost,"Old Dry Dock repair"):
		return false
	ship["condition"] = 100
	GameState.ships[ship_id] = ship
	EventBus.vessel_repaired.emit(ship_id)
	return true

func lease_facility(facility_id:String) -> bool:
	if not GameState.facilities.has(facility_id):
		return false
	var facility:Dictionary = GameState.facilities[facility_id]
	var leased:Array = GameState.player_company.get("leased_facility_ids",[])
	if facility_id in leased:
		return true
	var cost := float(facility.get("lease_cost",0.0))
	if cost <= 0.0 or not GameState.change_cash(-cost,"Facility lease: "+str(facility.get("name","Facility"))):
		return false
	leased.append(facility_id)
	GameState.player_company["leased_facility_ids"] = leased
	GameState.companies["company_player"] = GameState.player_company.duplicate(true)
	facility["lessee_id"] = "company_player"
	facility["status"] = "Leased by TCH Maritime Co."
	GameState.facilities[facility_id] = facility
	EventBus.facility_lease_started.emit(facility_id)
	return true

func _on_day_advanced(_day:int,_month:int,_year:int) -> void:
	_apply_daily_costs()
	var voyage_ids := GameState.voyages.keys()
	for voyage_id in voyage_ids:
		_progress_voyage(str(voyage_id))

func _apply_daily_costs() -> void:
	for ship_id in GameState.player_ship_ids():
		if not GameState.ships.has(ship_id):
			continue
		var ship:Dictionary = GameState.ships[ship_id]
		var daily := 0.0
		if str(ship.get("ownership","")) == "charter":
			daily += float(ship.get("daily_rate",0.0))
		daily += float(int(ship.get("crew_count",0))) * 0.55
		var captain_id := str(ship.get("captain_id",""))
		if captain_id != "" and GameState.people.has(captain_id):
			daily += float(GameState.people[captain_id].get("daily_wage",0.0))
		if daily > 0.0:
			GameState.change_cash(-daily,"Daily vessel payroll/charter")
	var leased:Array = GameState.player_company.get("leased_facility_ids",[])
	for facility_id in leased:
		var f:Dictionary = GameState.facilities.get(str(facility_id),{})
		var weekly := float(f.get("weekly_cost",0.0))
		if weekly > 0.0:
			GameState.change_cash(-(weekly/7.0),"Facility lease running cost")

func _progress_voyage(voyage_id:String) -> void:
	if not GameState.voyages.has(voyage_id):
		return
	var voyage:Dictionary = GameState.voyages[voyage_id]
	if str(voyage.get("status","")) != "en_route" or str(voyage.get("pending_event","")) != "":
		return
	var ship_id := str(voyage.get("ship_id",""))
	if not GameState.ships.has(ship_id):
		return
	var ship:Dictionary = GameState.ships[ship_id]
	ship["provisions_days"] = maxi(0,int(ship.get("provisions_days",0))-1)
	voyage["days_elapsed"] = int(voyage.get("days_elapsed",0)) + 1
	var total := int(voyage.get("days_total",1)) + int(voyage.get("delay_days",0))
	voyage["progress"] = clampf(float(voyage["days_elapsed"])/float(maxi(total,1)),0.0,1.0)
	GameState.ships[ship_id] = ship
	GameState.voyages[voyage_id] = voyage
	_maybe_trigger_event(voyage_id)
	if not GameState.voyages.has(voyage_id):
		return
	voyage = GameState.voyages[voyage_id]
	EventBus.voyage_progress.emit(voyage_id,float(voyage.get("progress",0.0)))
	if float(voyage.get("progress",0.0)) >= 1.0:
		_complete_voyage(voyage_id)

func _maybe_trigger_event(voyage_id:String) -> void:
	var voyage:Dictionary = GameState.voyages[voyage_id]
	var ship_id := str(voyage.get("ship_id",""))
	var ship:Dictionary = GameState.ships[ship_id]
	var progress := float(voyage.get("progress",0.0))
	if progress >= 0.32 and not bool(voyage.get("weather_event_done",false)):
		voyage["weather_event_done"] = true
		var captain_id := str(ship.get("captain_id",""))
		if captain_id != "" and GameState.people.has(captain_id) and int(GameState.people[captain_id].get("weather",0)) >= 60:
			voyage["delay_days"] = int(voyage.get("delay_days",0)) + 1
		else:
			voyage["pending_event"] = "heavy_weather"
			EventBus.voyage_event_requested.emit(voyage_id,"heavy_weather")
		GameState.voyages[voyage_id] = voyage
		return
	if progress >= 0.68 and int(ship.get("provisions_days",0)) <= 2 and not bool(voyage.get("supply_event_done",false)):
		voyage["supply_event_done"] = true
		voyage["pending_event"] = "low_stores"
		GameState.voyages[voyage_id] = voyage
		EventBus.voyage_event_requested.emit(voyage_id,"low_stores")

func _complete_voyage(voyage_id:String) -> void:
	var voyage:Dictionary = GameState.voyages[voyage_id]
	var ship_id := str(voyage.get("ship_id",""))
	var contract_id := str(voyage.get("contract_id",""))
	var destination := str(voyage.get("destination_port_id",""))
	var ship:Dictionary = GameState.ships[ship_id]
	ship["state"] = "in_port"
	ship["port_id"] = destination
	ship["active_voyage_id"] = ""
	ship["assigned_contract_id"] = ""
	GameState.ships[ship_id] = ship
	if GameState.contracts.has(contract_id):
		var contract:Dictionary = GameState.contracts[contract_id]
		contract["status"] = "completed"
		GameState.contracts[contract_id] = contract
		GameState.change_cash(float(contract.get("reward",0.0)),"Freight contract completed")
		EventBus.contract_completed.emit(contract_id)
	voyage["status"] = "completed"
	voyage["progress"] = 1.0
	GameState.voyages[voyage_id] = voyage
	EventBus.vessel_arrived.emit(ship_id,destination)
