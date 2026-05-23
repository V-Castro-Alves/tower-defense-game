extends Node

signal round_changed(current_round)
signal round_started(current_round)
signal round_completed(current_round, no_leak)

const TOTAL_ROUNDS: int = 10

var current_round: int = 0 : set = set_round
var round_active: bool = false
var spawn_timer: Timer
var spawn_list: Array = []
var spawn_interval: float = 1.0

var active_asteroids: int = 0
var leaks_this_round: int = 0

# Round structures mapping round number to details: [spawn_list, interval]
var round_definitions: Dictionary = {
	1: { "spawns": [1,1,1,1,1, 1,1,1,1,1], "interval": 1.5 }, # 10 Pebbles (P)
	2: { "spawns": [1,1,1,1, 1,1,1,1, 2,2], "interval": 1.3 }, # 4P, 4P, 2 Boulders (B)
	3: { "spawns": [1,1,1, 1,1,1, 2,2, 2,2], "interval": 1.2 }, # 3P, 3P, 2B, 2B
	4: { "spawns": [2,2,2, 2,2,2, 2,2,2,2], "interval": 1.0 }, # 3B, 3B, 4B
	5: { "spawns": [2, 2, {"tier": 2, "variant": "Hard Crust"}, 2, 2, 2, 3, {"tier": 3, "variant": "Magnetic Core"}], "interval": 1.0 },
	6: { "spawns": [2, 2, {"tier": 2, "variant": "Hard Crust"}, 2, 2, 2, {"tier": 2, "variant": "Hard Crust"}, 3, 3, {"tier": 3, "variant": "Magnetic Core"}], "interval": 0.9 },
	7: { "spawns": [2, 2, 2, 2, 2, 3, 3, {"tier": 3, "elemental": "Ice"}, {"tier": 3, "elemental": "Lava"}, {"tier": 3, "variant": "Blinding Tail"}], "interval": 0.8 },
	8: { "spawns": [3, 3, {"tier": 3, "elemental": "Ice"}, {"tier": 3, "elemental": "Ice"}, 3, 3, {"tier": 3, "elemental": "Lava"}, 3, {"tier": 4, "variant": "Hard Crust"}], "interval": 0.8 },
	9: { "spawns": [3, 3, {"tier": 3, "elemental": "Lava"}, {"tier": 3, "elemental": "Lava"}, 3, {"tier": 4, "variant": "Ring Belt"}, {"tier": 4, "variant": "Blinding Tail"}, {"tier": 4, "elemental": "Ice"}], "interval": 0.7 },
	10: { "spawns": [{"tier": 4, "variant": "Ring Belt"}, {"tier": 4, "variant": "Ring Belt"}, {"tier": 4, "elemental": "Lava"}, 4, {"tier": 5, "variant": "Magnetic Core"}], "interval": 0.6 }
}

func _ready():
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_spawn_next)
	add_child(spawn_timer)
	reset_rounds()

func reset_rounds():
	self.current_round = 0
	round_active = false
	active_asteroids = 0
	leaks_this_round = 0
	spawn_list.clear()
	if spawn_timer:
		spawn_timer.stop()

func set_round(value: int):
	current_round = clamp(value, 0, TOTAL_ROUNDS)
	round_changed.emit(current_round)

func start_round():
	if round_active or GameManager.current_phase == GameManager.GamePhase.GAME_OVER or GameManager.current_phase == GameManager.GamePhase.GAME_WON:
		return
		
	self.current_round += 1
	round_active = true
	leaks_this_round = 0
	active_asteroids = 0
	
	GameManager.current_phase = GameManager.GamePhase.ROUND_ACTIVE
	round_started.emit(current_round)
	
	# Load definitions
	var def = round_definitions.get(current_round, round_definitions[1])
	spawn_list.clear()
	for s in def["spawns"]:
		spawn_list.append(s)
	spawn_interval = def["interval"]
	
	spawn_timer.start(0.5) # Start first spawn shortly

func _spawn_next():
	if spawn_list.is_empty():
		return
		
	var spawn_data = spawn_list.pop_front()
	var tier = 1
	var variant = "None"
	var elemental = "None"
	
	if spawn_data is Dictionary:
		tier = spawn_data.get("tier", 1)
		variant = spawn_data.get("variant", "None")
		elemental = spawn_data.get("elemental", "None")
	else:
		tier = spawn_data as int
		
	# Spawn in the main scene
	get_tree().call_group("main", "spawn_asteroid", tier, 0.0, variant, elemental)
	
	if not spawn_list.is_empty():
		# Start timer for next spawn, considering current speed scale
		spawn_timer.start(spawn_interval)

func register_asteroid_spawn():
	active_asteroids += 1

func register_asteroid_removed():
	active_asteroids = max(0, active_asteroids - 1)
	_check_round_end()

func register_leak():
	leaks_this_round += 1

func _check_round_end():
	if round_active and spawn_list.is_empty() and active_asteroids == 0:
		round_active = false
		var no_leak = (leaks_this_round == 0)
		
		# Award bonus
		if no_leak:
			var bonus = current_round * 5
			EconomyManager.add_minerals(bonus)
			
		round_completed.emit(current_round, no_leak)
		
		if current_round >= TOTAL_ROUNDS:
			GameManager.current_phase = GameManager.GamePhase.GAME_WON
		else:
			GameManager.current_phase = GameManager.GamePhase.ROUND_PREPARATION
