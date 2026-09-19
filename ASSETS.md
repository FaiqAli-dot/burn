# BURN — Art Asset Library

All gameplay art is **original / generated for BURN**. No copyrighted, ripped, or random stock packs.

## Style
Premium stylized 2D illustration — soft painterly shading, readable silhouettes at gameplay size, warm dark atmospheres. Not photoreal, not pixel art, not emoji.

## Layout

```
assets/
  materials/{paper,wood,grass,fabric,oil,plastic,metal,glass}/  # 4 variants each
  fire/{flames,embers,smoke,bursts,burn_masks}/
  environments/{workshop,forest,warehouse}/backdrop.png
  ui/branding/flame_mark.png
  _src/   # generation sheets (Godot-ignored via .gdignore)
```

## Materials (32 sprites)
| Material | Variants |
|----------|----------|
| paper | sheet, folded, stack, torn |
| wood | plank, log, branch, crate |
| grass | clump, patch, tuft, blades |
| fabric | strip, folded, hanging, bundle |
| oil | puddle, trail, droplet, spill |
| plastic | bottle, container, sheet, block |
| metal | can, plate, sheet, beam |
| glass | bottle, panel, shard, jar |

Variant selection is presentation-only: `hash(material + object_id + visual_seed)`.

## Fire / FX
- Flames: small, medium, large, side
- Embers / smoke / burst plates
- Burn masks: hole_irregular, crack, multihole, edge_eat (organic dissolve, not circular)

## Environments
Workshop / Forest / Warehouse authored backdrop plates + shader wash / vignette.

## Integration
- `MaterialVisualCatalog` loads authored PNGs
- `MaterialVisualDefinition` separates appearance from gameplay `MaterialDefinition`
- `BurnableObject` primary visual = `Sprite2D` + `burnable_sprite.gdshader` (polygons hidden)
- Particles sample flame/ember/smoke textures
- Intro / Main Menu use `ui/branding/flame_mark.png`

## License
All files under `assets/` were authored/generated for this project. Free to ship with BURN.
