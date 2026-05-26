extends Node

var playthrough_start_time: float = 0.0
var round_metrics: Array = [] # List of dictionaries

# Tower statistics: { type: { "placed": int, "sold": int, "damage": int, "kills": int } }
var tower_stats: Dictionary = {}

# Elemental reactions: { "Shatter": int, "Melt": int, "Solidify": int, "Overload": int }
var reaction_stats: Dictionary = {
	"Shatter": 0,
	"Melt": 0,
	"Solidify": 0,
	"Overload": 0
}

# New Balance & Telemetry tracking variables
var upgrades_purchased: Dictionary = {
	"HotLaser": 0,
	"ColdLaser": 0,
	"OpticalTargeting": 0
}
var repositioning_events: int = 0
var repositioning_fees_spent: int = 0

var leaks_breakdown: Dictionary = {
	"Pebble": 0,
	"Boulder": 0,
	"Meteor": 0,
	"Giant": 0,
	"Planet Chunk": 0,
	"Hard Crust": 0,
	"Magnetic Core": 0,
	"Ring Belt": 0,
	"Blinding Tail": 0
}

var damage_absorbed: int = 0
var damage_deflected: int = 0

var income_sources: Dictionary = {
	"Kill": 0,
	"Split": 0,
	"Bonus": 0,
	"Refund": 0
}

# Current round logging helper
var current_round_start_time: float = 0.0
var current_round_start_minerals: int = 0
var current_round_placements_cost: int = 0

var starting_capital: int = 200
var starting_lives: int = 20
var operations_mode: String = "Normal"

var ship_types: Array = ["Scout", "Laser Frigate", "Missile Cruiser", "Pulse Beam", "Ion Cannon", "Drone Carrier", "Gravity Well"]

func _ready():
	reset_metrics()

func reset_metrics():
	playthrough_start_time = Time.get_unix_time_from_system()
	round_metrics.clear()
	tower_stats.clear()
	for type in ship_types:
		tower_stats[type] = {
			"placed": 0,
			"sold": 0,
			"damage": 0,
			"kills": 0
		}
	reaction_stats = {
		"Shatter": 0,
		"Melt": 0,
		"Solidify": 0,
		"Overload": 0
	}
	upgrades_purchased = {
		"HotLaser": 0,
		"ColdLaser": 0,
		"OpticalTargeting": 0
	}
	repositioning_events = 0
	repositioning_fees_spent = 0
	leaks_breakdown = {
		"Pebble": 0,
		"Boulder": 0,
		"Meteor": 0,
		"Giant": 0,
		"Planet Chunk": 0,
		"Hard Crust": 0,
		"Magnetic Core": 0,
		"Ring Belt": 0,
		"Blinding Tail": 0
	}
	damage_absorbed = 0
	damage_deflected = 0
	income_sources = {
		"Kill": 0,
		"Split": 0,
		"Bonus": 0,
		"Refund": 0
	}
	current_round_start_time = 0.0
	current_round_start_minerals = 0
	current_round_placements_cost = 0

func record_upgrade(upgrade_type: String):
	if upgrades_purchased.has(upgrade_type):
		upgrades_purchased[upgrade_type] += 1

func record_reposition(fee: int):
	repositioning_events += 1
	repositioning_fees_spent += fee

func record_leak_threat(tier_name: String, variant_name: String):
	if leaks_breakdown.has(tier_name):
		leaks_breakdown[tier_name] += 1
	if variant_name != "None" and leaks_breakdown.has(variant_name):
		leaks_breakdown[variant_name] += 1

func record_mitigation(mitigation_type: String, amount: int):
	if mitigation_type == "absorbed":
		damage_absorbed += amount
	elif mitigation_type == "deflected":
		damage_deflected += amount

func record_income(source: String, amount: int):
	if income_sources.has(source):
		income_sources[source] += amount

