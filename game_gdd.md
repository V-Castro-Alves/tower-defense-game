# SPACE DEFENDERS
## Game Design Document
**Version 0.3 | Prototype Phase**

---

## Table of Contents
1. [Game Overview](#1-game-overview)
2. [Core Mechanics](#2-core-mechanics)
3. [Spaceships (Towers)](#3-spaceships-towers)
4. [Map](#4-map)
5. [Wave System](#5-wave-system)
6. [UI & Input](#6-ui--input)
7. [Technical Architecture](#7-technical-architecture)
8. [TDD Test Plan](#8-tdd-test-plan)
9. [Development Roadmap](#9-development-roadmap)
10. [Open Questions & TBD Items](#10-open-questions--tbd-items)

---

## 1. Game Overview

Space Defenders is a tower defense game where the player deploys spaceships to destroy incoming asteroid waves before they reach the space station. Asteroids do not have health bars — their size is their health. Shooting an asteroid breaks it into smaller pieces, creating a chain reaction of splitting debris.

**Core loop:**
- Player places spaceships before and during waves using the ship shop in the HUD
- Asteroids travel a fixed Z-shaped path with a loop toward the space station
- Spaceships automatically shoot asteroids within their circular range
- Destroyed Pebbles drop Minerals, which fund new ships and upgrades
- Player manually starts each new wave when ready
- Survive all 10 waves without losing 20 lives

---

## 2. Core Mechanics

### 2.1 Asteroid Splitting System

Asteroids have no HP. Each hit reduces the asteroid one tier. When a Pebble (tier 1) is hit it is destroyed. All other tiers split into 2 asteroids of the tier below.

| Tier | Name | Splits Into | Speed (px/s) | Lives Lost if Leaked |
|------|------|-------------|--------------|----------------------|
| 5 | Planet Chunk | 2x Giant | 40 | 32 |
| 4 | Giant | 2x Meteor | 60 | 16 |
| 3 | Meteor | 2x Boulder | 90 | 8 |
| 2 | Boulder | 2x Pebble | 130 | 4 |
| 1 | Pebble | Destroyed | 180 | 1 |

> ⚠️ **Important:** A Planet Chunk leaking through costs 32 lives — an instant game over since the player only has 20 lives. Large asteroids must be prioritized aggressively.

---

### 2.2 Lives System

- Player starts with **20 lives**
- Each Pebble that reaches the station = 1 life lost
- Larger asteroids cost their full pebble-equivalent lives on leak
- Game over when lives reach 0

---

### 2.3 Economy — Minerals

Minerals are the only in-game currency.

- Earned mid-wave: **1 Pebble destroyed = 1 Mineral**
- Larger asteroids yield more minerals when fully cleared (chained splits)
- Player starts with **50 Minerals**
- Minerals are spent to place ships, upgrade ships, reposition ships, or recouped by selling

| Asteroid | Total Minerals if Fully Cleared |
|----------|---------------------------------|
| Pebble | 1 |
| Boulder | 4 (2 pebbles × 2) |
| Meteor | 8 (4 pebbles × 2) |
| Giant | 16 (8 pebbles × 2) |
| Planet Chunk | 32 (16 pebbles × 2) |

**Total minerals available across all 10 waves:** 508
**Expected player spend:** ~300–350 minerals (60–70% of total)

**No-leak wave bonus:** At the end of a wave with zero leaks, the player earns a bonus of `wave_number × 5` minerals (e.g. Wave 4 no-leak = +20 minerals).

---

### 2.4 Wave Control

- The player manually starts each wave by pressing the **"Launch Wave"** button
- No time limit between waves — players place/upgrade ships at their own pace
- Once a wave starts, asteroids spawn at intervals specific to that wave
- The Launch Wave button is disabled until the current wave is fully cleared

---

## 3. Spaceships (Towers)

### 3.1 Placement Rules

- Ships are placed **freely** on any non-path tile
- Placement flow: **click ship in shop → range preview follows cursor → click tile to place** OR **drag from shop to tile** (range preview visible in both cases)
- Ships cannot overlap each other or be placed on the path
- Range shown as a circle on hover/select at all times

---

### 3.2 Repositioning

- A placed ship can be moved to a new valid tile at any time
- **Cost: 15% of the ship's base cost** (rounded up, upgrades not included)
- Repositioning is available during waves and between waves

| Ship | Base Cost | Reposition Fee |
|------|-----------|----------------|
| Scout | 15 | 3 minerals |
| Laser Frigate | 35 | 6 minerals |
| Missile Cruiser | 50 | 8 minerals |
| Ion Cannon | 60 | 9 minerals |
| Drone Carrier | 75 | 12 minerals |
| Nuke Destroyer | 100 | 15 minerals |

---

### 3.3 Selling

- Click a placed ship → panel opens → click Sell
- Returns **70% of total value** (base cost + all upgrades purchased), rounded down
- Available during waves and between waves

---

### 3.4 Targeting Modes

Each ship can be set to one of four targeting priorities via the ship panel.

| Mode | Behavior | Best For |
|------|----------|----------|
| **First** | Targets the asteroid furthest along the path | Preventing leaks |
| **Last** | Targets the asteroid least far along the path | Finishing stragglers |
| **Strongest** | Targets the highest tier asteroid in range | Killing big threats first |
| **Closest** | Targets the asteroid nearest to the ship | Maximizing DPS efficiency |

---

### 3.5 Ship Types

| Ship | Cost | Range (tiles) | Damage | Fire Rate | Special |
|------|------|---------------|--------|-----------|---------|
| Scout | 15 | 3 | 1 tier/shot | 1.5 shots/s | Fast, cheap, default targeting: First |
| Laser Frigate | 35 | 5 | 1 tier, pierce | 1.0 shots/s | Pierces all asteroids in a straight line |
| Missile Cruiser | 50 | 4 | 1 tier, splash | 0.6 shots/s | AoE blast radius of 1.5 tiles |
| Ion Cannon | 60 | 5 | 2 tiers/shot | 0.4 shots/s | Punches through large asteroids |
| Drone Carrier | 75 | 3 | 1 tier, multi | Fast (drones) | Spawns 3 drones that orbit and auto-target |
| Nuke Destroyer | 100 | 7 | Clears 1 full tier on screen | 0.1 shots/s | Massive AoE, very long reload |

---

### 3.6 Upgrades

- Upgrades purchased with Minerals by clicking a placed ship → upgrade panel
- Upgrade costs stack into total ship value for sell calculation
- Full upgrade trees: **TBD Phase 4**

---

## 4. Map

### 4.1 Prototype Map — Z-Path with Loop

**Grid:** 32 × 18 tiles at **64×64 px** per tile = 2048 × 1152 px total canvas

The asteroid path follows a Z shape with a loop in the middle, from top-left to bottom-right.

```
 ┌────────────────────────────────────┐
 │ ★ ══════════════════════════╗      │
 │                             ║      │
 │                       ╔═════╝      │
 │                       ║            │
 │                  ┌────╜            │
 │                  │   loop          │
 │                  └────╖            │
 │                       ║            │
 │                       ╚════════ ■  │
 └────────────────────────────────────┘
  ★ = Asteroid entry (top-left)    ■ = Space station (bottom-right)
```

**Path waypoints (tile coordinates):** TBD Phase 2 — exact grid coordinates to be defined when building the map scene.

> 💡 **Choke point:** Ships placed near the loop hit asteroids twice — once entering, once exiting. High-value placement zone.

**Tile types:**
- `PATH` — asteroid travels here, no ship placement allowed
- `BUILDABLE` — ship can be placed here
- `BLOCKED` — decorative / out of bounds, no placement

---

## 5. Wave System

### 5.1 Wave Table

Spawn order within each wave: **small clusters first, big finisher last.**

| Wave | Composition | Spawn Order | Spawn Interval | Minerals Available | No-Leak Bonus |
|------|-------------|-------------|----------------|--------------------|---------------|
| 1 | 10 Pebbles | 10 Pebbles | 1.5s | 10 | +5 |
| 2 | 8 Pebbles + 2 Boulders | 4P, 4P, 2B | 1.3s | 16 | +10 |
| 3 | 6 Pebbles + 4 Boulders | 3P, 3P, 2B, 2B | 1.2s | 22 | +15 |
| 4 | 10 Boulders | 3B, 3B, 4B | 1.0s | 40 | +20 |
| 5 | 6 Boulders + 2 Meteors | 3B, 3B, 2M | 1.0s | 40 | +25 |
| 6 | 8 Boulders + 3 Meteors | 4B, 4B, 3M | 0.9s | 56 | +30 |
| 7 | 5 Boulders + 5 Meteors | 3B, 2B, 3M, 2M | 0.8s | 60 | +35 |
| 8 | 8 Meteors + 1 Giant | 4M, 4M, 1G | 0.8s | 80 | +40 |
| 9 | 5 Meteors + 3 Giants | 3M, 2M, 2G, 1G | 0.7s | 88 | +45 |
| 10 | 1 Planet Chunk + 4 Giants | 2G, 2G, 1PC | 0.6s | 96 | +50 |

**P** = Pebble, **B** = Boulder, **M** = Meteor, **G** = Giant, **PC** = Planet Chunk

**Total base minerals:** 508 | **Max no-leak bonus (all waves):** +275

---

### 5.2 Economy Pacing

| Waves | Economy State | Recommended Purchases |
|-------|--------------|----------------------|
| 1–3 | Tight — rely on starting 50 minerals | 2–3 Scouts |
| 4–6 | Opening up — 40–56 minerals/wave | Laser Frigate, Missile Cruiser |
| 7–10 | Strong — 60–96 minerals/wave | Ion Cannon, Drone Carrier, Nuke Destroyer |

---

## 6. UI & Input

### 6.1 HUD Layout

Always visible during gameplay:

| Element | Position | Description |
|---------|----------|-------------|
| ❤️ Lives counter | Top-left | Current / max lives (e.g. 18/20) |
| 💎 Mineral counter | Top-center | Current mineral balance |
| 🌊 Wave counter | Top-right | Current wave / total (e.g. Wave 3/10) |
| ⚡ Speed toggle | Top-right (below wave) | Button cycling 1x → 2x → 1x |
| 🚀 Ship shop | Bottom bar | All 6 ships with cost, click or drag to place |
| 🟢 Launch Wave button | Bottom-right | Disabled during active wave |

---

### 6.2 Ship Placement Flow

1. Player clicks a ship in the bottom shop bar OR starts dragging it
2. A **ghost preview** of the ship follows the cursor with its **range circle** visible
3. Valid tiles highlight green, invalid tiles (path, occupied) highlight red
4. Player clicks a valid tile → ship is placed, minerals deducted
5. Player presses **Escape** or right-clicks to cancel placement

---

### 6.3 Ship Management Panel

Triggered by clicking a placed ship. Panel shows:

- Ship name and icon
- Current targeting mode (dropdown to change: First / Last / Strongest / Closest)
- Upgrade button(s) with cost (TBD Phase 4)
- **Reposition** button — enters reposition mode, player clicks new tile, fee deducted
- **Sell** button — shows refund amount (70% of total value), confirms on click

---

### 6.4 Game Speed

- Default: **1x**
- Toggle button in HUD cycles between **1x and 2x**
- Affects asteroid movement speed and ship fire rate equally
- Available at all times including during waves

---

## 7. Technical Architecture

### 7.1 Engine & Language

- **Engine:** Godot 4
- **Language:** GDScript
- **Testing framework:** GUT (Godot Unit Test)
- **Resolution:** 2048 × 1152 (16:9), scalable

---

### 7.2 Project File Structure

```
space_defenders/
├── scenes/
│   ├── game.tscn               # Root game scene
│   ├── map/
│   │   └── map.tscn            # Tilemap + path
│   ├── entities/
│   │   ├── asteroids/
│   │   │   ├── asteroid.tscn   # Base asteroid scene
│   │   │   └── asteroid.gd
│   │   └── ships/
│   │       ├── ship.tscn       # Base ship scene
│   │       ├── scout.tscn
│   │       ├── laser_frigate.tscn
│   │       ├── missile_cruiser.tscn
│   │       ├── ion_cannon.tscn
│   │       ├── drone_carrier.tscn
│   │       └── nuke_destroyer.tscn
│   └── ui/
│       ├── hud.tscn
│       ├── ship_panel.tscn     # Upgrade/sell/reposition panel
│       └── shop_bar.tscn
├── scripts/
│   ├── managers/
│   │   ├── game_manager.gd     # Autoload — game state
│   │   ├── wave_manager.gd     # Autoload — wave spawning
│   │   └── economy_manager.gd  # Autoload — minerals/lives
│   ├── entities/
│   │   ├── asteroid_base.gd
│   │   └── ship_base.gd
│   └── ui/
│       ├── hud.gd
│       └── ship_panel.gd
├── resources/
│   ├── ship_data.tres          # ShipData resource definitions
│   └── wave_data.tres          # WaveData resource definitions
├── assets/
│   ├── sprites/
│   └── sounds/
└── tests/
    ├── unit/
    │   ├── test_asteroid_splitting.gd
    │   ├── test_economy.gd
    │   ├── test_targeting.gd
    │   └── test_wave_manager.gd
    └── integration/
        ├── test_wave_run.gd
        └── test_full_game.gd
```

---

### 7.3 Autoloads (Singletons)

| Singleton | Responsibility |
|-----------|---------------|
| `GameManager` | Global game state (phase, lives, game over, win) |
| `WaveManager` | Wave progression, asteroid spawning, spawn intervals |
| `EconomyManager` | Mineral balance, earn/spend/sell transactions |

---

### 7.4 Signal Map

| Signal | Emitted By | Listened By | Payload |
|--------|-----------|-------------|---------|
| `asteroid_leaked(tier)` | Asteroid | GameManager, EconomyManager | tier: int |
| `asteroid_destroyed(tier, position)` | Asteroid | EconomyManager | tier: int, pos: Vector2 |
| `mineral_earned(amount)` | EconomyManager | HUD | amount: int |
| `mineral_spent(amount)` | EconomyManager | HUD | amount: int |
| `life_lost(amount)` | GameManager | HUD | amount: int |
| `wave_started(wave_number)` | WaveManager | HUD, GameManager | wave_number: int |
| `wave_completed(wave_number, no_leak)` | WaveManager | EconomyManager, HUD | wave_number: int, no_leak: bool |
| `game_over` | GameManager | UI | — |
| `game_won` | GameManager | UI | — |
| `ship_placed(ship_type, position)` | Ship | EconomyManager | type: String, pos: Vector2 |
| `ship_sold(refund)` | Ship | EconomyManager | refund: int |
| `ship_repositioned(cost)` | Ship | EconomyManager | cost: int |

---

### 7.5 Core Data Resources

**ShipData (Resource)**
```gdscript
@export var id: String
@export var display_name: String
@export var base_cost: int
@export var range_tiles: float
@export var damage_tiers: int
@export var fire_rate: float        # shots per second
@export var is_piercing: bool
@export var is_splash: bool
@export var splash_radius: float
@export var default_targeting: String
@export var scene_path: String
```

**AsteroidData (Resource)**
```gdscript
@export var tier: int
@export var display_name: String
@export var speed: float            # pixels per second
@export var lives_on_leak: int      # = 2^(tier-1)
@export var minerals_on_destroy: int  # always 1 (only pebbles give minerals)
```

**WaveData (Resource)**
```gdscript
@export var wave_number: int
@export var spawn_groups: Array     # [{type, count}, ...] in spawn order
@export var spawn_interval: float   # seconds between spawns
@export var no_leak_bonus: int      # wave_number * 5
```

---

## 8. TDD Test Plan

### 8.1 Unit Tests

#### `test_asteroid_splitting.gd`
- [ ] Hitting a Pebble destroys it and emits `asteroid_destroyed`
- [ ] Hitting a Boulder spawns exactly 2 Pebbles at the same position
- [ ] Hitting a Meteor spawns exactly 2 Boulders
- [ ] Hitting a Giant spawns exactly 2 Meteors
- [ ] Hitting a Planet Chunk spawns exactly 2 Giants
- [ ] Split asteroids inherit the correct speed for their tier
- [ ] Split asteroids continue along the path from the parent's position

#### `test_economy.gd`
- [ ] Player starts with 50 minerals
- [ ] Destroying a Pebble adds exactly 1 mineral
- [ ] Destroying a Boulder fully adds exactly 4 minerals total
- [ ] Placing a Scout deducts 15 minerals
- [ ] Cannot place a ship if minerals are insufficient
- [ ] Selling a Scout with no upgrades returns 10 minerals (70% of 15, rounded down)
- [ ] Selling a Scout with 20 minerals in upgrades returns 24 minerals (70% of 35)
- [ ] Repositioning a Scout costs 3 minerals (ceil(15 * 0.15))
- [ ] No-leak bonus on wave 4 adds exactly 20 minerals
- [ ] No-leak bonus on wave 10 adds exactly 50 minerals

#### `test_targeting.gd`
- [ ] "First" mode targets asteroid with highest path_progress value
- [ ] "Last" mode targets asteroid with lowest path_progress value
- [ ] "Strongest" mode targets asteroid with highest tier in range
- [ ] "Closest" mode targets asteroid nearest to ship position
- [ ] Targeting ignores asteroids outside ship range
- [ ] Targeting updates correctly when target leaves range
- [ ] Ship fires at no target when range is empty

#### `test_wave_manager.gd`
- [ ] Wave 1 spawns exactly 10 Pebbles
- [ ] Wave 2 spawns 8 Pebbles then 2 Boulders (small first, big last)
- [ ] Wave 10 spawns Giants before Planet Chunk
- [ ] Spawn interval between asteroids matches wave data
- [ ] `wave_completed` is emitted only when all asteroids are gone
- [ ] `wave_completed` payload includes correct `no_leak` boolean
- [ ] Launch Wave button re-enables after wave is cleared

### 8.2 Integration Tests

#### `test_wave_run.gd`
- [ ] Full Wave 1 run: 10 Pebbles destroyed → 10 minerals earned → wave_completed fires
- [ ] Full Wave 1 run with 1 leak: lives reduced by 1, wave still completes
- [ ] Full Wave 4 run: 10 Boulders → 40 minerals if all cleared
- [ ] Planet Chunk leak on wave 10 triggers game_over (32 lives lost > 20)

#### `test_full_game.gd`
- [ ] Completing all 10 waves with lives > 0 triggers `game_won`
- [ ] Lives reaching 0 mid-wave triggers `game_over`
- [ ] All 10 waves completed with no leaks = 508 + 275 = 783 total minerals earned

---

## 9. Development Roadmap

| Phase | Focus | Status |
|-------|-------|--------|
| Phase 1 | Game Design Document | ✅ In Progress |
| Phase 2 | Prototype — Godot project scaffold, map scene, one asteroid tier, one ship, core loop | ⏳ Not Started |
| Phase 3 | Core systems — all tiers, all ships, economy, waves, targeting, GUT tests | ⏳ Not Started |
| Phase 4 | Content — ship upgrade trees, wave balancing, map tuning | ⏳ Not Started |
| Phase 5 | Art & Polish — sprites, particles, explosions, sound, music, UI polish | ⏳ Not Started |
| Phase 6 | Playtesting & Balancing | ⏳ Not Started |
| Phase 7 | Launch | ⏳ Not Started |

---

## 10. Open Questions & TBD Items

| System | Open Question | Priority |
|--------|--------------|----------|
| Map | Exact path waypoints (tile coordinates array) | Phase 2 |
| Map | Exact tile grid dimensions finalized in engine | Phase 2 |
| Ships | Full upgrade trees for each of the 6 ship types | Phase 4 |
| Ships | Exact projectile speed per ship | Phase 3 |
| Ships | Drone Carrier: how many drones? do they have their own range? | Phase 3 |
| Ships | Can two ships be placed adjacent? any minimum distance? | Phase 3 |
| Waves | Exact spawn group timing (delay between groups vs within groups) | Phase 3 |
| Future | Additional maps | Phase 4+ |
| Future | Special wave types (asteroid belts, comets, boss variants) | Phase 4+ |

---

*Space Defenders GDD v0.3 — This is a living document, update as decisions are finalized.*
