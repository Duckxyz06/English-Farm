# English Farm 🌱

Educational farming game inspired by cozy farming RPGs, combining exploration, farming and English learning.

## Alpha 0.1 playable prototype

The repository now contains a runnable Godot prototype with:

- Momo as the controllable orange-and-white cat with a green scarf
- A large cozy farm world with house, fields, paths, trees, pond and learning garden
- Camera follow
- Walkable world boundaries and blocked buildings/pond areas
- Lily NPC interaction
- First English vocabulary quest: `CARROT = CÀ RỐT`
- Coin reward after answering correctly
- In-game HUD and interaction hints

### Controls

- `W A S D` — move Momo
- `E` — interact / close dialogue
- `1` / `2` — answer Lily's English question

## Run in Godot

1. Install Godot 4.3 or newer.
2. Clone or download this repository.
3. Open `project.godot` in Godot.
4. Press **F6/F5** or click **Run Project**.

The main scene is `game/scenes/Main.tscn`.

## Automatic Windows build

GitHub Actions configuration is included at `.github/workflows/godot-alpha.yml`.
When Actions are enabled for the repository, pushes to `main` run a Godot headless smoke test and export a Windows artifact named:

`EnglishFarm-Windows-Alpha`

## Visual direction

The final asset target remains:

- pixel-art cozy farming style
- Momo: orange-and-white cat, green leaf scarf
- wooden/cream/leaf UI language
- warm natural palette

The current Alpha uses procedural pixel-style shapes so gameplay can be tested before the final sprite sheet and tileset are integrated.

## Project structure

```text
project.godot
export_presets.cfg
game/
  scenes/
  scripts/
  assets/
data/
docs/
scripts/
ui/
```

## Next milestones

- replace procedural Momo with final sprite sheet and animations
- replace procedural environment with approved tilemap assets
- expand farming interactions
- add inventory UI and more quests
- save/load system
