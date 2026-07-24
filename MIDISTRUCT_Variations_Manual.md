# MIDISTRUCT Variations — User Manual

**Version 2.0** · ReaImGui Edition · Acrosonus Mastering

MIDISTRUCT Variations is a REAPER script that takes a single MIDI item and generates a batch of musical variations from it — one per generator you select — laid out as separate takes on fixed lanes underneath your source item.

---

## 1. Requirements

- REAPER with the **ReaImGui** extension installed (via ReaPack).
- A selected MIDI item with at least one note.

If the script fails to open with an error mentioning `ImGui_PushFont`, update to the latest version — older builds used a 2-argument call that current ReaImGui versions reject.

## 2. Installation

1. Copy the `.lua` file into your REAPER `Scripts` folder (or import it via **Actions → Show action list → New action → Load ReaScript**).
2. Run it from the Actions list, or bind it to a toolbar button/shortcut.

## 3. Quick Start

1. Select a MIDI item in the arrangement.
2. Open the script.
3. Pick a **Madness** level (1–10) and, optionally, a **Style Preset** and/or **Instrument Preset**.
4. Check the generators you want (or let a preset choose for you).
5. Click **Generate Variations**.
6. Each checked generator produces its own MIDI item on its own fixed lane, directly below your source item. The source item is preserved and re-selected when generation finishes.

---

## 4. The Madness Dial

A single slider (1 = calm, 10 = chaotic) drives roughly 30 underlying parameters at once — humanization amounts, chance percentages, velocity curves, swing, subdivision counts, and more. It's the fastest way to scale the whole batch from subtle to extreme without tuning each generator by hand.

Selecting a **Style Preset** or **Instrument Preset** may also adjust the Madness level as part of applying the preset.

## 5. Style Presets

