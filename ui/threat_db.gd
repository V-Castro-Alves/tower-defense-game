extends Control

# Custom Control node to programmatically draw exact asteroid previews
class ThreatPreview extends Control:
	var current_tier: int = 1
	var variant: String = "None"
	var elemental_type: String = "None"
	var draw_size: float = 32.0
	var color: Color = Color.WHITE

	func setup_preview(t: int, v: String, e: String):
		current_tier = t
		variant = v
		elemental_type = e
		
		# Map tier sizes and colors matching asteroid.gd
		match current_tier:
			5:
				draw_size = 64.0
				color = Color("#7f1d1d")
			4:
				draw_size = 48.0
				color = Color("#dc2626")
			3:
				draw_size = 36.0
				color = Color("#ea580c")
			2:
				draw_size = 24.0
				color = Color("#f97316")
			1:
				draw_size = 16.0
				color = Color("#eab308")
				
		custom_minimum_size = Vector2(80, 80)
		queue_redraw()

	func _draw():
		var center = Vector2(40, 40)
		var draw_color = color
		if elemental_type == "Ice":
			draw_color = Color("#bae6fd") # Ice pale blue
		elif elemental_type == "Lava":
			draw_color = Color("#f97316") # Molten orange
			
		# Draw solid square representing the asteroid centered
		var rect = Rect2(center.x - draw_size / 2, center.y - draw_size / 2, draw_size, draw_size)
		draw_rect(rect, draw_color)
		# Subtle dark inner border to give dimension
		draw_rect(rect, Color(0, 0, 0, 0.4), false, 2.0)
		
		# Frosted ice cracks or Lava molten veins
		if elemental_type == "Ice":
			draw_line(center + Vector2(-draw_size/3, -draw_size/3), center + Vector2(draw_size/3, draw_size/3), Color("#f0f9ff", 0.5), 1.0)
			draw_line(center + Vector2(draw_size/4, -draw_size/4), center + Vector2(-draw_size/4, draw_size/4), Color("#f0f9ff", 0.5), 1.0)
		elif elemental_type == "Lava":
			draw_line(center + Vector2(-draw_size/3, 0), center + Vector2(draw_size/3, 0), Color("#fef08a", 0.6), 1.5)
			draw_line(center + Vector2(0, -draw_size/3), center + Vector2(0, draw_size/3), Color("#fef08a", 0.6), 1.5)
		
		# Draw variant visual layers
		match variant:
			"Hard Crust":
				draw_rect(Rect2(center.x - draw_size / 4, center.y - draw_size / 4, draw_size / 2, draw_size / 2), Color(0.1, 0.1, 0.1, 0.6))
				draw_rect(Rect2(center.x - draw_size / 4, center.y - draw_size / 4, draw_size / 2, draw_size / 2), Color.BLACK, false, 1.0)
			"Magnetic Core":
				var aura_color = Color("#60a5fa")
				aura_color.a = 0.25
				draw_circle(center, draw_size * 0.8, aura_color)
				draw_arc(center, draw_size * 0.8, 0, 2*PI, 32, Color("#3b82f6", 0.4), 1.0)
			"Ring Belt":
				var ring_color = Color("#94a3b8")
				ring_color.a = 0.6
				draw_arc(center, draw_size * 0.9, 0, 2*PI, 16, ring_color, 1.5, true)
			"Blinding Tail":
				var tail_color = Color("#fbbf24")
				tail_color.a = 0.7
				draw_circle(center + Vector2(-draw_size/3, 0), draw_size/4, tail_color)

