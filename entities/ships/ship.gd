extends Area2D

var ship_type: String = "Scout"
var display_name: String = "Scout"
var base_cost: int = 15
var range_tiles: float = 3.0
var fire_rate: float = 1.5
var damage: int = 1
var ship_color: Color = Color("#22c55e")

var range_pixels: float = 192.0
var targeting_mode: String = "First"
var is_ghost: bool = false
var is_selected: bool = false
var is_hovered: bool = false

var fire_cooldown: float = 0.0
var selected_range_color: Color = Color(0, 1, 0, 0.4)

# Drone Carrier specific
var drones: Array[Node2D] = []
var drone_angle: float = 0.0
var drone_cooldowns: Array[float] = [0.0, 0.0, 0.0]

func _ready():
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Set up a collision shape for mouse clicking
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(48, 48)
	collision.shape = shape
	add_child(collision)
	
	setup_type(ship_type)
	queue_redraw()

func setup_type(type: String):
	ship_type = type
	match ship_type:
		"Scout":
			display_name = "Scout"
			base_cost = 15
			range_tiles = 3.0
			fire_rate = 1.5
			damage = 1
			ship_color = Color("#22c55e") # Green
		"Laser Frigate":
			display_name = "Laser Frigate"
			base_cost = 35
			range_tiles = 5.0
			fire_rate = 1.0
			damage = 1
			ship_color = Color("#06b6d4") # Cyan
		"Missile Cruiser":
			display_name = "Missile Cruiser"
			base_cost = 50
			range_tiles = 4.0
			fire_rate = 0.6
			damage = 1
			ship_color = Color("#a855f7") # Purple
		"Ion Cannon":
			display_name = "Ion Cannon"
			base_cost = 60
			range_tiles = 5.0
			fire_rate = 0.4
			damage = 2
			ship_color = Color("#3b82f6") # Blue
		"Drone Carrier":
			display_name = "Drone Carrier"
			base_cost = 75
			range_tiles = 3.0
			fire_rate = 1.0 # Base fire rate doesn't apply directly; drones handle it
			damage = 1
			ship_color = Color("#ec4899") # Pink
			# Setup drones
			if drones.is_empty() and not is_ghost:
				for i in range(3):
					var drone = Node2D.new()
					drone.name = "Drone_" + str(i)
					add_child(drone)
					drones.append(drone)
		"Nuke Destroyer":
			display_name = "Nuke Destroyer"
			base_cost = 100
			range_tiles = 7.0
			fire_rate = 0.1 # 10s cooldown
			damage = 1
			ship_color = Color("#ffffff") # White
			
	range_pixels = range_tiles * 64.0
	selected_range_color = ship_color
	selected_range_color.a = 0.4
	
	queue_redraw()

func _on_mouse_entered():
	is_hovered = true
	queue_redraw()

func _on_mouse_exited():
	is_hovered = false
	queue_redraw()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_ghost:
			get_tree().call_group("main", "select_ship", self)
			get_viewport().set_input_as_handled()

func _draw():
	# Range Circle
	if is_selected or is_ghost or is_hovered:
		var fill_color = selected_range_color
		fill_color.a = 0.12
		draw_circle(Vector2.ZERO, range_pixels, fill_color)
		draw_arc(Vector2.ZERO, range_pixels, 0, 2*PI, 64, selected_range_color, 1.5, true)
		
	# Solid Square Representing Ship
	draw_rect(Rect2(-24, -24, 48, 48), ship_color)
	# Accent borders
	draw_rect(Rect2(-24, -24, 48, 48), Color.BLACK, false, 2.0)
	
	# Type specifics visual decoration inside square
	match ship_type:
		"Scout":
			# Arrow decoration
			draw_line(Vector2(0, -16), Vector2(-12, 12), Color.BLACK, 2.0)
			draw_line(Vector2(0, -16), Vector2(12, 12), Color.BLACK, 2.0)
			draw_line(Vector2(-12, 12), Vector2(0, 4), Color.BLACK, 2.0)
			draw_line(Vector2(12, 12), Vector2(0, 4), Color.BLACK, 2.0)
		"Laser Frigate":
			# Center lens
			draw_circle(Vector2.ZERO, 8.0, Color.BLACK)
			draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
		"Missile Cruiser":
			# Rocket cross
			draw_rect(Rect2(-6, -18, 12, 36), Color.BLACK)
			draw_rect(Rect2(-18, -6, 36, 12), Color.BLACK)
		"Ion Cannon":
			# Heavy barrel indicator
			draw_rect(Rect2(-8, -20, 16, 12), Color.BLACK)
		"Drone Carrier":
			# Inner core
			draw_circle(Vector2.ZERO, 6.0, Color.BLACK)
		"Nuke Destroyer":
			# Hazard symbol/black dots
			draw_circle(Vector2.ZERO, 8.0, Color.BLACK)
			draw_circle(Vector2(-10, -6), 4.0, Color.BLACK)
			draw_circle(Vector2(10, -6), 4.0, Color.BLACK)
			draw_circle(Vector2(0, 10), 4.0, Color.BLACK)

	# Draw drones programmatically for Carrier
	if ship_type == "Drone Carrier" and not is_ghost:
		for i in range(drones.size()):
			var angle = drone_angle + (i * PI * 2.0 / 3.0)
			var drone_pos = Vector2.from_angle(angle) * 44.0
			draw_rect(Rect2(drone_pos.x - 6, drone_pos.y - 6, 12, 12), Color("#f472b6"))
			draw_rect(Rect2(drone_pos.x - 6, drone_pos.y - 6, 12, 12), Color.BLACK, false, 1.0)