A Style Preset sets a Madness level **and** checks a coherent bundle of generators for a recognizable style, in one click. Selecting **Custom** leaves everything as-is (it's a neutral state, not a reset).

| Preset | What it does |
|---|---|
| Reggae Skank | Short offbeat chords |
| Bossa Nova | Syncopated, gentle diatonic harmony, swelling dynamics |
| Trap / Hi-Hat Rolls | Fast subdivision bursts |
| Waltz | Arpeggiated chords, swelling dynamics, no percussion |
| Ambient / Drone | Sparse, slow-drifting modal texture |
| Funk / Ghost Notes | Fast, quiet echo hits between the main notes |
| Four-on-the-Floor House | Steady, offbeat chords/hats on the "and" |
| Breakbeat / D&B | Chopped-up, fast, aggressive |
| Lo-Fi Hip-Hop | Warm, slightly imperfect, not chaotic |
| Baroque Ornamentation | Inversions, mirrored counter-lines, parallel thirds |
| Metal / Power Chords | Literal (non-diatonic) fifths, tight gating |
| Jazz Swing | Syncopated, tight gating, 7th/9th color tones |
| Latin Clave | Displaced offbeat feel with a light arpeggiated strum |
| Minimalist / Glass | Slow phasing drift + ascending arpeggios |
| IDM / Glitch | Chopped, displaced, unpredictable |
| Pop | Catchy, clean, gentle dynamic movement |
| Rock | Driving rhythm-guitar downstrokes, punchy gating |
| Country / Folk | Simple, diatonic, light grace-note/passing-tone ornamentation |
| Blues | Swung, expressive, shuffling |

## 6. Instrument Presets

Unlike Style Presets, an Instrument Preset is a **filter**: it only *unchecks* generators that don't suit the instrument, and it always filters from your **last full selection** (whatever you checked manually, or whatever a Style Preset set) rather than from whatever an earlier Instrument Preset happened to leave checked. That means:

- Switching between Instrument Presets is non-destructive: going **Piano/Chords → Drums/Percussion** correctly re-checks generators Piano/Chords had unchecked but Drums/Percussion allows (e.g. Ratchet/Stutter) — it doesn't stay stuck at the more restrictive filter's result.
- **Any / All** actively restores that last full selection (it's not just "do nothing").
- Picking a new **Style Preset** while an Instrument Preset is active re-applies that same instrument filter on top of the new style's selection, instead of silently clearing it.
- Manually checking or unchecking a generator yourself updates what "last full selection" means going forward, exactly like picking a new Style Preset does.

| Preset | Behavior |
|---|---|
| Any / All | Restores your last full selection; no filtering |
| Drums / Percussion | Keeps only rhythm/dynamics generators; also forces **Drum Mode** on |
| Bass | Keeps rhythm, dynamics, and light ornamentation; excludes chord/harmony stacking |
| Piano / Chords | Keeps chord- and harmony-oriented generators |
| Melody / Lead | Keeps single-line melodic transformations |

**Typical workflow:** pick a Style Preset for the vibe, then an Instrument Preset to strip out anything irrelevant to your source material — e.g. "Trap / Hi-Hat Rolls" + "Drums / Percussion." Feel free to flip between Instrument Presets afterward to compare — nothing you had checked gets permanently lost.

## 7. Drum Mode

A manual checkbox (also toggled automatically by the Drums/Percussion instrument preset). When on, every generator that would reorder or transpose pitch (Power/Diatonic/Jazz Harmonizer, Melodic Mirror, Random Walk, Chord Inversions, Octave & Simplify's octave jump, Ghost Delay's pitch drift, Antiphonal Echo's transposition, Strummer/Chord Shatter/Arpeggiator's chord grouping) is bypassed or neutralized instead of scrambling your drum map.

---

## 8. The 24 Generators

### Rhythm & Timing
- **Syncopation** — displaces notes off the beat with a humanized, chance-based shift.
- **Rhythmic Displacement** — shifts the *entire* pattern by a fixed subdivision and wraps the tail around to the start (true metric displacement, not per-note).
- **Ratchet / Stutter** — subdivides notes into fast repeats with velocity decay.
- **Reich Phasing** — notes drift progressively out of alignment and wrap, à la Steve Reich's phase pieces.
- **Gate / Staccato** — shortens note durations to a fixed ratio, with a minimum floor.

### Velocity & Dynamics
- **Smart Velocity** — shapes velocity by metric position (strong downbeat, weaker offbeats), reading the project's actual time signature.
- **Dynamic Swell** — a velocity crescendo/decrescendo across the whole item.
- **Lo-Fi Groove** — randomized micro-timing and velocity humanization for a lo-fi feel.

### Pitch & Melody
- **Melodic Mirror** — inverts the melody around an axis pitch; optionally diatonic (mirrors by scale degree instead of raw semitone).
- **Random Walk Melody** — a bounded random walk across scale degrees, with automatic leap smoothing so consecutive notes don't jump too far.
- **Retrograde** — reverses the note order.
- **Octave & Simplify** — thins out notes and occasionally jumps a note an octave, with legato "glue" between same-pitch neighbors.
- **Grace Note / Ornament** — inserts a short grace note just before select notes, borrowing time from the main note.
- **Passing Tone Connector** — bridges a melodic leap between two consecutive notes with a short passing tone, only when there's enough silence to fit one without disturbing either note.

### Harmony
- **Power Harmonizer** — adds a fifth (literal by default — the true power-chord interval — with optional snap-to-scale) and/or a sub-octave, with an optional CC74 filter riser.
- **Diatonic Harmonizer** — adds a diatonic 3rd or 6th above/below, with smart voicing that flips direction to stay in a comfortable register.
- **Jazz Extensions** — adds a diatonic 7th or 9th color tone, reusing the same smart voicing as the Diatonic Harmonizer.

### Chords
- **Strummer** — staggers the notes of a chord like a strum (up, down, or alternating).
- **Chord Shatter** — breaks chords into arpeggiated steps, with occasional octave jumps.
- **Chord Inversions** — true cascading inversions (1st, 2nd, 3rd...) based on chord size, not a simple coin-flip.
- **Arpeggiator Expander** — turns chords (or single notes) into a repeating arpeggio pattern (up / down / up-down / random).

### Texture & Ambience
- **Ghost Delay** — quiet, decaying echo repeats after each note; optional diatonic pitch drift at higher Madness.
- **Drone / Pedal Point** — adds a sustained low note (detected or chosen root) under the whole phrase.
- **Antiphonal Echo** — a call-and-response echo, triggered only at the end of a phrase (a real silence), not after every single note.

---

## 9. Advanced Settings

- **Strummer Direction** — Up / Down / Alternate.
- **Harmonizer Root / Scale** — set an explicit key, or leave on Auto-Detection (duration-weighted Krumhansl-Schmuckler correlation against the 24 major/minor profiles — see §11 for its limits).
- **Harmonizer - Snap Fifth to Scale** — off by default (literal fifth); enable to bend the fifth to the detected/chosen scale.
- **Diatonic Harmonizer - Interval** and **Jazz Extensions - Interval** — choose the exact diatonic interval and direction; a live readout shows the real interval in semitones (useful since a "third" isn't the same width in every scale, e.g. a pentatonic one).
- **Diatonic Harmonizer - Smart Voicing** — keep the added harmony note in a comfortable register.
- **Melodic Mirror - Diatonic Mirror**, **Ghost Delay - Diatonic Pitch Drift** — switch these generators' pitch math from chromatic to scale-aware.
- **Arpeggiator Expander - Pattern**, **Rhythmic Displacement - Shift** — pattern/subdivision choices for those generators.
- **Power Harmonizer - Enable CC Riser** — toggle the automatic filter-cutoff riser automation.
- **Seed** — check **Fixed Seed** and click **Generate** again to reproduce the exact same variation; leave it unchecked for a fresh random result each time (the field shows the seed that was actually used, so you can fix it after the fact if you liked a result). **New Seed** draws a fresh high-precision random value and checks Fixed Seed for you — every click gives a genuinely different value, regardless of how fast you click.

## 10. Workflow Tips

- **Lanes only grow, never shrink.** Re-running the script with fewer generators checked won't hide or merge content already sitting in higher lanes.
- **Chaining generators:** MIDISTRUCT doesn't combine multiple generators into a single output automatically (each checked generator always starts from the untouched source). To stack effects — e.g. syncopate *then* harmonize — generate once, then select the *generated lane* (instead of the original item) and run the script again with a different generator checked. This is a true serial chain, not a blend: the second generator receives the notes already transformed by the first. Note: each generated item contains an invisible muted "sentinel" note used to force the correct item length; when chaining, this note is read like any other by the next pass, though its position (just after the last real note) usually makes its effect negligible.
- **CC and pitch-bend** from your source take are copied into every generated variation automatically.
- If a generator throws an unexpected error, it's skipped and the rest of the batch still completes; the final message reports exactly how many variations succeeded and which ones failed.

## 11. Known Limitations

- **No generator chaining in a single pass** — see the workflow tip above for the manual workaround.
- **Auto-Detection only recognizes major and natural minor.** It won't output a modal (Dorian, Mixolydian...) or pentatonic label — modal content resolves to its relative major/minor's note set (which is usually fine, since the generators work off the note set rather than the "root"), and pentatonic content resolves to its parent 7-note scale, which can reintroduce notes that weren't in the original pentatonic color.
- **Auto-Detection picks one scale for the whole item**, weighted by note duration. A source that modulates mid-phrase will have the modulation "averaged away" in favor of whichever key dominates by total duration. Use an explicit Root/Scale for modulating material.
- **Auto-Detection is unreliable on very short or sparse phrases** (a couple of notes) — there isn't enough information for the correlation to be meaningful, though it will still return a plausible-looking answer.

## 12. Troubleshooting

- **`'reaper.ImGui_PushFont': expected 3 arguments minimum`** — you're on an older build of this script; update to the latest version.
- **"No generators selected" error** — check at least one generator before clicking Generate.
- **Partial failure message** — one or more generators hit an unexpected edge case in your source material; the successful variations are still generated normally.
