# Game direction

WORLDBACK is a 2D side-scrolling action RPG about restoring the migration routes of ancient living Worldbearers. An empire's World Anchors imprisoned or corrupted these colossal creatures. A survivor follows the remains of the old roads, learns the cost of that machinery, and eventually confronts the Crown Engine.

The player alternates deliberate exploration with readable, skill-based combat. Movement, positioning, deflection, stamina, and posture matter alongside equipment. Discoveries should change the player's options: a shortcut, sword improvement, useful material, piece of lore, or awakened companion.

## First prototype

The connected route is **Fallen Caravan → Overgrown Road → Bellhaven Courtyard → Mossback Vale → Mossback settlement**, with **Old Watchtower** branching from the road. Each location has a fixed layout and distinct purpose:

| Location | Purpose |
| --- | --- |
| Fallen Caravan | Safe introduction, first Waystone, survivor lore, basic combat |
| Overgrown Road | Forest crossroads, mixed enemies, distant fortress, optional routes |
| Old Watchtower | Vertical exploration, optional tougher encounter, sword improvement |
| Bellhaven Courtyard | Permanent shortcut, pre-boss checkpoint, Bell Warden arena |
| Mossback Vale | Boss-gated discovery, Worldbearer awakening |
| Shell settlement | Rest, storage, three prefab construction slots, discrete migration |

Rootwild Scavengers establish basic melee timing. Corrupted Wolves punish careless spacing with faster approaches and lunges. Fallen Sentinels offer slower, heavier attacks with punishable recovery. The Bell Warden tests these lessons with two phases and a ground attack; its defeat permanently opens the old migration road.

Waystones restore the player and respawn normal enemies. Death returns the player to the active Waystone. Bosses, collected one-time rewards, shortcuts, and settlement changes persist. There is no roguelike reset and no freely destructible world.

## Presentation

Use a 640×360 logical viewport, consistent pixel scale, a restrained forest/stone/gold palette, readable silhouettes, layered scenery, modest effects, and clear combat telegraphs. The prototype uses original geometric drawing and synthesized audio so no external asset service is needed. Detailed production sprite art, animation, music, and broader accessibility work remain later polish.

## Worldbearers

Mossback's overworld body and its shell settlement are separate scenes backed by persistent state. Awakening begins a bond; migration changes the current stop through a transition. Construction is permitted only in settlement slots. Future free placement remains restricted to approved construction zones.

Trust, condition, route unlocks, location, storage, and structures form an extensible state model. This does not yet imply advanced companion AI, simulation of a moving city, or complete taming/survival systems.

## Long-term world

The Rootwild introduces the adventure. Later regions are the flooded **Drowned March**, industrial **Cinder Wastes**, vertically layered **Shattered Peaks**, and imperial **Crownlands**. Future Rootwild additions include Shale Hollow, the Underroot Shrine, the Thorn King's Grove, and a larger Bellhaven Fortress.

The prototype is a compact proof of the complete progression loop. The 15–30 minute target is a future playtest and content goal, not a measured result for this build.
