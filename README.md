# CyberSurge: Neon Protocol

CyberSurge is a fast-paced 2D Survivors Arena top-down game built in Godot Engine 4.7.2 with pure procedural vector neon visuals (zero external bitmap textures), modular stacking weapons, and an automated headless test suite.

## Controls
- **W, A, S, D / Arrow Keys**: Move operative
- **Auto-Aim 360°**: Weapons automatically acquire and track hostile targets in range
- **[1], [2], [3]**: Select Cyber Shop upgrades between waves
- **[Space] / [Enter]**: Continue to next wave / Restart upon defeat or victory

## Weapons
- **Pulse Blaster**: High-cadence twin plasma bolts targeting the nearest enemy.
- **Orbiting Blade**: Dual energy blades rotating around the operative, cleaving through incoming swarms.
- **Tesla Arc**: High-voltage electrical discharge jumping between up to 4 nearby enemies.

## Waves & Progression
- **Wave 1 & 2**: Swarms of fast reconnaissance Drones.
- **Wave 3 & 4**: Armored Heavy Enforcers join the frontline.
- **Wave 5**: Mega-Mech Boss encounter with second-phase fury protocol.

## Headless Automated Testing
Run the complete regression suite without opening the GUI:
```bash
./deploy.sh
```
Or directly via Godot binary:
```bash
Godot_v4.7.2-stable_win64_console.exe --headless -s tests/TestRunner.gd
```

## Deployment (Coolify / Dokploy)
This project is pre-configured with Nginx Alpine serving the WebAssembly export with the required isolation headers:
- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`
