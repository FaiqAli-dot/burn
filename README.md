# BURN

Hyper-casual fire puzzle. Tap once. Watch it burn.

**Phase 1** — Godot 4.x + GDScript prototype proving IGNITE → SPREAD → CHAIN → DESTROY.

## Requirements

- [Godot 4.3+](https://godotengine.org/download) (4.3 / 4.4 recommended)
- Desktop or mobile export target (portrait)

## Open & run

1. Clone this repo.
2. Open **Godot 4.x** → **Import** → select `project.godot`.
3. Press **F5** (or Play). Main scene: `scenes/main.tscn`.
4. **Tap / click** a burnable object to ignite. One spark per attempt.
5. **R** or on-screen **RETRY** to restart instantly.

Viewport is **720×1280** portrait with canvas stretch.

## Phase 1 controls

| Input | Action |
| --- | --- |
| Tap / LMB | Ignite the tapped object (once per run) |
| R / Retry button | Reload Level 1 |

Goal: **BURN 100%**. Wrong starts can stall — retry and pick another spark.

## Project layout

```
scenes/           main + burnable prefab
scripts/
  autoload/       GameManager, AudioManager (stubs)
  fire/           FireManager (sim), MaterialDefinition
  objects/        BurnableObject states
  level/          LevelLoader (JSON → nodes)
  ui/             UIManager, ScoreManager
  visual/         ParticleManager (visual only)
resources/
  materials/      paper.tres, wood.tres
  levels/         level_01.json
shaders/          procedural background
```

Gameplay simulation (`FireManager` + `BurnableObject` heat/state) is **separate** from visuals (`ParticleManager` / shaders). Particles never drive ignition.

## Materials

Phase 1 ships **PAPER** and **WOOD** via `MaterialDefinition` resources. Add a new material by creating a `.tres`, registering its path in `LevelLoader.MATERIAL_PATHS`, and referencing it from level JSON — no FireManager rewrite.

## Assets

See [ASSETS.md](ASSETS.md). Phase 1 uses only procedural primitives/shaders (no purchased packs).

## Export notes

- Renderer: **Mobile** (iOS-friendly)
- Orientation: portrait
- No ads, analytics, or progression backend in Phase 1
