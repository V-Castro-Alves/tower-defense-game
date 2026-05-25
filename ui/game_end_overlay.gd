extends Control

var is_victory: bool = false
var panel: PanelContainer
var title_label: Label
var stats_grid: GridContainer

func setup_overlay(victory_state: bool):
	is_victory = victory_state
	
	# Full screen anchors
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP # Block inputs to playfield
	
	# Translucent dark backdrop (glassmorphism feel)
	var bg = ColorRect.new()
	bg.size = Vector2(2048, 1152)
	bg.color = Color(0.02, 0.04, 0.08, 0.85)
	add_child(bg)
	
	# Central modal panel
	panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.12, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	
	# Neon styling based on Victory/Defeat
	var accent_color = Color("#ef4444") # Red for defeat
	if is_victory:
		accent_color = Color("#fbbf24") # Warm gold for victory
		
	style.border_color = accent_color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", style)
	
	panel.custom_minimum_size = Vector2(720, 540)
	panel.position = Vector2(2048.0 / 2.0 - 720.0 / 2.0, 1152.0 / 2.0 - 540.0 / 2.0)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	# Title Header
	title_label = Label.new()
	if is_victory:
		title_label.text = "🏆 MISSION ACCOMPLISHED 🏆"
		title_label.add_theme_color_override("font_color", Color("#fbbf24")) # Gold
	else:
		title_label.text = "💀 PERIMETER BREACHED 💀"
		title_label.add_theme_color_override("font_color", Color("#ef4444")) # Red
		
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title_label)
	
	var subtitle = Label.new()
	if is_victory:
		subtitle.text = "ALL SECTORS PURGED — SPACE STATION SECURED"
		subtitle.add_theme_color_override("font_color", Color("#38bdf8")) # Neon Cyan
	else:
		subtitle.text = "DEFENSIVE GRID COLLAPSED — BRIDGE COMMAND LOST"
		subtitle.add_theme_color_override("font_color", Color("#94a3b8")) # Muted grey
		
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	vbox.add_child(subtitle)
	
	vbox.add_child(HSeparator.new())
	
	# Playthrough performance stats block
	var stats_lbl = Label.new()
	stats_lbl.text = "TACTICAL PERFORMANCE DEBRIEF:"
	stats_lbl.add_theme_color_override("font_color", Color("#64748b"))
	stats_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(stats_lbl)
	
	stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 32)
	stats_grid.add_theme_constant_override("v_separation", 14)
	stats_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_child(stats_grid)
	
	# Retrieve stats programmatically from Managers
	var total_time = Time.get_unix_time_from_system() - MetricsManager.playthrough_start_time
	var mins = int(total_time) / 60
	var secs = int(total_time) % 60
	var time_str = "%dm %ds" % [mins, secs]
	
	var rounds_completed = RoundManager.current_round
	if not is_victory and RoundManager.round_active:
		rounds_completed = max(0, RoundManager.current_round - 1)
		
	var total_placed = 0
	for t in MetricsManager.ship_types:
		total_placed += MetricsManager.tower_stats[t]["placed"]
		
	var total_spent = MetricsManager.current_round_placements_cost
	for r in MetricsManager.round_metrics:
		total_spent += r["spent_this_round"]
		
	_add_stat_row("Operations Duration:", time_str)
	_add_stat_row("Rounds Fully Secured:", "%d / 10" % rounds_completed)
	_add_stat_row("Starships Deployed:", "%d Ships" % total_placed)
	_add_stat_row("Total Minerals Invested:", "💎 %d" % total_spent)
	
	vbox.add_child(HSeparator.new())
	
	# Action buttons row
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 20)
	btn_hbox.size_flags_vertical = SIZE_SHRINK_END
	vbox.add_child(btn_hbox)
	
	# Restart Button
	var btn_restart = Button.new()
	btn_restart.text = "RESTART MISSION"
	btn_restart.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_restart.custom_minimum_size.y = 56
	btn_restart.add_theme_font_size_override("font_size", 18)
	btn_restart.pressed.connect(_on_restart_pressed)
	
	var style_restart = StyleBoxFlat.new()
	style_restart.bg_color = Color(0.08, 0.16, 0.1, 0.9)
	style_restart.border_width_left = 2
	style_restart.border_width_top = 2
	style_restart.border_width_right = 2
	style_restart.border_width_bottom = 2
	style_restart.border_color = Color("#22c55e") # Green glow
	style_restart.corner_radius_top_left = 8
	style_restart.corner_radius_top_right = 8
	style_restart.corner_radius_bottom_left = 8
	style_restart.corner_radius_bottom_right = 8
	btn_restart.add_theme_stylebox_override("normal", style_restart)
	btn_restart.add_theme_stylebox_override("hover", style_restart)
	btn_restart.add_theme_stylebox_override("pressed", style_restart)
	btn_hbox.add_child(btn_restart)
	
	# Menu Button
	var btn_menu = Button.new()
	btn_menu.text = "RETURN TO BRIDGE"
	btn_menu.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_menu.custom_minimum_size.y = 56
	btn_menu.add_theme_font_size_override("font_size", 18)
	btn_menu.pressed.connect(_on_menu_pressed)
	
	var style_menu = StyleBoxFlat.new()
	style_menu.bg_color = Color(0.12, 0.15, 0.22, 0.9)
	style_menu.border_width_left = 2
	style_menu.border_width_top = 2
	style_menu.border_width_right = 2
	style_menu.border_width_bottom = 2
	style_menu.border_color = Color("#38bdf8") # Cyan glow
	style_menu.corner_radius_top_left = 8
	style_menu.corner_radius_top_right = 8
	style_menu.corner_radius_bottom_left = 8
	style_menu.corner_radius_bottom_right = 8
	btn_menu.add_theme_stylebox_override("normal", style_menu)
	btn_menu.add_theme_stylebox_override("hover", style_menu)
	btn_menu.add_theme_stylebox_override("pressed", style_menu)
	btn_hbox.add_child(btn_menu)

func _add_stat_row(label_text: String, val_text: String):
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color("#94a3b8"))
	stats_grid.add_child(lbl)
	
	var val = Label.new()
	val.text = val_text
	val.add_theme_font_size_override("font_size", 16)
	val.add_theme_color_override("font_color", Color.WHITE)
	stats_grid.add_child(val)

func _on_restart_pressed():
	# Capture active configurations
	var is_dev = GameManager.dev_mode
	
	# Execute resets
	GameManager.reset_game()
	EconomyManager.reset_economy()
	RoundManager.reset_rounds()
	MetricsManager.reset_metrics()
	
	# Re-apply launch states to immediately bypass main menu on reload
	GameManager.dev_mode = is_dev
	GameManager.lives = 99999 if is_dev else 20
	EconomyManager.minerals = 99999 if is_dev else 200
	GameManager.current_phase = GameManager.GamePhase.ROUND_PREPARATION
	
	get_tree().reload_current_scene()

func _on_menu_pressed():
	# Full reset back to Pre Game Main Menu setup
	GameManager.reset_game()
	EconomyManager.reset_economy()
	RoundManager.reset_rounds()
	MetricsManager.reset_metrics()
	
	get_tree().reload_current_scene()
