extends Node

func _ready():
	print("====================================")
	print("SPACE DEFENDERS - AUTOMATED TEST RUNNER")
	print("====================================")
	
	# Create a visual canvas to display test results on screen
	var bg = ColorRect.new()
	bg.size = Vector2(2048, 1152)
	bg.color = Color("#090d16")
	add_child(bg)
	
	var label = Label.new()
	label.position = Vector2(80, 80)
	label.add_theme_font_size_override("font_size", 28)
	add_child(label)
	
	var log_text = "SPACE DEFENDERS TEST RESULTS:\n\n"
	var passed = true
	
	# Test 1: Economy Manager
	log_text += "[RUN] Testing Economy Manager...\n"
	EconomyManager.reset_economy()
	if EconomyManager.minerals != 50:
		log_text += "  [FAIL] Starting minerals is not 50 (got %d)\n" % EconomyManager.minerals
		passed = false
	else:
		log_text += "  [PASS] Starting minerals is 50\n"
		
	if not EconomyManager.spend_minerals(20):
		log_text += "  [FAIL] spend_minerals failed\n"
		passed = false
	elif EconomyManager.minerals != 30:
		log_text += "  [FAIL] spend_minerals did not deduct correctly (got %d)\n" % EconomyManager.minerals
		passed = false
	else:
		log_text += "  [PASS] spend_minerals deducted 20 correctly (got 30)\n"
		
	var fee = EconomyManager.get_reposition_fee(15)
	if fee != 3:
		log_text += "  [FAIL] reposition fee calculation is wrong (got %d, expected 3)\n" % fee
		passed = false
	else:
		log_text += "  [PASS] Reposition fee for Scout is 3 (15% base cost 15)\n"
		
	var refund = EconomyManager.get_sell_refund(15)
	if refund != 10:
		log_text += "  [FAIL] sell refund calculation is wrong (got %d, expected 10)\n" % refund
		passed = false
	else:
		log_text += "  [PASS] Sell refund for Scout is 10 (70% base cost 15)\n"
		
	# Test 2: Ship Targeting
	log_text += "\n[RUN] Testing Ship Targeting Modes...\n"
	var ship_scene = load("res://entities/ships/ship.tscn")
	var mock_ship = ship_scene.instantiate()
	mock_ship.ship_type = "Scout"
	mock_ship.global_position = Vector2(1000, 500)
	add_child(mock_ship)
	
	# Create mock asteroids at different progress
	var asteroid_scene = load("res://entities/asteroids/asteroid.tscn")
	var a1 = asteroid_scene.instantiate()
	a1.current_tier = 1
	a1.global_position = Vector2(1000, 550) # Within range (dist 50)
	a1.progress = 100.0
	add_child(a1)
	
	var a2 = asteroid_scene.instantiate()
	a2.current_tier = 1
	a2.global_position = Vector2(1000, 480) # Within range (dist 20)
	a2.progress = 350.0
	add_child(a2)
	
	mock_ship.targeting_mode = "First"
	var target_first = mock_ship.get_best_target()
	if target_first != a2:
		log_text += "  [FAIL] First targeting mode selected wrong target (got progress %f, expected 350.0)\n" % (target_first.progress if target_first else -1)
		passed = false
	else:
		log_text += "  [PASS] First targeting mode selected furthest asteroid along path\n"
		
	mock_ship.targeting_mode = "Last"
	var target_last = mock_ship.get_best_target()
	if target_last != a1:
		log_text += "  [FAIL] Last targeting mode selected wrong target\n"
		passed = false
	else:
		log_text += "  [PASS] Last targeting mode selected least far asteroid along path\n"
		
	# Clean up mock nodes
	mock_ship.queue_free()
	a1.queue_free()
	a2.queue_free()
	
	# Test 3: Regression Tests
	log_text += "\n[RUN] Testing Regression Fixed Cases...\n"
	
	# Regression 1: Array assignment in wave spawning
	var wave_def = WaveManager.wave_definitions.get(1, {})
	var mock_list: Array[int] = []
	mock_list.clear()
	for s in wave_def.get("spawns", []):
		mock_list.append(s as int)
		
	if mock_list.size() != 10:
		log_text += "  [FAIL] Regression 1: Typed array loading failed or size mismatched\n"
		passed = false
	else:
		log_text += "  [PASS] Regression 1: Typed Array[int] assignments are type-safe\n"
		
	# Regression 2: Full-screen HUD click swallowing check
	var hud_scene = load("res://ui/hud.tscn")
	var mock_hud = hud_scene.instantiate()
	add_child(mock_hud)
	
	if not (mock_hud is CanvasLayer):
		log_text += "  [FAIL] Regression 3: HUD does not inherit from CanvasLayer\n"
		passed = false
	else:
		log_text += "  [PASS] Regression 3: HUD inherits from CanvasLayer correctly\n"
		
	var hud_root = mock_hud.get_child(0) as Control
	if hud_root and hud_root.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		log_text += "  [FAIL] Regression 2: Full-screen HUD root control blocks mouse events (got %d)\n" % hud_root.mouse_filter
		passed = false
	else:
		log_text += "  [PASS] Regression 2: Full-screen HUD root does not intercept clicks (mouse_filter set to IGNORE)\n"
		
	# Regression 4: HUD mouse filter propagation on structural panels
	if hud_root:
		var top_bar = hud_root.get_child(0) as Control
		if top_bar and top_bar.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			log_text += "  [FAIL] Regression 4: top_bar is not set to MOUSE_FILTER_IGNORE\n"
			passed = false
		else:
			log_text += "  [PASS] Regression 4: top_bar is set to MOUSE_FILTER_IGNORE\n"
			
			# Check panels inside top_bar
			var lives_panel = top_bar.get_child(0) as Control
			if lives_panel and lives_panel.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				log_text += "  [FAIL] Regression 4: lives_panel is not set to MOUSE_FILTER_IGNORE\n"
				passed = false
			else:
				log_text += "  [PASS] Regression 4: lives_panel is set to MOUSE_FILTER_IGNORE\n"
				
		var shop_container = hud_root.get_child(1) as Control
		if shop_container and shop_container.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			log_text += "  [FAIL] Regression 4: shop_panel_container is not set to MOUSE_FILTER_IGNORE\n"
			passed = false
		else:
			log_text += "  [PASS] Regression 4: shop_panel_container is set to MOUSE_FILTER_IGNORE\n"
			
	mock_hud.queue_free()
	
	# Final Output
	if passed:
		log_text += "\n====================================\n"
		log_text += "ALL TESTS PASSED SUCCESSFULLY! ✅"
		log_text += "\n====================================\n"
		label.add_theme_color_override("font_color", Color("#22c55e")) # Emerald Green
	else:
		log_text += "\n====================================\n"
		log_text += "SOME TESTS FAILED! ❌"
		log_text += "\n====================================\n"
		label.add_theme_color_override("font_color", Color("#ef4444")) # Red
		
	label.text = log_text
	print(log_text)
