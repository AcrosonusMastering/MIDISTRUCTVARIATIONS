### MIDISTRUCT Variations

Changelog:

V2


Avaiblable release ======>>>>>>
> A full-featured procedural MIDI generation engine written in ReaScript Lua.  

⭕if you're lost on github a direct link  on google drive:
([https://drive.google.com/file/d/1b5N9PLpbO8yC1AMyEXcnW51ktwbnxJdn/view?usp=sharing](https://drive.google.com/file/d/1ajEAM1YFkaEIaYov5oOk99HlAf4fYBfi/view?usp=sharing))

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform: REAPER](https://img.shields.io/badge/Platform-REAPER%206%2B-orange.svg)](https://www.reaper.fm)
[![Language: Lua](https://img.shields.io/badge/Language-Lua-blue.svg)](https://www.lua.org)
[![No dependencies](https://img.shields.io/badge/Dependencies-None-green.svg)]()

**MIDISTRUCT Variations** is a powerful algorithmic MIDI transformer for REAPER. It takes a single MIDI item and generates 12 unique musical variations, instantly organized into **Fixed Lanes** for seamless arrangement and composition.
# MIDISTRUCT Variations

A REAPER (ReaImGui) script that takes a single MIDI item and generates a batch of musical variations from it — one output lane per transformation you pick, laid out directly under your source item.

**Version:** 2 · **Author:** Acrosonus Mastering · **License:** gpl-3.0

---

## Features

- **24 generators** spanning rhythm, dynamics, melody, harmony, chords, and texture — from simple syncopation and staccato gating to true chord inversions, diatonic harmonization with smart voicing, Steve Reich–style phasing, and more.
- **20 Style Presets** (Reggae Skank, Trap, Bossa Nova, Metal/Power Chords, Jazz Swing, Pop, Rock, Country/Folk, Blues, IDM/Glitch...) — one click sets a Madness level *and* a matching generator selection.
- **5 Instrument Presets** (Drums, Bass, Piano/Chords, Melody/Lead) — a filter layer that unchecks whatever doesn't suit your source material. It's non-destructive: it always filters from your last full selection, so switching between instrument presets (or back to "Any / All") never permanently loses a generator choice.
- **Drum Mode** — bypasses every pitch-reordering generator so a percussion track never gets scrambled into the wrong drum sounds.
- **Auto key detection** (duration-weighted Krumhansl-Schmuckler correlation) or explicit root/scale selection.
- **Reproducible seed control**, with a one-click random seed generator.
- **PPQ-scaled**, tempo/time-signature-aware, CC/pitch-bend-preserving, with per-generator error isolation so one bad edge case never aborts the rest of the batch.

## Requirements

- REAPER with the [ReaImGui](https://github.com/cfillion/reaimgui) extension (install via ReaPack).
- A selected MIDI item containing at least one note.

## Installation

1. Copy the `.lua` file into your REAPER `Scripts` folder, or import it via **Actions → Show action list → New action → Load ReaScript**.
2. Run it from the Actions list, or bind it to a toolbar button / shortcut.

## Quick Start

1. Select a MIDI item.
2. Run the script.
3. Pick a Madness level (1–10) and, optionally, a Style Preset and/or Instrument Preset.
4. Check the generators you want.
5. Click **Generate Variations** — each checked generator produces its own item on its own fixed lane below the source.

## Documentation

- [`MIDISTRUCT_Variations_Manual.md`](./MIDISTRUCT_Variations_Manual.md) — full generator reference, preset tables, advanced settings, workflow tips (including manually chaining generators), and known limitations.
- [`TECHNICAL_DOCS.md`](./TECHNICAL_DOCS.md) — architecture, internal conventions, and a contributor's guide for extending the script (new generators, new presets, testing approach).

## Known Limitations

- No built-in generator chaining in a single pass (workaround: regenerate on top of an already-generated lane — see the manual).
- Auto key detection only recognizes major/natural minor, assumes a single key for the whole item, and is unreliable on very short phrases.
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