var current_profile: Dictionary = {}
var profiles: Dictionary = {
	"Pebble": {
		"title": "PEBBLE (TIER 1 THREAT)",
		"tier": 1, "variant": "None", "element": "None",
		"integrity": "1 Hit", "speed": "180 px/s (Swift)", "penalty": "1 Life",
		"desc": "Small, swift space debris fragments. Pebbles move quickly but have zero armor structures.",
		"advice": "Scouts are highly cost-efficient counters due to rapid direct shots."
	},
	"Boulder": {
		"title": "BOULDER (TIER 2 THREAT)",
		"tier": 2, "variant": "None", "element": "None",
		"integrity": "2 Hits (HP)", "speed": "130 px/s (Moderate)", "penalty": "4 Lives",
		"desc": "Moderate-sized metamorphic rock. Boulder Integrity requires 2 hits before splitting.",
		"advice": "Splits into 2 Pebbles. Build early coverage to clear cascading splits."
	},
	"Meteor": {
		"title": "METEOR (TIER 3 THREAT)",
		"tier": 3, "variant": "None", "element": "None",
		"integrity": "3 Hits (HP)", "speed": "90 px/s (Medium)", "penalty": "8 Lives",
		"desc": "Heavy incoming asteroid cores. Meteors split into 2 Boulders, cascading into 4 Pebbles.",
		"advice": "Drone Carrier drones deal 0 damage due to crust density. Deploy heavy ships."
	},
	"Giant": {
		"title": "GIANT (TIER 4 THREAT)",
		"tier": 4, "variant": "None", "element": "None",
		"integrity": "4 Hits (HP)", "speed": "60 px/s (Slow)", "penalty": "16 Lives",
		"desc": "Massive monolithic space rock chunk. Extremely high cumulative split hits required.",
		"advice": "Deploy Laser Frigates for pierce sweep, or Ion Cannons to shred high HP tiers."
	},
	"Planet Chunk": {
		"title": "PLANET CHUNK (TIER 5 THREAT)",
		"tier": 5, "variant": "None", "element": "None",
		"integrity": "5 Hits (HP)", "speed": "40 px/s (Very Slow)", "penalty": "32 Lives (Instant Death)",
		"desc": "Colossal remnant core. Leaking a single Planet Chunk triggers an immediate GAME OVER.",
		"advice": "Prioritize with Ion Cannons and freeze with Gravity Wells in looped pathways."
	},
	"Hard Crust": {
		"title": "HARD CRUST VARIANT",
		"tier": 3, "variant": "Hard Crust", "element": "None",
		"integrity": "+0 HP (Absorbs Weak)", "speed": "Base Tier Speed", "penalty": "Base Tier Penalty",
		"desc": "Armored space rock variant covered in high-density basalt plates.",
		"advice": "Absorbs ALL weak shots entirely (Scouts, Missile splash, Drones). Use Ion or Pierce shots."
	},
	"Magnetic Core": {
		"title": "MAGNETIC CORE VARIANT",
		"tier": 3, "variant": "Magnetic Core", "element": "None",
		"integrity": "Regenerates 0.5 HP/s", "speed": "Base Tier Speed", "penalty": "Base Tier Penalty",
		"desc": "Shielded variant creating localized electromagnetic fields that restore HP automatically.",
		"advice": "HP heals to max after 4.0s idle. Focus-fire or hit with Pulse Beam to pause regen for 2.0s."
	},
	"Ring Belt": {
		"title": "RING BELT VARIANT",
		"tier": 4, "variant": "Ring Belt", "element": "None",
		"integrity": "Splash Deflector", "speed": "Base Tier Speed", "penalty": "Base Tier Penalty",
		"desc": "Asteroids surrounded by a spinning orbital belt of sand and granular debris.",
		"advice": "Deflects all splash/AoE damage and drone strikes entirely. Use Scout direct focused fire."
	},
	"Blinding Tail": {
		"title": "BLINDING TAIL VARIANT",
		"tier": 3, "variant": "Blinding Tail", "element": "None",
		"integrity": "Targeting Swallower", "speed": "Base Tier Speed", "penalty": "Base Tier Penalty",
		"desc": "Comet-like streaks of ionization dust that occlude visual trackers within 3.0 tiles (192px).",
		"advice": "Blinds Scouts, Missile Cruisers, and Drones. Use Laser Frigates/Ions, or Scout Optical Upgrades."
	},
	"Ice Elemental": {
		"title": "❄️ ICE ELEMENTAL SUB-TYPE",
		"tier": 3, "variant": "None", "element": "Ice",
		"integrity": "Laser Vulnerable", "speed": "Base Tier Speed", "penalty": "Base Tier Penalty",
		"desc": "Rare cryogenic core sub-type interacting dynamically with laser thermal frequencies.",
		"advice": "Hot Laser melts it cleanly. Cold Laser shatters it, triggering a 2.0-tile shrapnel burst."
	},
	"Lava Elemental": {
		"title": "🌋 LAVA ELEMENTAL SUB-TYPE",
		"tier": 3, "variant": "None", "element": "Lava",
		"integrity": "Laser Vulnerable", "speed": "Base Tier Speed", "penalty": "Base Tier Penalty",
		"desc": "Rare volcanic molten sub-type interacting dynamically with laser thermal frequencies.",
		"advice": "Cold Laser solidifies it (0 damage conversion). Hot Laser triggers massive Overload explosion."
	}
};

