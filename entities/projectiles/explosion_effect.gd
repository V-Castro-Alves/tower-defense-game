extends Node2D

var radius: float = 96.0
var current_radius: float = 0.0
var duration: float = 0.3
var elapsed: float = 0.0
var color: Color = Color(0.9, 0.4, 0.1, 0.8) # Vibrant orange

func _ready():
	queue_redraw()

func _process(delta):
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
		
	var t = elapsed / duration
	current_radius = lerp(0.0, radius, t)
	color.a = lerp(0.8, 0.0, t)
	queue_redraw()

func _draw():
	# Draw expanding ring
	draw_arc(Vector2.ZERO, current_radius, 0, 2*PI, 32, color, 4.0, true)
	# Draw slightly filled center
	var fill_color = color
	fill_color.a *= 0.3
	draw_circle(Vector2.ZERO, current_radius, fill_color)
