# CyberSurge: Neon Protocol: Game Design Specification

- **Project Name**: CyberSurge: Neon Protocol
- **Target Engine**: Godot Engine 4.7.2 Stable (Official)
- **Primary Language**: GDScript 2.0
- **Platforms**: Web (HTML5 / WebAssembly) & Desktop (Windows x86_64)
- **Deployment**: Coolify / Dokploy via Docker (Nginx Alpine with COOP/COEP headers)
- **Date**: 2026-11-09
- **Status**: Approved Design

---

## 1. Vision & Core Game Loop

CyberSurge: Neon Protocol is a 2D top-down cyberpunk survivors arena game. The player controls a rogue cyborg agent surviving waves of hostile combat drones in a procedural neon cyberspace arena.

### Core Loop
1. **Combat Phase**:
   - Player moves across the arena using standard directional inputs (WASD / Arrow Keys).
   - Equiped weapons automatically target and engage the closest hostile drones within their operational range.
   - Destroyed drones drop Nano-Chips (currency) and EXP orbs.
   - A wave timer counts down toward zero.
2. **Shop & Rest Phase**:
   - When the wave ends, remaining regular enemies vanish.
   - The Cyber Shop interface opens automatically.
   - The player spends accumulated Nano-Chips to buy new weapon modules, upgrade attributes, or repair armor.
3. **Progression**:
   - The game advances across 5 distinct waves.
   - Wave 5 introduces the Mega-Mech Boss.
   - Defeating the boss triggers the Victory sequence; losing all Hit Points at any stage triggers Defeat.

---

## 2. Visual Identity & Anti-Slop Guidelines

### Visual Style
- **Procedural Geometric Neon**:
  - Entity visuals rendered via clean vector geometry (`_draw()` or `Polygon2D`) with vivid edge lighting and smooth particle trails.
  - Zero bloated external texture atlases, ensuring instantaneous asset loading and tiny Web export footprints (< 10 MB total).
- **Core Color Palette (Maximum 3 Main + 1 Accent)**:
  - **Player & Friendly Projectiles**: Neon Cyan (`#00F0FF`)
  - **Enemies & Danger Indicators**: Crimson Magenta (`#FF0055`)
  - **Loot, Currency, & UI Highlights**: Amber Gold (`#FFB000`)
  - **Environment Background**: Deep Slate Black (`#0B0E14`)

### Anti-Slop UI Standards
- No dead interactive controls: every button in the HUD and Shop has an active callback and defined feedback.
- Accessible keyboard navigation: every modal is fully operable via keyboard (keys 1-3 for shop cards, Space/Enter to confirm, Escape to cancel).
- Clear, factual copywriting: stats and upgrades describe tangible mathematical values (e.g., "+20% Move Speed") without generic buzzwords.
- Natural copy punctuation: no em-dash characters are used in any in-game dialogue or user interface text.

---

## 3. System Architecture & Node Hierarchy

```text
cybersurge/
├── project.godot
├── scenes/
│   ├── main/
│   │   ├── Main.tscn
│   │   └── Main.gd
│   ├── entities/
│   │   ├── player/
│   │   │   ├── Player.tscn
│   │   │   └── Player.gd
│   │   ├── enemies/
│   │   │   ├── EnemyBase.tscn
│   │   │   ├── EnemyBase.gd
│   │   │   ├── DroneEnemy.tscn
│   │   │   ├── DroneEnemy.gd
│   │   │   ├── HeavyEnforcer.tscn
│   │   │   ├── HeavyEnforcer.gd
│   │   │   ├── BossMegaMech.tscn
│   │   │   └── BossMegaMech.gd
│   │   └── drops/
│   │       ├── NanoChip.tscn
│   │       └── NanoChip.gd
│   ├── weapons/
│   │   ├── WeaponBase.gd
│   │   ├── BlasterWeapon.tscn
│   │   ├── BlasterWeapon.gd
│   │   ├── OrbitBladeWeapon.tscn
│   │   ├── OrbitBladeWeapon.gd
│   │   ├── TeslaArcWeapon.tscn
│   │   └── TeslaArcWeapon.gd
│   └── ui/
│       ├── HUD.tscn
│       ├── HUD.gd
│       ├── ShopModal.tscn
│       ├── ShopModal.gd
│       ├── GameOverModal.tscn
│       └── GameOverModal.gd
├── scripts/
│   ├── GameData.gd
│   └── WeaponFactory.gd
└── tests/
    └── TestRunner.gd
```

