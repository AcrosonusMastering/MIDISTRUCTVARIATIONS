### MIDISTRUCT Variations
⭕ NOT FINISH
> A full-featured procedural MIDI generation engine written in ReaScript Lua.  

⭕if you're lost on github a direct link  on google drive:


[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform: REAPER](https://img.shields.io/badge/Platform-REAPER%206%2B-orange.svg)](https://www.reaper.fm)
[![Language: Lua](https://img.shields.io/badge/Language-Lua-blue.svg)](https://www.lua.org)
[![No dependencies](https://img.shields.io/badge/Dependencies-None-green.svg)]()

MIDISTRUCT Variations is an intelligent MIDI variation generator for REAPER, designed to transform a single MIDI take into eight distinct musical variations. Developed by Acrosonus Mastering, this tool uses algorithmic processing to handle everything from subtle humanization to complex melodic inversion.
🌪️ The Madness Dial

The core of the script is the Madness Dial (scaled 1–10), which dynamically adjusts the intensity of every algorithm:

    Levels 1–3: Subtle rhythmic nudges, light humanization, and polite dynamics.

    Levels 4–7: Clear structural changes, wider strums, and richer harmonies.

    Levels 8–10: "Creative chaos" with aggressive syncopation, drifting pitch echoes, and extreme staccato plucks.

    The script uses ExtState to remember your last madness setting across different REAPER sessions.

🎹 Included Variations

When run, the script generates eight new takes within the selected MIDI item:

    Syncopation: Features rhythmic displacement and groove humanization.

    Smart Velocity: Applies beat-aware dynamics and sinusoidal accent curves.

    Octave & Simplify: Performs intelligent note reduction and octave color shifts.

    Strummer: Creates chord sweeps or arpeggios with organic micro-timing jitter.

    Gate / Staccato: An aggressive rhythmic transformer that shortens notes into plucks.

    Power Harmonizer: Adds perfect fifths and sub-bass layers, complete with a CC74 smoothstep filter riser.

    Ghost Delay: Generates MIDI echoes with velocity decay and optional pitch drift.

    Melodic Mirror: Bach-style melodic inversion around a pitch axis (Median or Center) with intelligent octave folding.

🛠 Installation

    Open REAPER.

    Open the Actions List (default shortcut: ?).

    Click New action > Load ReaScript...

    Select MIDISTRUCT_Variations.lua.

    (Optional) Assign the script to a toolbar button or keyboard shortcut for quick access.

🚀 How to Use

    Select a MIDI Media Item in your project.

    Run the script.

    Enter a Madness Level between 1 and 10.

    Click OK. Eight new takes will be added to your item.

    Use the T key (default REAPER shortcut) to cycle through and audition the new variations.

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
