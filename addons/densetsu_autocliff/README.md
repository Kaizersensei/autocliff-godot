# Autocliff for Godot

Editor-assisted cliff mesh placement for terrain/map authoring.

## What It Does

- Works with any `Node3D` surface target that has colliders below the sampling area.
- If the target is `Terrain3D`, it also uses Terrain3D data sampling and terrain-material filtering.
- Samples a rectangular area over the selected target using downward raycasts.
- Keeps only hits in a slope range (candidate cliff surfaces).
- Selects a mesh from a user-provided pool.
- Aligns mesh orientation to surface normal with random yaw jitter.
- Pushes meshes into the surface by a configurable bury offset.
- Outputs either:
  - `MultiMeshInstance3D` (recommended for heavy instancing), or
  - individual `MeshInstance3D`.

## Usage

1. Enable plugin: `Project > Project Settings > Plugins > Autocliff`.
2. Open the **Autocliff** dock (right dock).
3. Select your target surface root in the Scene tree and click **Use Selected**.
4. Add cliff meshes:
   - **Add Mesh Files** (`.obj`, `.tres`, `.res`) or
   - **Add Selected Node Mesh**.
5. Configure sampling/slope/density/offset options.
6. Click **Autocliff**.

## Notes

- Ray hits are constrained to the selected target subtree for normal collider-backed targets.
- `Terrain3D` remains supported as a first-class target with better editor-time sampling.
- `Map slope to mesh list order` lets you assign mesh pool entries from lower slope to steeper slope.
- Generated output is created under the target's parent node and tagged with group:
  - `densetsu_autocliff`

## Current Limitations

- Terrain-material filtering is only available when the target is `Terrain3D`.
- First-pass heuristic: no biome/topology masks yet.
- No collision occlusion test for "already occupied by another cliff mesh" yet.
- No placement scoring by mesh footprint yet.

These are intended next steps for the procedural toolchain.
