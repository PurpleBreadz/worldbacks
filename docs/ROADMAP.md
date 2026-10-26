# Roadmap

## Current: Milestone 1 prototype

Implemented and automatically validated the connected prototype path: menu → caravan → road and optional watchtower → courtyard shortcut and Bell Warden → Mossback Vale → awakening → shell construction → save/continue.

The prototype implements the movement/combat foundation, three regular enemy configurations, a two-phase boss, six handcrafted scenes including the settlement, checkpoints, persistent rewards, basic menus, storage, and prefab building slots. Consult `TESTING.md` for evidence; feature presence alone is not a completion claim.

Before calling Milestone 1 complete:

- Perform a full graphical keyboard playthrough without developer intervention.
- Tune enemy spacing, dodge/deflection windows, stamina, boss recovery, and healing against real play.
- Review route prompts, camera bounds and traversal during combat. All eleven tower jumps already pass input-driven physics tests.
- Extend the reviewed 640×360 UI presentation checks to typical desktop resolutions and a full playthrough.
- Verify Windows/macOS builds and graphical save/reopen flow; fresh-process persistent state restoration already passes native tests.
- Measure playtime. Expand meaningful encounters/discoveries if the current route falls short of the intended 15–30 minutes.

## Later milestones

| Milestone | Focus |
| --- | --- |
| 2 — Combat expansion | Weapon classes, equipment, techniques, richer enemy behaviors and animation |
| 3 — Complete Rootwild | Shale Hollow, Underroot Shrine, Thorn King, expanded Bellhaven, quests/NPCs |
| 4 — Worldbearers | Richer bonding, settlement building, migration routes/events, facilities/NPCs |
| 5 — RPG and survival | Crafting, gathering, cooking, equipment progression, consumables, taming |
| 6 — Regions | Drowned March, Cinder Wastes, Shattered Peaks, Crownlands |
| 7 — Story | Elder Worldbearers, Crown Engine, regional changes and endings |
| 8 — Production polish | Final art/audio, animation, performance, accessibility, broad platform testing |

Do not expand these systems before the current combat and exploration loop works reliably. The next most useful development task is a recorded full graphical playthrough followed by focused corrections to traversal, combat readability, and balance.
