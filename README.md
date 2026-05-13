### MIDISTRUCT Variations
⭕ NOT FINISH
> A full-featured procedural MIDI generation engine written in ReaScript Lua.  

⭕if you're lost on github a direct link  on google drive:


[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform: REAPER](https://img.shields.io/badge/Platform-REAPER%206%2B-orange.svg)](https://www.reaper.fm)
[![Language: Lua](https://img.shields.io/badge/Language-Lua-blue.svg)](https://www.lua.org)
[![No dependencies](https://img.shields.io/badge/Dependencies-None-green.svg)]()

**MIDISTRUCT Variations** is a powerful algorithmic MIDI transformer for REAPER. It takes a single MIDI item and generates 12 unique musical variations, instantly organized into **Fixed Lanes** for seamless arrangement and composition.

---

## ✨ Features

- **The Madness Dial (1-10):** A global intensity controller that scales the complexity and "chaos" of all algorithms.
- **12 Intelligent Algorithms:** From Bach-inspired inversions to modern rhythmic shredding.
- **Fixed Lanes Integration:** Automatically configures your track to REAPER 7's Fixed Lane mode for easy auditioning.
- **Non-Destructive Workflow:** Your original MIDI is preserved in Lane 0, and the entire process is wrapped in a single Undo block.
- **Musical Intelligence:** Includes pitch-folding (keeping notes in range), beat-aware velocity curves, and organic micro-timing.

---

## 🛠 Installation

1. **Download:** Save `MIDISTRUCT_Variations_v4.lua` to your computer.
2. **Locate Scripts Folder:** In REAPER, go to `Options > Show REAPER resource path in explorer/finder`. Open the `Scripts` folder.
3. **Copy:** Move the `.lua` file into this folder.
4. **Load:** - Open the **Action List** (`?`).
   - Click `New action > Load ReaScript...`.
   - Select `MIDISTRUCT_Variations_v4.lua`.
5. **Run:** Select a MIDI item and run the script.

---

## 🎹 The 12 Variations

| Lane | Name | Musical Description |
| :--- | :--- | :--- |
| **0** | **Original** | A backup of your source material. |
| **1** | **Syncopation** | Shifts rhythms to create groove and off-beat accents. |
| **2** | **Smart Velocity** | Applies sinusoidal dynamics based on the beat. |
| **3** | **Octave & Simplify** | Note reduction + intelligent octave shifting. |
| **4** | **Strummer** | Simulates guitar/harp sweeps with micro-timing. |
| **5** | **Gate / Staccato** | Shortens notes for a plucked, rhythmic feel. |
| **6** | **Harmonizer** | Adds 5ths, sub-octaves, and a CC74 Filter Riser. |
| **7** | **Ghost Delay** | MIDI-based echo with optional pitch drift. |
| **8** | **Melodic Mirror** | Inverts the melody around its central axis. |
| **9** | **Humanize** | Adds non-linear "human" errors to timing and velocity. |
| **10** | **Rhythm Shredder** | Fragments notes into faster subdivisions. |
| **11** | **Chaos Engine** | Experimental randomization within musical constraints. |

---

## ⚙️ Technical Details

### The "Madness" Scaling
Each algorithm uses the `Madness` input to scale its internal variables:
- **Low (1-3):** Subtle variation, useful for humanization.
- **Mid (4-7):** Structural changes, new melodies, and rhythms.
- **High (8-10):** Total deconstruction and experimental textures.

### Harmonic Integrity
The **Melodic Mirror** uses a "Pitch Folding" technique. Instead of simply clamping notes that go out of the MIDI range (0-127), the script shifts them by octaves until they are back in range, preserving the harmonic class of the note.

---

License

```
MidiStruct — Algorithmic MIDI Composer for REAPER
Copyright (C) 2025 Acrosonus Mastering

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

https://www.gnu.org/licenses/gpl-3.0.html
```

**What this means in practice:**
- ✅ Free to use, modify and share
- ✅ Use in your own productions — no restrictions
- ✅ Fork and improve — contributions welcome
- ❌ Cannot be included in a closed-source commercial product
- ❌ Derivative works must remain open source under GPL v3

---
