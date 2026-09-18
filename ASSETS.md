# BURN — Visual Assets

All art is **original** and hybrid: procedural textures + small shaders. No third-party / copyrighted game assets.

## Folders

| Path | Purpose |
|------|---------|
| `assets/textures/` | Reserved for optional baked exports (currently empty — textures generated at runtime) |
| `shaders/` | `background.gdshader`, `burnable_surface.gdshader` |
| `scripts/visual/` | Themes, presenter, particles, camera, composition, texture factory |
| `resources/themes/` | Theme ids resolved in code via `EnvironmentTheme` factories |
| `resources/levels/showcase/` | `SHOWCASE_01`–`07` art-review levels |
| `icon.svg` | App / brand mark |

## Procedural textures (`SoftTextureFactory`)

Generated per `visual_seed` (from level seed / id). Cached in `MaterialVisualCatalog`.

- **paper** — fibers + soft folds
- **wood** — grain bands + knots
- **grass** — blade clusters
- **fabric** — weave + fold shading
- **oil** — glossy puddle falloff
- **plastic** — specular band + micro scratches
- **metal** — brushed steel bands
- **glass** — rim light + transparency

Particle soft blobs are also procedural (no PNG dependency).

## Environments

| Id | Mood |
|----|------|
| `workshop` | Warm charcoal, amber accent |
| `forest` | Cool canopy green-gray |
| `warehouse` | Cold steel night |

Set via level JSON `"environment"` field, or archetype heuristic in `EnvironmentPresenter`.

## Decorative props

`CompositionLayer` spawns non-interactive silhouettes with `gameplay=false` / `decoration=true`. Never registered with `FireManager`.

## Runtime rules

- Visuals **observe** burn state only; they never write heat / ignition / progress.
- `visual_seed` must not alter solver / generator determinism.
- Particle pools stay modest for 60 FPS mobile targets.
