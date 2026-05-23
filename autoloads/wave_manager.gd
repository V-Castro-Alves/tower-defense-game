extends Node

signal wave_changed(current_wave)
signal wave_started(current_wave)
signal wave_completed(current_wave, no_leak)

const TOTAL_WAVES: int = 10

var current_wave: int = 0 : set = set_wave
var wave_active: bool = false
var spawn_timer: Timer
var spawn_list: Array[int] = []
var spawn_interval: float = 1.0

var active_asteroids: int = 0
var leaks_this_wave: int = 0

# Wave structures mapping wave number to details: [spawn_list, interval]
var wave_definitions: Dictionary = {
	1: { "spawns": [1,1,1,1,1, 1,1,1,1,1], "interval": 1.5 }, # 10 Pebbles (P)
	2: { "spawns": [1,1,1,1, 1,1,1,1, 2,2], "interval": 1.3 }, # 4P, 4P, 2 Boulders (B)
	3: { "spawns": [1,1,1, 1,1,1, 2,2, 2,2], "interval": 1.2 }, # 3P, 3P, 2B, 2B
	4: { "spawns": [2,2,2, 2,2,2, 2,2,2,2], "interval": 1.0 }, # 3B, 3B, 4B
	5: { "spawns": [2,2,2, 2,2,2, 3,3], "interval": 1.0 }, # 3B, 3B, 2 Meteors (M)
	6: { "spawns": [2,2,2,2, 2,2,2,2, 3,3,3], "interval": 0.9 }, # 4B, 4B, 3M
	7: { "spawns": [2,2,2, 2,2, 3,3,3, 3,3], "interval": 0.8 }, # 3B, 2B, 3M, 2M
	8: { "spawns": [3,3,3,3, 3,3,3,3, 4], "interval": 0.8 }, # 4M, 4M, 1 Giant (G)
	9: { "spawns": [3,3,3, 3,3, 4,4, 4], "interval": 0.7 }, # 3M, 2M, 2G, 1G
	10: { "spawns": [4,4, 4,4, 5], "interval": 0.6 } # 2G, 2G, 1 Planet Chunk (PC)
}

func _ready():
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_spawn_next)
	add_child(spawn_timer)
	reset_waves()

func reset_waves():
	self.current_wave = 0
	wave_active = false
	active_asteroids = 0
	leaks_this_wave = 0
	spawn_list.clear()
	if spawn_timer:
		spawn_timer.stop()

func set_wave(value: int):
	current_wave = clamp(value, 0, TOTAL_WAVES)
	wave_changed.emit(current_wave)

func start_wave():
	if wave_active or GameManager.current_phase == GameManager.GamePhase.GAME_OVER or GameManager.current_phase == GameManager.GamePhase.GAME_WON:
		return
		
	self.current_wave += 1
	wave_active = true
	leaks_this_wave = 0
	active_asteroids = 0
	
	GameManager.current_phase = GameManager.GamePhase.WAVE_ACTIVE
	wave_started.emit(current_wave)
	
	# Load definitions
	var def = wave_definitions.get(current_wave, wave_definitions[1])
	spawn_list.clear()
	for s in def["spawns"]:
		spawn_list.append(s as int)
	spawn_interval = def["interval"]
	
	spawn_timer.start(0.5) # Start first spawn shortly

func _spawn_next():
	if spawn_list.is_empty():
		return
		
	var tier = spawn_list.pop_front()
	# Spawn in the main scene
	get_tree().call_group("main", "spawn_asteroid", tier, 0.0)
	
	if not spawn_list.is_empty():
		# Start timer for next spawn, considering current speed scale
		spawn_timer.start(spawn_interval)

func register_asteroid_spawn():
	active_asteroids += 1

func register_asteroid_removed():
	active_asteroids = max(0, active_asteroids - 1)
	_check_wave_end()

func register_leak():
	leaks_this_wave += 1

func _check_wave_end():
	if wave_active and spawn_list.is_empty() and active_asteroids == 0:
		wave_active = false
		var no_leak = (leaks_this_wave == 0)
		
		# Award bonus
		if no_leak:
			var bonus = current_wave * 5
			EconomyManager.add_minerals(bonus)
			
		wave_completed.emit(current_wave, no_leak)
		
		if current_wave >= TOTAL_WAVES:
			GameManager.current_phase = GameManager.GamePhase.GAME_WON
		else:
			GameManager.current_phase = GameManager.GamePhase.WAVE_PREPARATION
