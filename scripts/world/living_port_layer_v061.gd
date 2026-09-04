extends Node2D

var ambient_t:float=0.0
var sim_t:float=0.0
var berth_positions:Array=[Vector2(-350,165),Vector2(-210,205),Vector2(-55,238)]

func _ready() -> void:
	set_process(true)
	queue_redraw()

func _process(delta:float) -> void:
	ambient_t+=delta
	sim_t+=delta*float(maxi(TimeSystem.speed,0))
	_update_ambient_ship_state(delta)
	queue_redraw()

func _update_ambient_ship_state(delta:float) -> void:
	if TimeSystem.speed<=0:
		return
	for ship_id in GameState.ships.keys():
		var ship:Dictionary=GameState.ships[ship_id]
		if str(ship.get("state",""))!="harbor_transit":
			continue
		var progress:=float(ship.get("route_progress",0.0))
		progress=fmod(progress+delta*.018*float(TimeSystem.speed),1.0)
		ship["route_progress"]=progress
		GameState.ships[ship_id]=ship

func _draw() -> void:
	_draw_water_motion()
	_draw_smoke()
	_draw_flags()
	_draw_birds()
	_draw_ambient_harbor_traffic()
	_draw_player_vessels()
	_draw_carts()
	_draw_dock_workers()
	_draw_crane_activity()

func _draw_water_motion() -> void:
	for row in range(9):
		var y:=55.0+float(row)*38.0
		for i in range(12):
			var phase:=ambient_t*(14.0+row)+float(i*37+row*11)
			var x:=-610.0+float(i)*112.0+fmod(phase,70.0)
			var length:=18.0+float((i+row)%4)*5.0
			draw_line(Vector2(x,y),Vector2(x+length,y+sin(phase*.08)*2.0),Color(.65,.9,.95,.22),1.0)

func _draw_smoke() -> void:
	var stacks:Array=[Vector2(-455,-220),Vector2(230,-215),Vector2(438,-190),Vector2(505,-165)]
	for stack_value in stacks:
		var stack:Vector2=stack_value
		for i in range(5):
			var age:=fmod(ambient_t*.52+float(i)*.19,1.0)
			var drift:=Vector2(age*26.0,-age*58.0)
			var wobble:=Vector2(sin(ambient_t*1.7+i)*5.0*age,0)
			var radius:=4.0+age*9.0
			draw_circle(stack+drift+wobble,radius,Color(.72,.72,.69,.25*(1.0-age)))

func _draw_flags() -> void:
	for base_value in [Vector2(-420,-145),Vector2(120,-142),Vector2(465,-118)]:
		var base:Vector2=base_value
		draw_line(base,base+Vector2(0,-34),Color("#423126"),2.0)
		var tip:=base+Vector2(0,-33)
		var wave:=sin(ambient_t*4.0+base.x*.01)*3.0
		var cloth:=PackedVector2Array([tip,tip+Vector2(22,wave+4),tip+Vector2(20,wave+13),tip+Vector2(0,10)])
		draw_colored_polygon(cloth,Color("#b53c35"))
		draw_line(tip+Vector2(4,1),tip+Vector2(4,9),Color("#e6d5b1"),1.0)
		draw_line(tip+Vector2(1,5),tip+Vector2(18,5+wave),Color("#e6d5b1"),1.0)

func _draw_birds() -> void:
	for i in range(8):
		var x:=-520.0+fmod(ambient_t*(22.0+i*2.0)+i*165.0,1080.0)
		var y:=-245.0+sin(ambient_t*.8+i)*18.0+float(i%3)*20.0
		var p:=Vector2(x,y)
		draw_line(p+Vector2(-6,1),p,Color(.15,.17,.16,.8),1.5)
		draw_line(p,p+Vector2(6,1),Color(.15,.17,.16,.8),1.5)

func _ambient_ship_ids() -> Array:
	var ids:Array=[]
	for ship_id in GameState.ships.keys():
		var ship:Dictionary=GameState.ships[ship_id]
		if str(ship.get("state",""))=="harbor_transit": ids.append(ship_id)
	return ids