### Node Responsibilities & Communication Contracts
1. **Signal-Down, Call-Up Rule**:
   - Parent nodes call functions directly on their children.
   - Children communicate with parents strictly via Godot signals:
     - `Player.health_changed(current: int, max_hp: int)`
     - `Player.player_died()`
     - `EnemyBase.enemy_died(position: Vector2, chip_value: int)`
     - `NanoChip.chip_collected(amount: int)`
     - `HUD.upgrade_selected(upgrade_id: String)`
2. **Autoload Singleton (`GameData.gd`)**:
   - Stores current run metrics: active wave, total kills, accumulated Nano-Chips, unlocked upgrades.
   - Provides reset and calculation methods for stats scaling.

---

## 4. Mechanics Specification

### Player Attributes
- Initial Hit Points: 100
- Initial Move Speed: 240.0 pixels/second
- Targeting Radius: 320.0 pixels
- Magnet Pickup Radius: 120.0 pixels

### Weapons Matrix
1. **Pulse Blaster (Starting Weapon)**:
   - Behavior: Fires linear energy bolts toward the nearest enemy in range.
   - Cooldown: 0.4 seconds
   - Base Damage: 25
   - Projectile Speed: 650.0 pixels/second
2. **Orbiting Blade (Acquired in Shop)**:
   - Behavior: Continuous energy blade orbiting the player at a fixed distance (90.0 pixels).
   - Rotation Speed: 4.0 radians/second
   - Contact Damage: 30 per tick (0.2s tick rate per unique enemy)
3. **Tesla Arc (Acquired in Shop)**:
   - Behavior: Discharges instant chain lightning hitting a primary target and jumping to up to 2 adjacent foes within 150.0 pixels.
   - Cooldown: 1.2 seconds
   - Chain Damage: 45 / 30 / 20

### Enemies Specification
1. **Recon Drone (Chaser)**:
   - Max HP: 20
   - Move Speed: 180.0 pixels/second
   - Collision Contact Damage: 10
   - Drop Value: 1 Nano-Chip
2. **Heavy Enforcer (Bruiser)**:
   - Max HP: 140
   - Move Speed: 100.0 pixels/second
   - Collision Contact Damage: 25
   - Knockback Resistance: 90%
   - Drop Value: 5 Nano-Chips
3. **Boss: Mega-Mech Titan (Wave 5)**:
   - Max HP: 2000
   - Move Speed: 80.0 pixels/second
   - Phases:
     - Phase 1 (100% to 50% HP): Fires radial ring bullets every 3.0 seconds.
     - Phase 2 (Under 50% HP): Enters Overdrive mode, increasing movement speed to 130.0 pixels/second and launching dash charges.
   - Defeat Condition: Triggers instant game victory.

---

## 5. Wave Progression Table

| Wave | Duration | Primary Spawns | Target Spawn Interval | Objectives |
| :--- | :--- | :--- | :--- | :--- |
| **Wave 1** | 45 Seconds | Recon Drones | 1.2s | Introduction to movement and targeting |
| **Wave 2** | 50 Seconds | Drones (High density) | 0.8s | Test crowd control and evasion |
| **Wave 3** | 60 Seconds | Drones + Heavy Enforcers | 0.6s (Drone) + 3.0s (Enforcer) | Test single-target focus damage |
| **Wave 4** | 60 Seconds | Fast Swarms + Dual Enforcers | 0.4s (Drone) + 2.0s (Enforcer) | Prepare player for high pressure |
| **Wave 5** | Endless / Boss | Mega-Mech Titan + Spawns | Boss active, minion spawn 4.0s | Defeat the Boss to win |

---

## 6. Headless Test Suite Plan

The project includes an automated test runner (`tests/TestRunner.gd`) that runs via Godot console in headless mode without requiring a graphical window:

1. **Test Player Health & Damage Mitigation**:
   - Verify damage intake reduces HP correctly.
   - Verify health clamp prevents negative numbers.
2. **Test Weapon Targeting Logic**:
   - Populate mock enemies at distances 100, 200, 300, and 500 pixels.
   - Confirm targeting selects the closest enemy within the 320px sensor limit.
3. **Test Nano-Chip Magnet Physics**:
   - Verify chip outside magnet radius remains static.
   - Verify chip inside magnet radius moves toward player position and triggers collection signal.
4. **Test Shop Purchase Transactions**:
   - Verify player cannot buy items with insufficient chips.
   - Verify successful transaction deducts chips and applies upgrade stat modifiers.

---

## 7. Web Deployment Configuration (Coolify / Dokploy)

### Dockerfile
```dockerfile
FROM nginx:alpine
COPY build/web/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Required Security Headers (`nginx.conf`)
```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    add_header Cross-Origin-Opener-Policy "same-origin" always;
    add_header Cross-Origin-Embedder-Policy "require-corp" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```
