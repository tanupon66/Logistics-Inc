extends Node

var speed:int = 0
var accumulator:float = 0.0
var seconds_per_game_hour:float = 0.35

func _ready() -> void:
	set_process(true)

func _process(delta:float) -> void:
	if speed <= 0 or GameState.world.is_empty():
		return
	accumulator += delta * float(speed)
	while accumulator >= seconds_per_game_hour:
		accumulator -= seconds_per_game_hour
		_advance_hour()

func set_speed(value:int) -> void:
	speed = clampi(value, 0, 4)
	EventBus.time_speed_changed.emit(speed)

func _advance_hour() -> void:
	var hour := int(GameState.world.get("hour", 8)) + 1
	if hour >= 24:
		hour = 0
		_advance_day()
	GameState.world["hour"] = hour

func _advance_day() -> void:
	var day := int(GameState.world.get("day", 1)) + 1
	var month := int(GameState.world.get("month", 1))
	var year := int(GameState.world.get("year", 1750))
	var days_in_month := _days_in_month(month, year)
	if day > days_in_month:
		day = 1
		month += 1
		if month > 12:
			month = 1
			year += 1
	GameState.world["day"] = day
	GameState.world["month"] = month
	GameState.world["year"] = year
	EventBus.day_advanced.emit(day, month, year)

func _days_in_month(month:int, year:int) -> int:
	match month:
		4, 6, 9, 11:
			return 30
		2:
			var leap := year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
			return 29 if leap else 28
		_:
			return 31
