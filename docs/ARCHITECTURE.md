# Architecture

The project uses Godot 4.6.3, GDScript, a 640×360 viewport, and a fixed 60 Hz physics tick. Its main scene coordinates reusable actor, world, and UI components. Authored layout data builds the locations; deterministic decorative drawing does not make their terrain procedural.

## Responsibilities

| Module | Responsibility |
| --- | --- |
| `project.godot` | Main scene, Input Map, display/physics settings, autoload registration |
| `scripts/core/game.gd` | Session state, progression operations, scene requests, save/load coordination |
| `scripts/core/` | Main-scene coordination, transitions, audio, transient effects |
| `scripts/actors/` | Player controller and shared enemy runtime behavior |
| `scripts/combat/` | Combat data/types and shared combat support |
| `resources/weapons/`, `resources/enemies/`, `resources/items/` | Tunable weapon/enemy/item definitions |
| `scripts/inventory/` | Item Resource type and metadata catalog |
| `scripts/world/` | Handcrafted layouts, environment drawing, reusable interactions |
| `scenes/player/`, `scenes/enemies/`, `scenes/world/` | Reusable actor/world scene entry points |
| `scripts/ui/`, `scenes/ui/` | Main menu, HUD, paused panels, map, construction/storage UI |
| `tests/` | Native GDScript validation with isolated persistent data |

`Game` is the central session/progression autoload. Its `world_requested`, `menu_requested`, `state_changed`, `notification`, `player_died`, and `effect_requested` signals connect systems without making UI authoritative. `Game.player` points to the live actor and must be cleared/replaced during transitions.

## Actors and combat

`WBPlayer` is a `CharacterBody2D`; input actions control movement and explicit combat states. `WBEnemy` shares a reusable actor interface across Scavenger, Wolf, Sentinel, and Bell Warden configurations. Both expose health, posture, `receive_hit(...)`, and `is_alive()`. Damage responses distinguish a hit from a block, parry, or dodge.

Collision layers separate fixed world geometry (1), player bodies (2), and enemies (4). Combat range/facing checks are separate from movement collision. Attack startup, active windows, and recovery decide when damage is possible; visuals illustrate those decisions. Enemies look up the active player and stop attacking when the session or target is inactive.

Normal enemy instances are transient. Rebuilding an area after rest recreates them. A boss defeat writes a stable persistent flag before removing its instance; world construction consults that flag and does not recreate the defeated boss.

## Areas and interactions

`WBWorld.build(area_id)` constructs a handcrafted location before the node enters the scene tree. `bounds` supplies camera limits and `spawn_points` supplies named entries. The area IDs are `caravan`, `road`, `tower`, `courtyard`, `vale`, and `settlement`.

Interactables join the `interactables` group and expose `prompt` plus `interact(player)`. The main coordinator chooses a nearby target, displays its prompt, and handles the `interact` action. Interactions call progression APIs rather than writing save files themselves. Camera, transitions, and effects remain scene concerns.

The shell settlement is separate from Mossback's exterior. The Vale tablet unlocks migration after awakening. Migration changes the persistent stop and rebuilds the appropriate view; settlement objects are not carried through an overworld physics simulation.

## Persistence

The versioned save under `user://` separates permanent state from runtime nodes. Its fields include:

- Current area, position, health, and relevant player resources.
- Inventory quantities, one-time collected IDs, progression flags, activated checkpoints, and the active checkpoint.
- Worldbearer awakening, trust, condition, current stop, route unlocks, storage, and structures keyed by designated slot.

Save/load validates the decoded data before applying it. The implementation keeps a valid previous snapshot in `.bak`, writes to `.tmp`, then atomically renames the new save; it preserves recoverable data when a write fails and handle missing or corrupted saves without crashing. Tests override the save path; they must never use the normal player save.

Stable identifiers such as `bell_warden_defeated`, `shortcut_open`, and `tempered_edge` connect world construction and progression. One-time pickup IDs prevent repeated rewards. New fields need safe defaults or an explicit migration, and incompatible schema changes need a new version.

Transient fields—enemy positions, attack timers, particles, menu focus, audio playback, and camera interpolation—are not save authorities. Resting and respawning intentionally rebuild this transient state.

## Extending the prototype

Add weapons/enemies through Resources and the shared actor interface. Add authored regions through the world definition and named spawn entries. Add new persistent discoveries with stable IDs and save tests. Add further Worldbearer species using the same exterior/settlement distinction. Keep systems testable without rendering and retain a manual playtest path for game feel.
