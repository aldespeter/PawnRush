# ⚔️ Shadow Knight — GameJam Platformer

> A fast-paced 2D action platformer built in **Godot 4.7** for a game jam.  
> Dash through four hand-crafted worlds, collect coins, dodge deadly traps, and face a boss that bursts from the ground to destroy you.

---

## 🎮 Overview

**Shadow Knight** is a side-scrolling 2D platformer where you guide a nimble knight through four distinct phases of increasing difficulty. Survive spikes, slimes, and a relentless Shadow Charger boss while collecting every coin you can find to earn a perfect three-star rating.

| Detail | Info |
|--------|------|
| **Engine** | Godot 4.7 (Forward Plus) |
| **Genre** | 2D Action Platformer |
| **Levels** | 4 Phases |
| **Rating System** | ⭐ 1–3 Stars per level (12 max) |
| **Max Lives** | 3 ♥ |

---

## 🗺️ Levels / Phases

| Phase | Name | Theme |
|-------|------|-------|
| Phase 1 | **Emerald Meadows** | Lush green grass world — introductory platforming |
| Phase 2 | **Autumn Canyon** | Rocky canyon with elevated platforms and hazards |
| Phase 3 | **Frozen Crypt** | Icy dungeon with Shadow Charger boss encounter |
| Phase 4 | **Void Citadel** | Final gauntlet — dark fortress with all hazards combined |

Completing all four phases leads to the **Win Screen** and a summary of your total star rating.

---

## 🕹️ Controls

### Movement

| Action | Keyboard | Arrow Keys |
|--------|----------|------------|
| Move Left | `A` | `←` |
| Move Right | `D` | `→` |
| Jump / Double Jump | `Space` or `W` | `↑` |

### Special Abilities

| Ability | Keyboard | Notes |
|---------|----------|-------|
| **Blink / Teleport** | `Shift` / `J` / Right-Click | Dash forward 75 px in facing direction. 1.5 s cooldown. One use per airborne segment. |
| **Ground Slam** | `S` / `↓` / `C` (while airborne) | Slam straight down at high speed, breaking blocks on landing. Camera shake + shockwave. |
| **Slide** | `S` / `↓` / `C` (while on ground) | Low-profile slide at 280 px/s — fits through tunnels. Can jump-cancel the slide. |
| **Dash** | Hold `Ctrl` + `D` (right) / `A` or `S` (left) | Horizontal burst of speed (380 px/s, 0.2 s). 0.6 s cooldown. Grants i-frames. |
| **Pause** | `Esc` | Opens the in-game pause menu. |

> 💡 **Pro Tip:** If you collect the **Secret Sword**, your Dash becomes a **Dash Slash** — dashing into any enemy within 30 px instantly slices them!

---

## ⚙️ Core Mechanics

### 🏃 Movement
- Run speed: **135 px/s**
- Smooth deceleration when no input is held
- Sprite automatically flips to face movement direction

### 🦘 Double Jump
- Jump velocity: **–290 px/s**
- Up to **2 jumps** per airborne segment (resets on landing)
- Higher-pitched jump sound on the second jump for audio feedback

### ✨ Blink (Teleport)
- Teleports the player **75 px** in the currently faced direction
- A ghost silhouette is left at the origin point
- Wall-collision detection prevents clipping into terrain
- Recharges after **1.5 seconds** or on touching the floor (one air-blink per jump)

### 💨 Dash
- Activated with `Ctrl` + directional key
- Moves at **380 px/s** for **0.2 s** with brief i-frame protection
- Leaves ghost trail particles during the dash
- If the **Secret Sword** is held, enemies within 30 px are instantly sliced — complete with splatter particles, spark burst, screen shake, and a hit-stop pause effect

### ⬇️ Ground Slam
- Only usable while airborne
- Slams downward at **650 px/s** — visually tinted golden-orange with ghost trail
- Landing triggers a **shockwave particle burst** and **camera shake**
- Destroys any **Breakable Blocks** beneath the player on impact

### 🏂 Slide
- Usable on the ground (or with a forgiving 14 px ground-proximity check)
- Slides at **280 px/s** and shrinks the collision shape to squeeze through low tunnels
- Accelerates on downhill slopes, decelerates on uphill ones (slope boost/friction system)
- Generates dust particles; can be jump-cancelled at any time

### 🛡️ Invulnerability Frames
- Taking damage triggers **1.2 s** of i-frames (flicker alpha effect)
- Ground Slam and Dash also grant temporary i-frames during their active windows

---

## 👾 Enemies

### 🟢 Slime (Green & Purple variants)
- Patrols back and forth, reversing direction when it detects a wall via raycasts
- Walk speed: **60 px/s**
- Contact with the Slime's kill zone damages the player
- Can be destroyed with a **Dash Slash** (requires Secret Sword)

### 💀 Shadow Charger (Boss)
Appears in Phase 3 as a scripted encounter:

