# QuadEXQ

A single-player Quake mod by **Bob Kabura**, built on his earlier mods EXQ and QuadUTF, together with **the QuadEXQ engine**, a modified [Mark V](https://github.com/QuakeEngines/Mark_V-clone) (by Baker).

## The mod

- **PlayerSkill**: one adaptive difficulty from 0 to 100. Play well and the enemies get tougher; die and they ease off.
- **Bullet time**: build up adrenaline and the world slows down around you.
- **Elites and bosses**: every map has a boss, and the exit stays sealed until it is dead. Elites fight like players and call in reinforcements.
- **The Rune Hunter**: come back to the start map with 2 or more runes and a rival who looks just like you calls you out to an arena for a deathmatch duel, first to 10 frags. Lose and it steals a rune; then every death is a chance at a **revenge match** to win it back.
- **EXQ Arena**: duels are fought on any map you have with "dm" in its name or named "d" + a number, plus Q1Edge and Towersp.
- **Delta team**: win an arena fight and three allies join you for the rest of the map, until Delta Labs calls them back.

## The engine (Mark V, modified)

- The HUD, the intermission report card and a play log.
- Death checkpoints, and autosaves only when it is safe.
- CONTINUE in the Single Player menu, drawn in the real Quake menu font.
- Safe autosave, CONTINUE and death checkpoints for plain Quake and other mods too.
- Bullet time takes the picture back to 1996 (`qx_retro`): 640x480, the Quake palette and the old "+" crosshair at the slowest.
- Random arena pick (`qx_arena`), fixed-color player models for the Rune Hunters, and assorted fixes (for example, stuck mouse buttons with DirectInput).

## What is in this repository

This repository holds the **engine** source: Mark V v1099 Revision 4 (see `README_MarkV.md`) with the QuadEXQ changes on top, one commit each, and the mod's QuakeC source.

- `Mark_V/`: engine source (Windows, Code::Blocks / MinGW: `Mark_V/QuadEXQ.cbp`)
- `SDK/`: the libraries Mark V builds against
- `QuadEXQ/`: the mod's QuakeC source (`src/`, build with FTEQCC: `fteqcc -srcfile progs.src`) and the player's guide

The playable mod (progs.dat, pak0.pak, maps, music) is released on ModDB as the QuadEXQ download.

## Playing

You need Quake (`id1/pak0.pak`, plus `pak1.pak` for the full game). Put the mod in a `QuadEXQ` folder next to `id1` and run:

```
quadexq.exe -game QuadEXQ
```

The player's guide comes with the mod (`README_QuadEXQ_v0.7beta.txt`).

## License

GPL v2, like Mark V and Quake itself (see `gnu.txt`). Quake's game data (pak files) is not included and is not free.

## Credits

- QuadEXQ, EXQ, QuadUTF and the Towersp map: Bob Kabura
- Mark V engine: Baker and contributors; FitzQuake: John Fitzgibbons; Quake: id Software
- FrikBot: Ryan "Frika C" Smith
