extends PathFollow2D

var current_tier: int = 1
var speed: float = 100.0
var lives_on_leak: int = 1
var size: float = 32.0
var color: Color = Color.WHITE

var collision_shape: CollisionShape2D
var area: Area2D

func _ready():
	loop = false
	
	# Create Area2D and CollisionShape2D
	area = Area2D.new()
	area.collision_layer = 2 # Asteroid layer
	area.collision_mask = 0
	add_child(area)
	
	collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size, size)
	collision_shape.shape = shape
	area.add_child(collision_shape)
	
	setup_tier(current_tier)
	WaveManager.register_asteroid_spawn()

func setup_tier(t: int):
	current_tier = t
	match current_tier:
		5:
			speed = 40.0
			lives_on_leak = 32
			size = 64.0
			color = Color("#7f1d1d") # Dark Red
		4:
			speed = 60.0
			lives_on_leak = 16
			size = 48.0
			color = Color("#dc2626") # Red
		3:
			speed = 90.0
			lives_on_leak = 8
			size = 36.0
			color = Color("#ea580c") # Orange
		2:
			speed = 130.0
			lives_on_leak = 4
			size = 24.0
			color = Color("#f97316") # Light Orange
		1:
			speed = 180.0
			lives_on_leak = 1
			size = 16.0
			color = Color("#eab308") # Yellow
			
	if collision_shape and collision_shape.shape:
		collision_shape.shape.size = Vector2(size, size)
		
	queue_redraw()

func _draw():
	# Draw solid square representing the asteroid
	draw_rect(Rect2(-size / 2, -size / 2, size, size), color)
	# Subtle dark inner border to give dimension
	draw_rect(Rect2(-size / 2, -size / 2, size, size), Color(0, 0, 0, 0.4), false, 2.0)

func _process(delta):
	# Move forward on path
	progress += speed * delta
	
	if progress_ratio >= 1.0:
		# Leak asteroid
		GameManager.lose_lives(lives_on_leak)
		WaveManager.register_leak()
		WaveManager.register_asteroid_removed()
		queue_free()

func take_damage(amount: int):
	if is_queued_for_deletion():
		return
		
	var new_tier = current_tier - amount
	if new_tier <= 0:
		# Entirely destroyed
		if current_tier == 1:
			EconomyManager.add_minerals(1)
		elif current_tier == 2:
			# Destroyed Boulder completely (worth 4 minerals)
			EconomyManager.add_minerals(4)
		else:
			# Destroys bigger ones completely (adds full equivalent value)
			EconomyManager.add_minerals(get_mineral_value(current_tier))
			
		WaveManager.register_asteroid_removed()
		queue_free()
	else:
		# Boulder splits award 2 minerals
		if current_tier == 2:
			EconomyManager.add_minerals(2)
			
		# Spawn two children staggered on path using deferred calls to prevent physics flush errors
		for main in get_tree().get_nodes_in_group("main"):
			main.call_deferred("spawn_asteroid", new_tier, progress - 8.0)
			main.call_deferred("spawn_asteroid", new_tier, progress + 8.0)
		
		# Remove parent
		WaveManager.register_asteroid_removed()
		queue_free()

func get_mineral_value(tier: int) -> int:
	match tier:
		5: return 32
		4: return 16
		3: return 8
		2: return 4
		1: return 1
	return 0
