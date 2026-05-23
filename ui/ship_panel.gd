extends Control

var current_ship: Node2D = null

var panel: PanelContainer
var title_label: Label
var target_dropdown: OptionButton
var reposition_btn: Button
var sell_btn: Button

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Programmatic visual panel
	panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.12, 0.9) # Dark translucent
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.5, 0.8, 0.7) # Glowing border
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	
	panel.custom_minimum_size = Vector2(320, 220)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# Header with title and close
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	title_label = Label.new()
	title_label.text = "SHIP INFO"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title_label)
	
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(24, 24)
	close_btn.pressed.connect(func(): close_panel())
	header.add_child(close_btn)
	
	vbox.add_child(HSeparator.new())
	
	# Targeting dropdown
	var target_box = HBoxContainer.new()
	target_box.add_theme_constant_override("separation", 10)
	vbox.add_child(target_box)
	
	var target_lbl = Label.new()
	target_lbl.text = "Target:"
	target_lbl.add_theme_font_size_override("font_size", 16)
	target_box.add_child(target_lbl)
	
	target_dropdown = OptionButton.new()
	target_dropdown.size_flags_horizontal = SIZE_EXPAND_FILL
	target_dropdown.add_item("First")
	target_dropdown.add_item("Last")
	target_dropdown.add_item("Strongest")
	target_dropdown.add_item("Closest")
	target_dropdown.item_selected.connect(_on_target_mode_selected)
	target_box.add_child(target_dropdown)
	
	vbox.add_child(HSeparator.new())
	
	# Action buttons
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	vbox.add_child(actions)
	
	reposition_btn = Button.new()
	reposition_btn.text = "Reposition\n💎--"
	reposition_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	reposition_btn.custom_minimum_size.y = 52
	reposition_btn.pressed.connect(_on_reposition_pressed)
	
	var repo_style = StyleBoxFlat.new()
	repo_style.bg_color = Color(0.12, 0.2, 0.35, 0.8)
	repo_style.corner_radius_top_left = 6
	repo_style.corner_radius_top_right = 6
	repo_style.corner_radius_bottom_left = 6
	repo_style.corner_radius_bottom_right = 6
	reposition_btn.add_theme_stylebox_override("normal", repo_style)
	reposition_btn.add_theme_stylebox_override("hover", repo_style)
	reposition_btn.add_theme_stylebox_override("pressed", repo_style)
	reposition_btn.add_theme_stylebox_override("disabled", repo_style)
	actions.add_child(reposition_btn)
	
	sell_btn = Button.new()
	sell_btn.text = "Sell\n+💎--"
	sell_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	sell_btn.custom_minimum_size.y = 52
	sell_btn.pressed.connect(_on_sell_pressed)
	
	var sell_style = StyleBoxFlat.new()
	sell_style.bg_color = Color(0.35, 0.12, 0.12, 0.8)
	sell_style.corner_radius_top_left = 6
	sell_style.corner_radius_top_right = 6
	sell_style.corner_radius_bottom_left = 6
	sell_style.corner_radius_bottom_right = 6
	sell_btn.add_theme_stylebox_override("normal", sell_style)
	sell_btn.add_theme_stylebox_override("hover", sell_style)
	sell_btn.add_theme_stylebox_override("pressed", sell_style)
	actions.add_child(sell_btn)

func open_for_ship(ship: Node2D):
	current_ship = ship
	visible = true
	
	# Update fields
	title_label.text = current_ship.display_name
	
	# Targeting dropdown option index matching mode
	var idx = 0
	match current_ship.targeting_mode:
		"First": idx = 0
		"Last": idx = 1
		"Strongest": idx = 2
		"Closest": idx = 3
	target_dropdown.selected = idx
	
	# Reposition fee
	var repo_fee = EconomyManager.get_reposition_fee(current_ship.base_cost)
	reposition_btn.text = "Reposition\n💎 %d" % repo_fee
	
	# Disable reposition if player cannot afford
	if EconomyManager.can_afford(repo_fee):
		reposition_btn.disabled = false
		reposition_btn.modulate = Color.WHITE
	else:
		reposition_btn.disabled = true
		reposition_btn.modulate = Color(1, 1, 1, 0.4)
		
	# Sell refund
	var refund = EconomyManager.get_sell_refund(current_ship.base_cost)
	sell_btn.text = "Sell\n+💎 %d" % refund
	
	# Positioning near ship and clamping to viewport
	var desired_pos = current_ship.global_position + Vector2(-160, -260)
	global_position = desired_pos.clamp(Vector2(20, 20), Vector2(2048 - 340, 1152 - 380))

func close_panel():
	visible = false
	current_ship = null
	if get_parent().get_parent().selected_ship:
		get_parent().get_parent().select_ship(null)

func _on_target_mode_selected(index: int):
	if not is_instance_valid(current_ship):
		return
	var mode = "First"
	match index:
		0: mode = "First"
		1: mode = "Last"
		2: mode = "Strongest"
		3: mode = "Closest"
	current_ship.targeting_mode = mode

func _on_reposition_pressed():
	if not is_instance_valid(current_ship):
		return
	# Trigger reposition state in main
	get_parent().get_parent().start_reposition_mode(current_ship)
	visible = false

func _on_sell_pressed():
	if not is_instance_valid(current_ship):
		return
		
	var refund = EconomyManager.get_sell_refund(current_ship.base_cost)
	EconomyManager.add_minerals(refund)
	
	# Delete ship
	current_ship.queue_free()
	close_panel()
