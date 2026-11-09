# CyberSurge: Neon Protocol Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a fully playable, testable 2D cyberpunk survivors arena game in Godot 4.7.2 with procedural geometric neon visuals, auto-aim combat, wave progression, a functional cyber shop, and web deployment support for Coolify/Dokploy.

**Architecture:** Node-based composition following Godot best practices (signal-down, call-up). Standalone autoload `GameData` managing run metrics and player stats; modular weapon and enemy hierarchies inheriting from base classes; headless Godot test suite for automated CI/regression checks.

**Tech Stack:** Godot Engine 4.7.2 Stable (GDScript 2.0), Headless CLI Runner, Docker (Nginx Alpine).

**Spec:** `docs/superpowers/specs/2026-11-09-cybersurge-game-design.md`

## Global Constraints
- Target Engine: Godot 4.7.2 Stable (`Godot_v4.7.2-stable_win64_console.exe`).
- Viewport: 1280x720, `canvas_items` stretch mode, `keep_width` aspect.
- Color Palette: Neon Cyan (`#00F0FF`), Crimson Magenta (`#FF0055`), Amber Gold (`#FFB000`), Slate Black (`#0B0E14`).
- Punctuation & Copy: Zero em-dash (`—`) characters in all code, comments, specs, and in-game text.
- Anti-Slop: All interactive buttons must have working callbacks; full keyboard accessibility on all modals.

## Review Focus
1. Player takes rapid multi-enemy contact damage: invulnerability frames (0.2s grace) prevent instant death.
2. Targeting sensor with 0 enemies in range: weapon does not fire or throw null reference.
3. Chip magnet behavior when player moves away faster than chip speed: chip accelerates to prevent permanent trailing.
4. Purchasing item in Cyber Shop with exact funds: chip balance cleanly drops to 0 without underflow.
5. Wave timer hits 0 while projectiles are in-flight: projectiles resolve safely before shop modal opens.

---

### Task 1: Project Foundation & Headless Test Runner Setup

**Files:**
- Create: `project.godot`
- Create: `tests/TestRunner.gd`

**Interfaces:**
- Produces: CLI execution mechanism `Godot_v4.7.2-stable_win64_console.exe --headless -s tests/TestRunner.gd` returning exit code 0 on test success.

- [ ] **Step 1: Write the failing test runner in `tests/TestRunner.gd`**
- [ ] **Step 2: Run headless test runner to verify initial bootstrap**
- [ ] **Step 3: Create `project.godot` with 1280x720 resolution and 2D canvas stretch**
- [ ] **Step 4: Re-run headless test runner and verify exit code 0**
- [ ] **Step 5: Commit initial foundation**

---

### Task 2: Autoload GameData & Nano-Chip Drop Economy

**Files:**
- Create: `scripts/GameData.gd`
- Create: `scenes/entities/drops/NanoChip.gd`
- Create: `scenes/entities/drops/NanoChip.tscn`
- Modify: `project.godot` (Register `GameData` autoload)
- Modify: `tests/TestRunner.gd`

**Interfaces:**
- Produces: `GameData.add_chips(amount: int) -> void`
- Produces: `GameData.spend_chips(amount: int) -> bool`
- Produces: `GameData.reset_run() -> void`
- Produces: `NanoChip` entity emitting `chip_collected(amount: int)`

- [ ] **Step 1: Add unit test in `tests/TestRunner.gd` for chip accumulation and spending**
- [ ] **Step 2: Run test and verify failure**
- [ ] **Step 3: Implement `scripts/GameData.gd` and register in `project.godot`**
- [ ] **Step 4: Implement procedural geometric visuals and magnet physics in `NanoChip.gd`**
- [ ] **Step 5: Run headless test runner to verify PASS**
- [ ] **Step 6: Commit GameData and NanoChip**

---

### Task 3: Player Entity & 360 Auto-Aim Targeting Sensor

**Files:**
- Create: `scenes/entities/player/Player.gd`
- Create: `scenes/entities/player/Player.tscn`
- Modify: `tests/TestRunner.gd`

**Interfaces:**
- Consumes: `GameData` stats (speed, max_hp, magnet_radius)
- Produces: `Player.get_closest_enemy() -> Node2D`
- Produces: `Player.take_damage(amount: int) -> void`
- Emits: `health_changed(current: int, max_hp: int)`, `player_died`

- [ ] **Step 1: Add player damage and nearest-enemy targeting test in `tests/TestRunner.gd`**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement `Player.gd` with neon vector drawing, 8-way WASD movement, and Area2D target sensor**
- [ ] **Step 4: Run headless test runner to verify PASS**
- [ ] **Step 5: Commit Player entity**

