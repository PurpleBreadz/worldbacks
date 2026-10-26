# WORLDBACK

An original 2D dark fantasy action RPG built with **Godot 4.6.3 (standard edition) and GDScript**. Explore a handcrafted fragment of the Rootwild, confront the Bell Warden, and awaken a Worldbearer whose shell becomes a small settlement.

Milestone 1 now has a connected, compact playable prototype. It uses original geometric pixel-style art and synthesized sound, with no external asset or package dependencies. The intended final slice is 15–30 minutes; prototype playtime and combat balance have not yet been established by human playtesting.

## Run

1. Install the standard Godot **4.6.3** editor for your operating system. The .NET edition and export templates are unnecessary for editor play.
2. Import this repository's `project.godot` in the Godot Project Manager.
3. Open the project and press **F6 only for an individual scene**, or **F5 to run the game**. Choose **Begin a new journey** to begin or **Continue journey** to load saved progress.

From a terminal in the checkout:

```sh
godot --editor --path .
godot --path .
```

In the prepared Codex cloud environment, activate the pinned executable first:

```sh
export PATH=/workspace/.worldback-tools/bin:$PATH
cd /workspace/worldbacks
godot --headless --version
```

Headless mode supports validation and tests. Use a local graphical Godot editor to play the game and assess rendering, sound, and feel. Desktop exports for Windows and macOS require matching export templates and platform-specific verification; packaged releases are not included.

## Controls

| Action | Key |
| --- | --- |
| Move | A / D |
| Jump; release early for a shorter jump | Space |
| Dodge | Shift |
| Sword attack | J |
| Block; press just before impact to deflect | K |
| Interact | E |
| Heal | Q |
| Inventory | Tab |
| Discovered areas | M |
| Pause / close menu | Esc |

Inputs use Godot's Input Map. Basic gamepad actions are mapped, but keyboard is the validated control scheme; complete controller navigation remains future work.

## Prototype route

Begin at the **Fallen Caravan** and activate its Waystone. Follow the **Overgrown Road** toward **Bellhaven Courtyard**; the **Old Watchtower** is an optional vertical detour with a useful treasure. Open the courtyard shortcut, rest before the boss, and defeat **the Bell Warden** to open the way to **Mossback Vale**. Awaken Mossback, enter the separate shell settlement, and spend collected scrap on one of its three building slots. Discover the route tablet farther right in the Vale, then use the settlement helm to migrate between the Vale and Fallen Caravan. Storage and discrete migration stops demonstrate the foundation for a persistent mobile settlement.

Watch enemy telegraphs, manage stamina, and use deflection to build enemy posture. Resting restores resources and respawns normal enemies; boss defeats, collected treasures, shortcuts, and settlement structures are permanent progress. Save progress from the pause menu or at Waystones before quitting.

## Validate

```sh
bash tests/validate.sh
```

Set `GODOT=/path/to/godot` if needed. The completed run passed 113 gameplay/persistence checks, 53 UI checks, 18 traversal checks, input-only combat, and save restoration across two processes. See [testing evidence and limits](docs/TESTING.md).

## Development

- [Design and scope](docs/GAME_DESIGN.md)
- [Architecture and persistence](docs/ARCHITECTURE.md)
- [Validation and manual acceptance checks](docs/TESTING.md)
- [Roadmap](docs/ROADMAP.md)
- [Changelog](docs/CHANGELOG.md)
- [Contributor and agent instructions](AGENTS.md)

The current focus is a connected prototype rather than the entire RPG. Creature taming, the complete Rootwild, crafting, equipment variety, unrestricted settlement building, and later regions remain future work. Automated test results and their limitations are recorded in `docs/TESTING.md`; implementation alone does not establish gameplay quality.