func start_round(round_num: int):
	current_round_start_time = Time.get_unix_time_from_system()
	current_round_start_minerals = EconomyManager.minerals
	current_round_placements_cost = 0

func end_round(round_num: int, leaks: int):
	var elapsed = Time.get_unix_time_from_system() - current_round_start_time
	var ending_minerals = EconomyManager.minerals
	
	var round_data = {
		"round_number": round_num,
		"clear_time_seconds": elapsed,
		"starting_minerals": current_round_start_minerals,
		"ending_minerals": ending_minerals,
		"spent_this_round": current_round_placements_cost,
		"lives_remaining": GameManager.lives,
		"leaks_this_round": leaks
	}
	round_metrics.append(round_data)

func record_tower_placement(type: String, cost: int):
	if tower_stats.has(type):
		tower_stats[type]["placed"] += 1
	current_round_placements_cost += cost

func record_tower_sell(type: String):
	if tower_stats.has(type):
		tower_stats[type]["sold"] += 1

func record_damage(type: String, amount: int):
	if tower_stats.has(type):
		tower_stats[type]["damage"] += amount

func record_kill(type: String):
	if tower_stats.has(type):
		tower_stats[type]["kills"] += 1

func record_reaction(reaction_type: String):
	if reaction_stats.has(reaction_type):
		reaction_stats[reaction_type] += 1

func save_playthrough_report():
	# Ensure the directory exists
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists("res://metrics"):
		dir.make_dir("res://metrics")
		
	# Timestamp formatting
	var datetime = Time.get_datetime_dict_from_system()
	var timestamp = "%04d%02d%02d_%02d%02d%02d" % [
		datetime["year"], datetime["month"], datetime["day"],
		datetime["hour"], datetime["minute"], datetime["second"]
	]
	
	# 1. Save JSON Report
	var json_data = {
		"timestamp": timestamp,
		"developer_mode": GameManager.dev_mode,
		"operations_mode": operations_mode,
		"total_play_time_seconds": Time.get_unix_time_from_system() - playthrough_start_time,
		"victory": GameManager.current_phase == GameManager.GamePhase.GAME_WON,
		"starting_capital": starting_capital,
		"starting_lives": starting_lives,
		"rounds_summary": round_metrics,
		"tower_efficiencies": tower_stats,
		"elemental_reactions": reaction_stats,
		"upgrades_purchased": upgrades_purchased,
		"repositioning_events": repositioning_events,
		"repositioning_fees_spent": repositioning_fees_spent,
		"leaks_breakdown": leaks_breakdown,
		"damage_absorbed": damage_absorbed,
		"damage_deflected": damage_deflected,
		"income_sources": income_sources
	}
	
	var json_path = "res://metrics/playthrough_report_" + timestamp + ".json"
	var file = FileAccess.open(json_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(json_data, "\t"))
		file.close()
		
	# 2. Save Markdown Report
	var md_path = "res://metrics/playthrough_report_" + timestamp + ".md"
	var md_file = FileAccess.open(md_path, FileAccess.WRITE)
	if md_file:
		var md_content = generate_markdown_report(json_data)
		md_file.store_string(md_content)
		md_file.close()