var list_container: VBoxContainer
var preview_box: ThreatPreview
var profile_title: Label
var stats_grid: GridContainer
var desc_text: Label
var advice_text: Label

var stat_hp: Label
var stat_spd: Label
var stat_leak: Label

func _ready():
	# Full screen layout
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Transparent backing to visually fade Main Menu
	var bg = ColorRect.new()
	bg.size = Vector2(2048, 1152)
	bg.color = Color(0.02, 0.04, 0.08, 0.95)
	add_child(bg)
	
	# Middle panel container
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.12, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.5, 0.9, 0.8) # Glowing cyan border
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", style)
	
	panel.custom_minimum_size = Vector2(1360, 780)
	panel.position = Vector2(2048.0 / 2.0 - 1360.0 / 2.0, 1152.0 / 2.0 - 780.0 / 2.0)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 36)
	panel.add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 24)
	margin.add_child(main_vbox)
	
	# Header HBox
	var header = HBoxContainer.new()
	main_vbox.add_child(header)
	
	var db_title = Label.new()
	db_title.text = "THREAT DATABASE - COGNITIVE DEFENSE READOUT"
	db_title.add_theme_font_size_override("font_size", 28)
	db_title.add_theme_color_override("font_color", Color("#06b6d4"))
	db_title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(db_title)
	
	var back_btn = Button.new()
	back_btn.text = "RETURN TO BRIDGE"
	back_btn.custom_minimum_size = Vector2(200, 48)
	back_btn.add_theme_font_size_override("font_size", 16)
	
	var style_btn = StyleBoxFlat.new()
	style_btn.bg_color = Color(0.35, 0.12, 0.12, 0.8)
	style_btn.corner_radius_top_left = 6
	style_btn.corner_radius_top_right = 6
	style_btn.corner_radius_bottom_left = 6
	style_btn.corner_radius_bottom_right = 6
	back_btn.add_theme_stylebox_override("normal", style_btn)
	back_btn.add_theme_stylebox_override("hover", style_btn)
	back_btn.pressed.connect(func(): queue_free())
	header.add_child(back_btn)
	
	main_vbox.add_child(HSeparator.new())
	
	# Content Split Area (Sidebar + Detailed Card)
	var content_area = HBoxContainer.new()
	content_area.size_flags_vertical = SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 36)
	main_vbox.add_child(content_area)
	
	# Left Scrolling Sidebar Container
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 0)
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	content_area.add_child(scroll)
	
	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 10)
	list_container.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(list_container)
	
	# Right Detailed Profile Card snaps
	var detail_card = PanelContainer.new()
	var style_card = StyleBoxFlat.new()
	style_card.bg_color = Color(0.06, 0.09, 0.18, 0.85)
	style_card.border_width_left = 1
	style_card.border_width_top = 1
	style_card.border_width_right = 1
	style_card.border_width_bottom = 1
	style_card.border_color = Color(0.2, 0.3, 0.5, 0.5)
	style_card.corner_radius_top_left = 10
	style_card.corner_radius_top_right = 10
	style_card.corner_radius_bottom_left = 10
	style_card.corner_radius_bottom_right = 10
	detail_card.add_theme_stylebox_override("panel", style_card)
	detail_card.size_flags_horizontal = SIZE_EXPAND_FILL
	detail_card.size_flags_vertical = SIZE_EXPAND_FILL
	content_area.add_child(detail_card)
	
	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 30)
	card_margin.add_theme_constant_override("margin_top", 30)
	card_margin.add_theme_constant_override("margin_right", 30)
	card_margin.add_theme_constant_override("margin_bottom", 30)
	detail_card.add_child(card_margin)
	
	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 24)
	card_margin.add_child(card_vbox)
	
	# Header Profile
	profile_title = Label.new()
	profile_title.text = "THREAT PROFILE"
	profile_title.add_theme_font_size_override("font_size", 24)
	profile_title.add_theme_color_override("font_color", Color("#fbbf24")) # Amber/Gold
	card_vbox.add_child(profile_title)
	
	# Middle Section: live drawing preview + Core Stats side-by-side
	var mid_box = HBoxContainer.new()
	mid_box.add_theme_constant_override("separation", 40)
	card_vbox.add_child(mid_box)
	
	# Programmatic Preview Box wrapper
	var preview_container = CenterContainer.new()
	preview_container.custom_minimum_size = Vector2(160, 160)
	var preview_bg = PanelContainer.new()
	var preview_style = StyleBoxFlat.new()
	preview_style.bg_color = Color("#090d16")
	preview_style.border_width_left = 2
	preview_style.border_width_top = 2
	preview_style.border_width_right = 2
	preview_style.border_width_bottom = 2
	preview_style.border_color = Color(0.2, 0.4, 0.7, 0.4)
	preview_style.corner_radius_top_left = 8
	preview_style.corner_radius_top_right = 8
	preview_style.corner_radius_bottom_left = 8
	preview_style.corner_radius_bottom_right = 8
	preview_bg.add_theme_stylebox_override("panel", preview_style)
	preview_bg.custom_minimum_size = Vector2(160, 160)
	preview_container.add_child(preview_bg)
	
	preview_box = ThreatPreview.new()
	preview_bg.add_child(preview_box)
	mid_box.add_child(preview_container)
	
	# Stats Grid Container
	stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 24)
	stats_grid.add_theme_constant_override("v_separation", 12)
	stats_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	mid_box.add_child(stats_grid)
	
	# Add static stats labels
	var lbl_hp = Label.new()
	lbl_hp.text = "Structural Integrity:"
	lbl_hp.add_theme_color_override("font_color", Color("#64748b"))
	stats_grid.add_child(lbl_hp)
	stat_hp = Label.new()
	stat_hp.text = "--"
	stats_grid.add_child(stat_hp)
	
	var lbl_spd = Label.new()
	lbl_spd.text = "Velocity Scale:"
	lbl_spd.add_theme_color_override("font_color", Color("#64748b"))
	stats_grid.add_child(lbl_spd)
	stat_spd = Label.new()
	stat_spd.text = "--"
	stats_grid.add_child(stat_spd)
	
	var lbl_leak = Label.new()
	lbl_leak.text = "Leak Impact (Station Lives):"
	lbl_leak.add_theme_color_override("font_color", Color("#64748b"))
	stats_grid.add_child(lbl_leak)
	stat_leak = Label.new()
	stat_leak.text = "--"
	stats_grid.add_child(stat_leak)
	
	card_vbox.add_child(HSeparator.new())
	
	# Description fields
	var desc_header = Label.new()
	desc_header.text = "TACTICAL DESCRIPTION:"
	desc_header.add_theme_color_override("font_color", Color("#64748b"))
	card_vbox.add_child(desc_header)
	
	desc_text = Label.new()
	desc_text.text = "Select a threat profile from the list to pull scan readouts."
	desc_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	card_vbox.add_child(desc_text)
	
	var advice_header = Label.new()
	advice_header.text = "STRATEGIC COUNTER RECOMMENDATION:"
	advice_header.add_theme_color_override("font_color", Color("#64748b"))
	card_vbox.add_child(advice_header)
	
	advice_text = Label.new()
	advice_text.text = "Select a threat profile from the list to pull counter recommendations."
	advice_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	advice_text.add_theme_color_override("font_color", Color("#a855f7")) # Tech purple highlight
	card_vbox.add_child(advice_text)
	
	# Instantiate list keys
	var keys = ["Pebble", "Boulder", "Meteor", "Giant", "Planet Chunk", "Hard Crust", "Magnetic Core", "Ring Belt", "Blinding Tail", "Ice Elemental", "Lava Elemental"]
	for k in keys:
		var btn = Button.new()
		btn.text = k.to_upper()
		btn.custom_minimum_size.y = 48
		btn.add_theme_font_size_override("font_size", 16)
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.08, 0.12, 0.22, 0.8)
		style_normal.border_width_left = 1
		style_normal.border_width_top = 1
		style_normal.border_width_right = 1
		style_normal.border_width_bottom = 1
		style_normal.border_color = Color(0.2, 0.4, 0.7, 0.4)
		style_normal.corner_radius_top_left = 6
		style_normal.corner_radius_top_right = 6
		style_normal.corner_radius_bottom_left = 6
		style_normal.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_normal)
		btn.add_theme_stylebox_override("pressed", style_normal)
		btn.pressed.connect(func(): display_profile(k))
		list_container.add_child(btn)
		
	# Select default first profile on load
	display_profile("Pebble")

func display_profile(key: String):
	var data = profiles.get(key, {})
	if data.is_empty():
		return
		
	current_profile = data
	profile_title.text = data["title"]
	stat_hp.text = data["integrity"]
	stat_spd.text = data["speed"]
	stat_leak.text = data["penalty"]
	desc_text.text = data["desc"]
	advice_text.text = data["advice"]
	
	# Update programmatic thumbnail renderer!
	preview_box.setup_preview(data["tier"] as int, data["variant"] as String, data["element"] as String)