1. **Emerges** from underground beside the player with a rising tween animation and dust particles
2. A **cutscene dialog** pauses gameplay and explains the dash mechanic (typewriter effect)
3. After the player clicks **Continue**, the Shadow Charger **telegraphs** its attack with 3 rapid blinks and alert sounds
4. It **dashes** at **360 px/s** across **240 px** toward the player
5. After the dash, it enters a **cooldown** phase, then transitions to a **patrol** pattern
6. The encounter repeats until the player reaches the level exit portal

---

## 🪙 Collectibles & Pickups

| Item | Effect |
|------|--------|
| **Coin** | +1 to total coin count. Contributes to per-level star rating. |
| **Life Pickup** | Restores 1 life (capped at 3 ♥) |
| **Secret Sword** | Unlocks the Dash Slash ability. Floating bob animation with particle burst on pickup. |

### ⭐ Star Rating (per level)
- Collect **0–1 coin** → ⭐ (1 star)
- Collect **2 coins** → ⭐⭐ (2 stars)
- Collect **3+ coins** → ⭐⭐⭐ (3 stars)

Best star count per level is preserved across replays. Maximum total: **12 ⭐**.

---

## ☠️ Hazards

| Hazard | Description |
|--------|-------------|
| **Spikes** | Static instant-kill floor/ceiling hazards |
| **Spike Barrier** | Lethal spike walls |
| **Ground Spike Trap** | Timed spike trap that rises from the floor |
| **Breakable Block** | Block that shatters on **Ground Slam** impact |
| **Kill Zone** | Invisible boundary — falling off screen respawns the player at their last safe position |
| **Platform** | Moving or static platforms |

---

## 💾 Game Systems

### GameManager (Autoload Singleton)
Persistent autoload that tracks all global state:
- Lives, coin counts, level stars
- Audio (music + SFX volumes, mute toggle, key rebinding)
- Scene transitions between levels and the dashboard
- Level restart with a slow-motion effect (`Engine.time_scale = 0.5`) before reload

### HUD
- Live hearts display (♥ / ♡)
- Coin counter
- Blink/Teleport cooldown indicator (cyan = ready, amber = recharging)
- Level phase title with colour-coded text
- Pause menu (Resume / Replay / Dashboard)

### Options Menu
- Master, Music, and SFX volume sliders
- Mute toggle
- Key rebinding for Move Left, Move Right, Jump, Teleport, Ground Slam

---

## 🔧 Project Setup (Godot 4.7)

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/GameJam-main.git
   ```
2. Open **Godot 4.7** (or later) and import the project:
   - Select `new-game-project/project.godot`
3. Press **F5** (or the Play button) to run from the main scene (`dashboard.tscn`).

> **Rendering Note:** The project uses `d3d12` as the Windows rendering driver (Direct3D 12). Make sure your GPU drivers are up to date.

---

## 📁 Project Structure

```
GameJam-main/
├── README.md
├── LICENSE
└── new-game-project/
    ├── project.godot          # Project settings & input map
    ├── scenes/
    │   ├── dashboard.tscn     # Main menu / level select
    │   ├── game.tscn          # Primary game scene
    │   ├── hud.tscn           # HUD overlay
    │   ├── player.tscn        # Player character
    │   ├── levels/
    │   │   ├── level_1.tscn   # Phase 1 – Emerald Meadows
    │   │   ├── level_2.tscn   # Phase 2 – Autumn Canyon
    │   │   ├── level_3.tscn   # Phase 3 – Frozen Crypt
    │   │   └── level_4.tscn   # Phase 4 – Void Citadel
    │   ├── shadow_charger.tscn
    │   ├── slime.tscn / slime_purple.tscn
    │   ├── coin.tscn / life_pickup.tscn / sword_pickup.tscn
    │   └── ...
    ├── scripts/
    │   ├── player.gd          # All player movement & abilities
    │   ├── game_manager.gd    # Autoload singleton
    │   ├── hud.gd             # HUD & pause logic
    │   ├── shadow_charger.gd  # Boss AI state machine
    │   ├── Slime.gd           # Slime patrol & slice-kill
    │   └── ...
    └── assets/
        ├── sprites/
        ├── fonts/
        ├── music/
        ├── sounds/
        └── LICENSE & CREDITS.txt
```

---

## 📜 License

All **art, music, and sound assets** are under the [Creative Commons Zero (CC0)](https://creativecommons.org/publicdomain/zero/1.0/) license — see [`assets/LICENSE & CREDITS.txt`](new-game-project/assets/LICENSE%20%26%20CREDITS.txt) for full attribution.

---

## 🙏 Credits

| Contribution | Author |
|---|---|
| Knight & Slime sprites | [analogStudios_](https://analogstudios.itch.io/) |
| World tileset & fruit sprites | [RottingPixels](https://rottingpixels.itch.io/) |
| Sounds & Music | Brackeys, Asbjørn Thirslund, Sofia Thirslund |
| Pixel Operator font | Jayvee Enaguas / HarvettFox96 |
| Asset repackaging & modifications | Brackeys |

---

*Made with ❤️ for a Game Jam — built on [Godot Engine](https://godotengine.org/).*
