extends Node2D

var start_pos: Vector2
var end_pos: Vector2
var beam_color: Color = Color("#06b6d4")
var duration: float = 0.2
var elapsed: float = 0.0

func _ready():
	queue_redraw()

func _process(delta):
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
	queue_redraw()

func _draw():
	var alpha = lerp(1.0, 0.0, elapsed / duration)
	var col = beam_color
	col.a = alpha
	
	# Draw glowing outer line
	draw_line(start_pos - global_position, end_pos - global_position, col, 6.0)
	# Draw bright inner line
	var white_col = Color.WHITE
	white_col.a = alpha
	draw_line(start_pos - global_position, end_pos - global_position, white_col, 2.0)
