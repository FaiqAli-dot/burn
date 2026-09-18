# BURN

Hyper-casual fire puzzle. Tap once. Watch it burn.

**Phase 2** — playable mobile vertical slice: new materials, oil explosions, juice, audio/haptics, progression + local save, teaching levels.

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

## Procedural level generation

Factory pipeline (real `FireManager` solvability — never a fake second physics):

`LevelGenerator → LevelSolver → LevelValidator → DifficultyAnalyzer → DuplicateCheck → JSON`

```bash
# Automated tests
godot --headless --path . -s res://tools/test_level_gen.gd

# Prove solver on handcrafted SPARK
godot --headless --path . -s res://tools/prove_solver_spark.gd

# Batch generate into resources/levels/generated/
godot --headless --path . -s res://tools/generate_levels.gd
```

In-game (debug, not normal UI): **F1** toggle per-start solver dump, **N** next generated level, **B** back to SPARK.

### Headless / Linux VM tip

If the windowed editor fails to start Vulkan on a headless/VM display:

```bash
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3
```

Legacy SPARK-only check: `godot --headless --path . -s res://tools/sim_validate.gd`

## Phase 1 controls

| Input | Action |
| --- | --- |
| Tap / LMB | Ignite the tapped object (once per run) |
| R / Retry button | Reload current level |
| CONTINUE | After win — next unlocked level |
| F1 | Toggle generation debug browser |
| N / P | Next / prev (debug browse or progression advance) |
| B | Load handcrafted SPARK |
| [ | Debug: restart progression |

Goal: **BURN 100%**. Wrong starts can stall — retry and pick another spark.

## Project layout

```
scenes/           main + burnable prefab
scripts/
  autoload/       GameManager, AudioManager (stubs)
  fire/           FireManager (sim), MaterialDefinition
  objects/        BurnableObject states
  level/          LevelLoader (JSON → nodes)
  level_gen/      Generator, Solver, Validator, Difficulty, Dupes
  ui/             UIManager, ScoreManager
  visual/         ParticleManager (visual only)
resources/
  materials/      paper.tres, wood.tres
  levels/         level_01.json + generated/
tools/            sim_validate, prove_solver, generate_levels, tests
shaders/          procedural background
```

Gameplay simulation (`FireManager` + `BurnableObject` heat/state) is **separate** from visuals (`ParticleManager` / shaders). Particles never drive ignition.

## Materials

Phase 2 ships **PAPER, WOOD, GRASS, FABRIC, OIL, PLASTIC, METAL, GLASS** via `MaterialDefinition`.
Metal/glass are non-flammable obstacles (excluded from burn %). Oil detonates with a deterministic heat burst.
Add a material by creating a `.tres`, registering it in `LevelLoader.MATERIAL_PATHS`, and referencing it from level JSON.

## Assets

See [ASSETS.md](ASSETS.md). Phase 1 uses only procedural primitives/shaders (no purchased packs).

## Export notes

- Renderer: **Mobile** (iOS-friendly)
- Orientation: portrait
- No ads, analytics, or progression backend in Phase 1
