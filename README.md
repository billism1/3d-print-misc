# 3D Print Miscellaneous

Miscellaneous 3D models too small to warrant their own repository. Each model lives in `src/` with its publication-ready STL in `publication/`.

## Models

| Model | Source | STL |
|-------|--------|-----|
| Flashlight shim / tail holder | [flashlight_holder.scad](src/flashlight_holder.scad) | [flashlight_holder.stl](publication/flashlight_holder.stl) |
| Beer can koozy — interior negative | [beer_can_koozy_negative.scad](src/beer_can_koozy_negative.scad) | [beer_can_koozy_negative.stl](publication/beer_can_koozy_negative.stl) |
| Beer can koozy — basic body example | [beer_can_koozy_negative.scad](src/beer_can_koozy_negative.scad) (`show_koozy=true`) | [beer_can_koozy_example_basic.stl](publication/beer_can_koozy_example_basic.stl) |
| Trophy cup (on selected base) | [trophy_cup.scad](src/trophy_cup.scad) | [trophy_cup.stl](publication/trophy_cup.stl) |
| Trophy base — ogee, minimal | [trophy_base_ogee_minimal.scad](src/trophy_base_ogee_minimal.scad) | [trophy_base_ogee_minimal.stl](publication/trophy_base_ogee_minimal.stl) |
| Trophy base — ogee | [trophy_base_ogee.scad](src/trophy_base_ogee.scad) | [trophy_base_ogee.stl](publication/trophy_base_ogee.stl) |
| Trophy base — scotia | [trophy_base_scotia.scad](src/trophy_base_scotia.scad) | [trophy_base_scotia.stl](publication/trophy_base_scotia.stl) |

## Repository Layout

- `src/` — editable source/design files (OpenSCAD, CAD, parametric models)
- `publication/` — publication-ready STL files

## Rendering

Both scripts require [OpenSCAD](https://openscad.org/) installed (found automatically
in `C:\Program Files\OpenSCAD\` or on `PATH`). STLs are written to `publication/`,
overwriting any existing file of the same name.

### Render one model

```powershell
powershell -ExecutionPolicy Bypass -File render.ps1 <scad-file>
```

The argument may be a bare name, a name with extension, or a path:

```powershell
powershell -ExecutionPolicy Bypass -File render.ps1 trophy_cup
powershell -ExecutionPolicy Bypass -File render.ps1 src\flashlight_holder.scad
```

### Render all models

```powershell
powershell -ExecutionPolicy Bypass -File render_all.ps1
```

Renders every `src/*.scad` file. Some files emit multiple variants — e.g.
`beer_can_koozy_negative.scad` produces both `beer_can_koozy_negative.stl`
(negative only) and `beer_can_koozy_example_basic.stl` (full koozy body).