func _draw_ambient_harbor_traffic() -> void:
	var lanes:Array=[
		[Vector2(-620,245),Vector2(620,140)],
		[Vector2(600,305),Vector2(-560,175)],
		[Vector2(-500,310),Vector2(520,245)]
	]
	var ids:Array=_ambient_ship_ids()
	for i in range(mini(ids.size(),lanes.size())):
		var ship:Dictionary=GameState.ships[ids[i]]
		var lane:Array=lanes[i]
		var a:Vector2=lane[0]
		var b:Vector2=lane[1]
		var u:=float(ship.get("route_progress",0.0))
		var pos:=a.lerp(b,u)
		_draw_sloop(pos,b-a,.68 if i!=1 else .53,Color("#51301f"))

func _player_ships_at_liverpool() -> Array:
	var ids:Array=[]
	for value in GameState.player_ship_ids():
		var ship_id:=str(value)
		if not GameState.ships.has(ship_id): continue
		var ship:Dictionary=GameState.ships[ship_id]
		var state:=str(ship.get("state",""))
		if str(ship.get("port_id",""))=="port_liverpool" and state in ["in_port","loading"]:
			ids.append(ship_id)
	return ids

func _draw_player_vessels() -> void:
	var ids:Array=_player_ships_at_liverpool()
	for i in range(mini(ids.size(),berth_positions.size())):
		var ship_id:=str(ids[i])
		var ship:Dictionary=GameState.ships[ship_id]
		var pos:Vector2=berth_positions[i]
		var vessel_class:=str(ship.get("class","Sloop")).to_lower()
		var scale_value:=.82 if vessel_class=="brig" else .68
		_draw_sloop(pos,Vector2(1,-.16),scale_value,Color("#7b3b26"))
		_draw_company_pennant(pos,scale_value)
		if str(ship.get("state",""))=="loading":
			_draw_loading_operation(pos,ship,i)

func _draw_company_pennant(pos:Vector2,k:float) -> void:
	var pole:=pos+Vector2(-2,-38)*k
	draw_line(pos+Vector2(-2,-16)*k,pole,Color("#3d281c"),1.2)
	var flutter:=sin(ambient_t*6.0+pos.x*.02)*2.0
	var flag:=PackedVector2Array([pole,pole+Vector2(17,3+flutter)*k,pole+Vector2(3,9)*k])
	draw_colored_polygon(flag,Color("#d2a33d"))

func _draw_loading_operation(ship_pos:Vector2,ship:Dictionary,index:int) -> void:
	var dock:=ship_pos+Vector2(78,-58)
	var progress:=float(ship.get("loading_progress",0.0))
	for crate_i in range(7):
		var phase:=fmod(sim_t*.21+float(crate_i)*.145+float(index)*.07,1.0)
		var p:=dock.lerp(ship_pos+Vector2(6,-12),phase)
		var lift:=sin(phase*PI)*18.0
		p.y-=lift
		_draw_crate(p,4.5)
	for pile_i in range(8):
		var col:=pile_i%4
		var row_index:=pile_i/4
		_draw_crate(dock+Vector2(col*9,row_index*7),4.0)
	var bar_pos:=dock+Vector2(-6,-18)
	draw_rect(Rect2(bar_pos,Vector2(58,6)),Color(.03,.05,.05,.8))
	draw_rect(Rect2(bar_pos+Vector2(1,1),Vector2(56.0*progress,4)),Color("#d7a842"))

func _draw_crate(pos:Vector2,size_value:float) -> void:
	draw_rect(Rect2(pos-Vector2(size_value*.5,size_value*.5),Vector2(size_value,size_value)),Color("#9a6a35"))
	draw_line(pos+Vector2(-size_value*.45,0),pos+Vector2(size_value*.45,0),Color("#543b25"),.7)