func generate_markdown_report(data: Dictionary) -> String:
	var result = "# 📊 Playthrough Telemetry & Balance Report\n\n"
	result += "Generated: `%s`  \n" % data["timestamp"]
	
	var mode_display = "NORMAL MODE 🎮"
	if data.get("operations_mode") == "Hard":
		mode_display = "HARD MODE 💀"
	elif data.get("operations_mode") == "Developer":
		mode_display = "DEVELOPER MODE 🛠️"
		
	result += "Mode: **%s**  \n" % mode_display
	result += "Outcome: **%s**  \n" % ("VICTORY (All 10 Rounds Cleared) ✅" if data["victory"] else "DEFEAT (Space Station Lost) ❌")
	result += "Total Playtime: `%d seconds`  \n\n" % data["total_play_time_seconds"]
	
	result += "## 🏁 Round-by-Round Breakdown\n\n"
	result += "| Round | Clear Time (s) | Start Minerals | End Minerals | Spent (💎) | Lives | Leaks |\n"
	result += "|---|---|---|---|---|---|---|\n"
	for r in data["rounds_summary"]:
		result += "| %d | %.1f | %d | %d | %d | %d | %d |\n" % [
			r["round_number"], r["clear_time_seconds"],
			r["starting_minerals"], r["ending_minerals"],
			r["spent_this_round"], r["lives_remaining"], r["leaks_this_round"]
		]
		
	result += "\n## 🚀 Starfleet Tower Combat Efficiencies\n\n"
	result += "| Tower Class | Placed | Sold | Total Damage Dealt | Lethal Kills |\n"
	result += "|---|---|---|---|---|\n"
	for t in ship_types:
		var stat = data["tower_efficiencies"][t]
		result += "| %s | %d | %d | %d | %d |\n" % [
			t, stat["placed"], stat["sold"], stat["damage"], stat["kills"]
		]
		
	result += "\n## 🌀 Elemental Reactions Triggered\n\n"
	result += "| Reaction Type | Occurrences |\n"
	result += "|---|---|\n"
	for reaction in data["elemental_reactions"].keys():
		result += "| %s | %d |\n" % [reaction, data["elemental_reactions"][reaction]]
		
	# Tactical Upgrades & Repositioning
	result += "\n## 🔧 Upgrades & Repositioning Telemetry\n\n"
	result += "- **Hot Lasers Purchased**: %d\n" % data.get("upgrades_purchased", {}).get("HotLaser", 0)
	result += "- **Cold Lasers Purchased**: %d\n" % data.get("upgrades_purchased", {}).get("ColdLaser", 0)
	result += "- **Optical Targetings Purchased**: %d\n" % data.get("upgrades_purchased", {}).get("OpticalTargeting", 0)
	result += "- **Repositioning Events**: %d\n" % data.get("repositioning_events", 0)
	result += "- **Total Repositioning Fees Spent**: %d 💎\n" % data.get("repositioning_fees_spent", 0)
	
	# Damage Shielding Mitigations
	result += "\n## 🛡️ Variant Shielding Mitigations\n\n"
	result += "- **Weak Damage Absorbed (Hard Crust)**: %d HP\n" % data.get("damage_absorbed", 0)
	result += "- **Splash/Drone Damage Deflected (Ring Belt)**: %d HP\n" % data.get("damage_deflected", 0)
	
	# Income Sources
	result += "\n## 💎 Economic Income Source Breakdown\n\n"
	result += "| Income Source | Total Earnings |\n"
	result += "|---|---|\n"
	var inc = data.get("income_sources", {})
	result += "| Pebble Death / Complete Kills | %d 💎 |\n" % inc.get("Kill", 0)
	result += "| Asteroid Splits | %d 💎 |\n" % inc.get("Split", 0)
	result += "| No-Leak Clean Clear Bonus | %d 💎 |\n" % inc.get("Bonus", 0)
	result += "| Placed Ship Sell Refunds | %d 💎 |\n" % inc.get("Refund", 0)
	
	# Leaked threat breakdown
	result += "\n## ☄️ Leaked Threats Breakdown\n\n"
	result += "| Threat Tier / Variant | Leaked Count |\n"
	result += "|---|---|\n"
	var l_brk = data.get("leaks_breakdown", {})
	for k in ["Pebble", "Boulder", "Meteor", "Giant", "Planet Chunk", "Hard Crust", "Magnetic Core", "Ring Belt", "Blinding Tail"]:
		var val = l_brk.get(k, 0)
		if val > 0:
			result += "| %s | %d |\n" % [k, val]
			
	result += "\n---\n*Space Defenders Telemetry Engine - Data Logged for Balance Optimization.* 🌌"
	return result
