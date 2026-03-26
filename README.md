# Autocliff for Godot

Standalone Godot editor plugin for scattering cliff meshes (primarily) onto arbitrary scene surfaces. It can also be used to scatter plants or any kind of mesh you desire.

## What It Does
- Places cliff instances onto a target surface using downward ray tests
- Can align cliffs to hit normals
- Supports density, scale, rotation, offset, and randomization controls
- Works with any `Node3D` target that exposes collider-backed surfaces
- Retains `Terrain3D` compatibility when used against a `Terrain3D` target

## Requirements
- Godot `4.6`
- `Terrain3D` is optional, not required

## Terrain3D Compatibility
When the target is a `Terrain3D` node, the plugin can still use terrain-specific sampling and terrain-material filtering.

When the target is any other `Node3D`, the plugin falls back to generic collider-based placement and skips terrain-only features.

## Installation
1. Copy the `addons/densetsu_autocliff` folder into your project.
2. Enable the plugin in `Project > Project Settings > Plugins`.
3. Open the Autocliff dock from the editor.

## Basic Usage
1. Set a target surface node path.
2. Assign one or more cliff source scenes.
3. Configure spacing, density, rotation, scale, and offset.
4. Generate the cliff layout.
5. Clear and regenerate as needed.

## Intended Use
This plugin is meant for fast environment dressing and iteration, especially for cliffs, rock formations, and plant clusters where hand placement is too slow.

## Scope
This public version is project-agnostic. It does not rely on a private project structure or private tooling.