func _draw_sloop(pos:Vector2,direction:Vector2,scale_value:float,hull_color:Color) -> void:
	var d:=direction.normalized()
	var n:=Vector2(-d.y,d.x)
	var hull:=PackedVector2Array([
		pos-d*30.0*scale_value-n*7.0*scale_value,
		pos+d*31.0*scale_value,
		pos-d*30.0*scale_value+n*7.0*scale_value,
		pos-d*37.0*scale_value
	])
	draw_colored_polygon(hull,hull_color)
	var mast:=pos-d*2.0*scale_value
	draw_line(mast,mast-n*33.0*scale_value,Color("#31241b"),maxf(1.0,2.0*scale_value))
	var tip:=mast-n*31.0*scale_value
	var sail:=PackedVector2Array([tip,mast-n*4.0*scale_value-d*4.0*scale_value,tip+d*19.0*scale_value+n*10.0*scale_value])
	draw_colored_polygon(sail,Color(.93,.87,.72,.92))
	for i in range(3):
		var wake_start:=pos-d*(35.0+i*6.0)*scale_value
		draw_line(wake_start-n*(7.0+i*3.0)*scale_value,wake_start-d*18.0*scale_value-n*(12.0+i*4.0)*scale_value,Color(.85,.95,1,.35),1.0)

func _activity_multiplier() -> int:
	var leased:Array=GameState.player_company.get("leased_facility_ids",[])
	var extra:=0
	if "facility_liverpool_quay" in leased: extra+=2
	if "facility_warehouse_3" in leased: extra+=2
	return extra

func _draw_carts() -> void:
	var count:=5+_activity_multiplier()
	var road_y:=-78.0
	for i in range(count):
		var u:=fmod(sim_t*(.027+i*.0015)+i*(1.0/float(count)),1.0)
		var x:=lerpf(-570.0,520.0,u)
		var y:=road_y-x*.045+float(i%2)*16.0
		_draw_cart(Vector2(x,y),.62)

func _draw_cart(pos:Vector2,k:float) -> void:
	draw_rect(Rect2(pos,Vector2(22,9)*k),Color("#694629"))
	draw_circle(pos+Vector2(5,11)*k,3.0*k,Color("#26211b"))
	draw_circle(pos+Vector2(18,11)*k,3.0*k,Color("#26211b"))
	draw_line(pos+Vector2(22,4)*k,pos+Vector2(34,1)*k,Color("#4c3826"),1.5)
	draw_circle(pos+Vector2(38,1)*k,4.0*k,Color("#795438"))

func _draw_dock_workers() -> void:
	var count:=11+_activity_multiplier()*2
	for i in range(count):
		var lane:=i%3
		var u:=fmod(sim_t*(.018+lane*.003)+float(i)*.113,1.0)
		var a:=Vector2(-455+lane*48,-18+lane*19)
		var b:=Vector2(350-lane*70,-75+lane*28)
		var p:=a.lerp(b,u)
		_draw_worker(p,i%4)

func _draw_worker(pos:Vector2,variant_index:int) -> void:
	var bob:=sin(ambient_t*8.0+pos.x*.05)*1.0
	var coat:Color=[Color("#5b3725"),Color("#315368"),Color("#6c5935"),Color("#493d55")][variant_index]
	draw_circle(pos+Vector2(0,-5+bob),2.2,Color("#cda87e"))
	draw_rect(Rect2(pos+Vector2(-2,-3+bob),Vector2(4,7)),coat)
	draw_line(pos+Vector2(-1,4+bob),pos+Vector2(-2,8+bob),Color("#28231e"),1.0)
	draw_line(pos+Vector2(1,4+bob),pos+Vector2(2,8+bob),Color("#28231e"),1.0)

func _draw_crane_activity() -> void:
	var cranes:Array=[Vector2(-286,38),Vector2(-128,70),Vector2(112,62)]
	for i in range(cranes.size()):
		var top:Vector2=cranes[i]
		var drop:=26.0+sin(ambient_t*(1.4+i*.18)+i)*16.0
		draw_line(top,top+Vector2(0,drop),Color("#322c25"),1.0)
		var hook:=top+Vector2(0,drop)
		draw_line(hook+Vector2(-3,0),hook+Vector2(0,4),Color("#342c23"),1.0)
		draw_line(hook+Vector2(3,0),hook+Vector2(0,4),Color("#342c23"),1.0)