func _process(delta):
	if is_ghost:
		return
		
	# Handle shooting cooldowns
	if fire_cooldown > 0.0:
		fire_cooldown -= delta
	else:
		_shoot()
		
	# Orbit drones for Carrier
	if ship_type == "Drone Carrier":
		drone_angle += delta * 2.0
		queue_redraw()
		
		# Process drone shooting
		for i in range(drones.size()):
			if drone_cooldowns[i] > 0.0:
				drone_cooldowns[i] -= delta
			else:
				_shoot_drone(i)

func get_asteroids_in_range() -> Array:
	var in_range = []
	var asteroids = get_tree().get_nodes_in_group("asteroids")
	for ast in asteroids:
		if is_instance_valid(ast):
			var dist = global_position.distance_to(ast.global_position)
			if dist <= range_pixels:
				in_range.append(ast)
	return in_range

func get_best_target() -> Node2D:
	var list = get_asteroids_in_range()
	if list.is_empty():
		return null
		
	var best = null
	match targeting_mode:
		"First":
			var max_prog = -1.0
			for ast in list:
				if ast.progress > max_prog:
					max_prog = ast.progress
					best = ast
		"Last":
			var min_prog = INF
			for ast in list:
				if ast.progress < min_prog:
					min_prog = ast.progress
					best = ast
		"Strongest":
			var max_tier = -1
			var max_prog = -1.0
			for ast in list:
				if ast.current_tier > max_tier or (ast.current_tier == max_tier and ast.progress > max_prog):
					max_tier = ast.current_tier
					max_prog = ast.progress
					best = ast
		"Closest":
			var min_dist = INF
			for ast in list:
				var dist = global_position.distance_to(ast.global_position)
				if dist < min_dist:
					min_dist = dist
					best = ast
	return best

func _shoot():
	var target = get_best_target()
	if not target:
		return
		
	fire_cooldown = 1.0 / fire_rate
	
	match ship_type:
		"Scout", "Ion Cannon":
			# Spawn standard homing projectile
			var proj_scene = load("res://entities/projectiles/projectile.tscn")
			var p = proj_scene.instantiate()
			p.damage = damage
			p.target = target
			p.global_position = global_position
			p.projectile_color = ship_color
			get_parent().add_child(p)
			
		"Missile Cruiser":
			# Spawn splash missile
			var proj_scene = load("res://entities/projectiles/projectile.tscn")
			var p = proj_scene.instantiate()
			p.damage = damage
			p.target = target
			p.splash_radius = 96.0 # 1.5 tiles
			p.global_position = global_position
			p.projectile_color = ship_color
			get_parent().add_child(p)
			
		"Laser Frigate":
			# Straight-line ray sweep piercing all asteroids along line
			var end_pos = global_position + (target.global_position - global_position).normalized() * range_pixels
			
			# Spawn visual beam effect
			var beam = Node2D.new()
			beam.set_script(preload("res://entities/ships/laser_beam_effect.gd"))
			beam.start_pos = global_position
			beam.end_pos = end_pos
			beam.beam_color = ship_color
			get_parent().add_child(beam)
			
			# Pierce damage check
			var asteroids = get_asteroids_in_range()
			for ast in asteroids:
				if is_instance_valid(ast):
					# Check distance from asteroid point to laser line segment
					var closest = Geometry2D.get_closest_point_to_segment(ast.global_position, global_position, end_pos)
					if ast.global_position.distance_to(closest) < (ast.size / 2.0 + 8.0):
						ast.take_damage(damage)
						
		"Nuke Destroyer":
			# Screen clear explosion
			# Visual flash effect in main scene
			get_tree().call_group("main", "spawn_nuke_flash")
			
			# Apply 1 damage (split) to every single active asteroid
			var asteroids = get_tree().get_nodes_in_group("asteroids")
			for ast in asteroids:
				if is_instance_valid(ast):
					ast.take_damage(1)

func _shoot_drone(index: int):
	# Find a target within range
	var target = get_best_target()
	if not target:
		return
		
	drone_cooldowns[index] = 0.6 # Drones fire fast!
	
	var angle = drone_angle + (index * PI * 2.0 / 3.0)
	var d_pos = global_position + Vector2.from_angle(angle) * 44.0
	
	# Spawn a small drone laser or projectile
	var proj_scene = load("res://entities/projectiles/projectile.tscn")
	var p = proj_scene.instantiate()
	p.damage = 1
	p.target = target
	p.speed = 800.0 # Drone shots are fast
	p.global_position = d_pos
	p.projectile_color = Color("#f472b6")
	get_parent().add_child(p)