---

### Task 4: Modular Procedural Weapons (Pulse Blaster, Orbit Blade, Tesla Arc)

**Files:**
- Create: `scenes/weapons/WeaponBase.gd`
- Create: `scenes/weapons/BlasterWeapon.gd`
- Create: `scenes/weapons/BlasterWeapon.tscn`
- Create: `scenes/weapons/OrbitBladeWeapon.gd`
- Create: `scenes/weapons/OrbitBladeWeapon.tscn`
- Create: `scenes/weapons/TeslaArcWeapon.gd`
- Create: `scenes/weapons/TeslaArcWeapon.tscn`
- Modify: `tests/TestRunner.gd`

**Interfaces:**
- Consumes: `Player.get_closest_enemy()`
- Produces: `WeaponBase.fire()`, `WeaponBase.upgrade_level()`

- [ ] **Step 1: Add weapon firing and damage tests in `tests/TestRunner.gd`**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement `WeaponBase.gd` and the 3 procedural neon weapons**
- [ ] **Step 4: Run headless test runner to verify PASS**
- [ ] **Step 5: Commit Weapons suite**

---

### Task 5: Enemies Hierarchy & Boss Mega-Mech

**Files:**
- Create: `scenes/entities/enemies/EnemyBase.gd`
- Create: `scenes/entities/enemies/DroneEnemy.gd`
- Create: `scenes/entities/enemies/HeavyEnforcer.gd`
- Create: `scenes/entities/enemies/BossMegaMech.gd`
- Modify: `tests/TestRunner.gd`

**Interfaces:**
- Consumes: `Player.global_position`
- Produces: `EnemyBase.take_damage(amount: int)`
- Emits: `enemy_died(pos: Vector2, chip_value: int)`

- [ ] **Step 1: Add enemy movement towards target and death drop tests in `tests/TestRunner.gd`**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement `EnemyBase.gd`, `DroneEnemy`, `HeavyEnforcer`, and Phase-shifting `BossMegaMech`**
- [ ] **Step 4: Run headless test runner to verify PASS**
- [ ] **Step 5: Commit Enemies hierarchy**

---

### Task 6: Cyber Shop Modal & HUD (Anti-Slop UI)

**Files:**
- Create: `scenes/ui/HUD.tscn`
- Create: `scenes/ui/HUD.gd`
- Create: `scenes/ui/ShopModal.tscn`
- Create: `scenes/ui/ShopModal.gd`
- Create: `scenes/ui/GameOverModal.tscn`
- Create: `scenes/ui/GameOverModal.gd`
- Modify: `tests/TestRunner.gd`

**Interfaces:**
- Consumes: `GameData`, `Player.health_changed`
- Produces: Keyboard-driven upgrade card selection (Keys 1-3, Space)

- [ ] **Step 1: Add shop inventory purchase and HUD update test in `tests/TestRunner.gd`**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement clean, high-contrast HUD and Shop modal adhering to anti-slop rules**
- [ ] **Step 4: Run headless test runner to verify PASS**
- [ ] **Step 5: Commit UI and Shop**

---

### Task 7: Main Game Flow & Wave Controller

**Files:**
- Create: `scenes/main/Main.tscn`
- Create: `scenes/main/Main.gd`
- Modify: `project.godot` (Set `Main.tscn` as main scene)
- Modify: `tests/TestRunner.gd`

**Interfaces:**
- Orchestrates: 5-wave lifecycle, spawner perimeter, state machine (Combat, Shop, Victory, Defeat).

- [ ] **Step 1: Add end-to-end wave state progression test in `tests/TestRunner.gd`**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement `Main.gd` wave spawner, boundary enforcement, and camera smoothing**
- [ ] **Step 4: Run headless test runner to verify PASS across all 5 waves**
- [ ] **Step 5: Commit Main game loop**

---

### Task 8: Web Export & Docker Nginx Deployment Setup

**Files:**
- Create: `Dockerfile`
- Create: `nginx.conf`
- Create: `export_presets.cfg`
- Create: `deploy.sh`

**Interfaces:**
- Produces: Docker container with Nginx configured with COOP/COEP headers for immediate Coolify / Dokploy deployment.

- [ ] **Step 1: Create `nginx.conf` with required Cross-Origin security headers**
- [ ] **Step 2: Create `Dockerfile` packaging static export into `nginx:alpine`**
- [ ] **Step 3: Add `export_presets.cfg` for Godot Web export**
- [ ] **Step 4: Create automated build/export shell script `deploy.sh`**
- [ ] **Step 5: Verify configuration syntax and commit deployment files**
