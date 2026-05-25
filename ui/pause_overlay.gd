extends Control

var panel: PanelContainer

func _ready():
	# Allow overlay processing during paused states
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Full screen anchors
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP # Block inputs under the panel
	
	# Translucent dark backdrop
	var bg = ColorRect.new()
	bg.size = Vector2(2048, 1152)
	bg.color = Color(0.02, 0.04, 0.08, 0.7)
	add_child(bg)
	
	# Central modal panel
	panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.12, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color("#06b6d4") # Glowing tech blue border
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", style)
	
	panel.custom_minimum_size = Vector2(560, 360)
	panel.position = Vector2(2048.0 / 2.0 - 560.0 / 2.0, 1152.0 / 2.0 - 360.0 / 2.0)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "⏸️ BRIDGE ON STANDBY ⏸️"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#06b6d4"))
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "ALL SECTORS AND DEFENSIVE SYSTEMS FROZEN"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("#64748b"))
	subtitle.add_theme_font_size_override("font_size", 12)
	vbox.add_child(subtitle)
	
	vbox.add_child(HSeparator.new())
	
	var desc = Label.new()
	desc.text = "Click 'CONTINUE' or press the 'Esc' key to resume operations."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 16)
	vbox.add_child(desc)
	
	vbox.add_child(HSeparator.new())
	
	# Buttons
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_hbox)
	
	# Continue Button
	var btn_continue = Button.new()
	btn_continue.text = "CONTINUE"
	btn_continue.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_continue.custom_minimum_size.y = 52
	btn_continue.add_theme_font_size_override("font_size", 16)
	btn_continue.pressed.connect(_on_continue_pressed)
	
	var style_continue = StyleBoxFlat.new()
	style_continue.bg_color = Color(0.08, 0.16, 0.1, 0.9)
	style_continue.border_width_left = 2
	style_continue.border_width_top = 2
	style_continue.border_width_right = 2
	style_continue.border_width_bottom = 2
	style_continue.border_color = Color("#22c55e")
	style_continue.corner_radius_top_left = 8
	style_continue.corner_radius_top_right = 8
	style_continue.corner_radius_bottom_left = 8
	style_continue.corner_radius_bottom_right = 8
	btn_continue.add_theme_stylebox_override("normal", style_continue)
	btn_continue.add_theme_stylebox_override("hover", style_continue)
	btn_continue.add_theme_stylebox_override("pressed", style_continue)
	btn_hbox.add_child(btn_continue)
	
	# Menu Button
	var btn_menu = Button.new()
	btn_menu.text = "ABANDON MISSION"
	btn_menu.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_menu.custom_minimum_size.y = 52
	btn_menu.add_theme_font_size_override("font_size", 16)
	btn_menu.pressed.connect(_on_menu_pressed)
	
	var style_menu = StyleBoxFlat.new()
	style_menu.bg_color = Color(0.35, 0.12, 0.12, 0.9)
	style_menu.border_width_left = 2
	style_menu.border_width_top = 2
	style_menu.border_width_right = 2
	style_menu.border_width_bottom = 2
	style_menu.border_color = Color("#ef4444")
	style_menu.corner_radius_top_left = 8
	style_menu.corner_radius_top_right = 8
	style_menu.corner_radius_bottom_left = 8
	style_menu.corner_radius_bottom_right = 8
	btn_menu.add_theme_stylebox_override("normal", style_menu)
	btn_menu.add_theme_stylebox_override("hover", style_menu)
	btn_menu.add_theme_stylebox_override("pressed", style_menu)
	btn_hbox.add_child(btn_menu)

func _on_continue_pressed():
	# Resume game using HUD helper
	var hud = get_parent()
	if hud and hud.has_method("toggle_pause"):
		hud.toggle_pause()

func _on_menu_pressed():
	# Resume physics first so reloads compile cleanly
	get_tree().paused = false
	
	# Full reset back to Bridge Menu
	GameManager.reset_game()
	EconomyManager.reset_economy()
	RoundManager.reset_rounds()
	MetricsManager.reset_metrics()
	
	get_tree().reload_current_scene()
