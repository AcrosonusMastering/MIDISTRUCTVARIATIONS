# MIDISTRUCT Variations — Technical Documentation

Version 2.0 · Single-file Lua ReaScript (ReaImGui) · gpl-3.0

This document describes the internal architecture for contributors — written so
that someone with no prior context can pick the project up. For end-user
instructions, see `README.md` and `MIDISTRUCT_Variations_Manual.md`.

**If you read nothing else, read §11 (Common Pitfalls) before touching the
seed logic, the collision resolver, or the preset system — all three have bitten
this project before, for non-obvious reasons.**

---

## 1. High-Level Architecture

The script is a single `.lua` file organized top-to-bottom as:

```
Header (@description/@version/@changelog)
Constants & CFG (default parameter table)
UI_STATE (persisted user selections)
Dropdown option tables (STRUM_DIRS, HARM_ROOTS, HARM_SCALES, ARP_PATTERNS, ...)
Utility functions (clamp, chance, gaussian_random, scale_ticks, swing_offset, ...)
Scale / key-detection helpers (detect_scale, get_explicit_scale, build_scale_list,
  pitch_to_diatonic_step, diatonic_step_to_pitch, describe_degree_interval)
MIDI I/O helpers (read_notes, read_cc, write_notes, get_ppq_per_beat,
  get_item_length_ppq)
resolve_same_pitch_overlaps (universal collision resolver)
24 generator functions (variation_*)
ALL_DEFS (the generator registry)
apply_madness (Madness dial → CFG)
STYLE_PRESETS / apply_style_preset
INSTRUMENT_PRESETS / apply_instrument_preset
GenerateSelectedVariations (the generation engine)
LoadState / SaveState (ExtState persistence)
loop() (ReaImGui UI, runs every frame via reaper.defer)
```

There is no module system — everything is `local` to the single chunk, in
declaration order. Functions must be defined before first use (standard Lua
top-down scoping). The one exception is `apply_instrument_preset`, which is
forward-declared (`local apply_instrument_preset` with no body) near the top of
the presets section so `apply_style_preset` — defined earlier — can call it;
its real body is assigned later with `function apply_instrument_preset(idx)
... end` (no `local`, since the name is already declared). If you need a
similar forward reference elsewhere, follow this same pattern rather than
reordering large blocks of code.

### Quick-reference index

| Looking for... | Search for... |
|---|---|
| A specific generator's logic | `variation_<name>`, e.g. `variation_ghost_delay` (see §6 for the full name↔function table) |
| The generator registry / checkbox list | `ALL_DEFS` |
| A tunable default value | `CFG.<FIELD_NAME>` inside the big `CFG = { ... }` table |
| How Madness maps to CFG | `apply_madness` |
| A Style Preset | `STYLE_PRESETS`, `STYLE_PRESET_NAMES` |
| An Instrument Preset | `INSTRUMENT_PRESETS`, `INSTRUMENT_PRESET_NAMES` |
| Seed / RNG behavior | inside `GenerateSelectedVariations`, the `used_seed` block, and the "New Seed" button in `loop()` |
| The main generation loop | `GenerateSelectedVariations` |
| A UI widget | `loop()` |
| Saved settings | `LoadState`, `SaveState`, `EXT_SEC` |

## 2. Data Model

A **note** is a plain table:

```lua
{ selected = bool, muted = bool, startppq = number, endppq = number,
  chan = int (0-15), pitch = int (0-127), vel = int (1-127) }
```

A **CC event** is:

```lua
{ selected = bool, muted = bool, ppq = number,
  chanmsg = int, chan = int, msg2 = int, msg3 = int }
```

Both are read from the source take with `read_notes(take)` / `read_cc(take)` and
written back with `write_notes(take, notes, cc_events)`, which calls
`reaper.MIDI_DisableSort`, inserts everything, then `reaper.MIDI_Sort`.

All PPQ values in a **generator's input/output are already remapped into the
target take's PPQ space** by the engine before/after the generator runs — a
generator function only ever sees notes it can treat as "this take's ticks."

## 3. The CFG / Madness System

`CFG` is one flat table of ~90 tunable numbers/flags (durations, chances,
velocity multipliers, thresholds...). `apply_madness(level)` (level 1–10) is
the single function that derives every one of these from the slider position,
usually via a small local `dial(calm_value, chaotic_value)` closure that
linearly interpolates between the two extremes.

**Rule for new tunables:** add the field to `CFG` with a sensible static
default, then add one line to `apply_madness` if it should scale with the
dial, or leave it untouched if it's a structural/mode setting driven by a UI
dropdown/checkbox instead (e.g. `CFG.STRUM_DIRECTION`, `CFG.DRUM_MODE`).

`apply_madness` is called once, at the top of `GenerateSelectedVariations`,
before any generator runs — so `UI_STATE` is the single source of truth during
UI interaction, and `CFG` is only guaranteed fresh at generation time.

## 4. PPQ-Independence: `scale_ticks`

Any constant expressed "in ticks" is meaningless across projects/items with a
different PPQ resolution. Constants that must scale are stored **as if the
resolution were 960 ticks/quarter** and converted at the call site with:

```lua
scale_ticks(ticks_at_960, ppqbeat) -- math.max(1, floor(ticks_at_960 * ppqbeat/960 + 0.5))
```

Any new generator introducing an absolute tick threshold (a minimum
duration, a grouping tolerance, a gap threshold, etc.) **must** go through
`scale_ticks`, not a bare literal — this was the source of several bugs in
earlier versions when it was missed for individual generators (see §11).

## 5. Key/Scale Detection & Diatonic Math

- `detect_scale(notes)` — duration-weighted Krumhansl-Schmuckler correlation
  against the 24 major/minor profiles (12 roots × major/minor). Returns a
  `{ [0..11] = true }` pitch-class-presence table. It only ever resolves to a
  major or natural-minor 7-note set; modal/pentatonic input gets folded into
  its closest major/minor relative. It picks **one** scale for the whole note
  array — it has no concept of modulation.
- `get_explicit_scale()` — returns the same shape from the Harmonizer
  Root/Scale dropdowns, or `nil` if the user left them on Auto.
  Generators call `get_explicit_scale() or detect_scale(notes)`.
- `build_scale_list(scale)` — turns the pitch-class set into a sorted array
  of pitch classes (the actual "scale degree table" used everywhere else).
- `pitch_to_diatonic_step(pitch, scale_list)` / `diatonic_step_to_pitch(step,
  scale_list)` — convert between an absolute MIDI pitch and a flattened
  "scale degree index" (`octave * #scale_list + index_within_octave`), so
  moving by `#scale_list` steps is always exactly one octave. This is the
  primitive that every diatonic generator (Diatonic Harmonizer, Jazz
  Extensions, Melodic Mirror's diatonic mode, Random Walk, Antiphonal Echo)
  builds on. Moving a pitch by ± the scale size semitone-preserves the scale
  degree while shifting by exactly one octave (±12 semitones) — this is the
  mechanism behind "smart voicing" (folding a harmony note back into a
  comfortable register without changing which scale degree it is) and behind
  Random Walk's leap-smoothing.

## 6. Generator Contract

Every generator is a function with the signature:

```lua
function variation_xxx(notes, ppqbeat, item_len_ppq, take)
```

Not every generator uses all four arguments (Lua ignores extra ones), but the
engine always calls with all four positionally, so a new generator can freely
add whichever it needs. Contract:

- **Input `notes`** is an array of note tables in the *current take's* PPQ
  space, in arbitrary order (sort a local copy if you need time order).
- **Return value** must be a new/mutated array of note tables in the same
  shape. Returning fewer, more, or repositioned notes is fine.
- **Never** assume `notes` is sorted by `startppq`.
- **Respect `CFG.DRUM_MODE`**: if the generator reorders or transposes pitch
  in a way that would scramble a GM drum map, bypass that part (or the whole
  function) when `CFG.DRUM_MODE` is true. Two patterns are in use: full
  bypass (`if CFG.DRUM_MODE then return notes end`) for generators that are
  pitch-alteration in their entirety, or a conditional guard around just the
  pitch-altering block for generators that also do something timing-only
  worth keeping (e.g. Ghost Delay still produces same-pitch echoes under Drum
  Mode, just without pitch drift).
- **Group by channel, not just by time**, when clustering simultaneous notes
  into a "chord" (Strummer, Chord Shatter, Chord Inversions, Arpeggiator) —
  `notes[j].chan == n.chan` must be part of the grouping condition, so
  multi-channel content isn't merged incorrectly.

### The 24 generators (name → function → notes)

| `ALL_DEFS.name` | Function | Extra fields |
|---|---|---|
| Syncopation | `variation_syncopation` | |
| Smart Velocity | `variation_smart_velocity` | |
| Octave & Simplify | `variation_octave_simplify` | |
| Strummer | `variation_strummer` | |
| Gate / Staccato | `variation_gate_staccato` | |
| Power Harmonizer | `variation_power_harmonizer` | `cc_builder = build_cc_riser` |
| Ghost Delay | `variation_ghost_delay` | `skip_collision_resolve = true` |
| Melodic Mirror | `variation_melodic_mirror` | |
| Retrograde | `variation_retrograde` | |
| Ratchet / Stutter | `variation_ratchet` | |
| Reich Phasing | `variation_reich_phasing` | |
| Chord Shatter | `variation_chord_shatter` | |
| Chord Inversions | `variation_chord_inversions` | |
| Dynamic Swell | `variation_dynamic_swell` | |
| Lo-Fi Groove | `variation_lofi_groove` | |
| Diatonic Harmonizer | `variation_diatonic_harmonizer` | |
| Arpeggiator Expander | `variation_arpeggiator` | |
| Rhythmic Displacement | `variation_rhythmic_displacement` | |
| Drone / Pedal Point | `variation_drone_pedal` | |
| Random Walk Melody | `variation_random_walk` | |
| Antiphonal Echo | `variation_antiphonal_echo` | |
| Grace Note / Ornament | `variation_grace_note` | |
| Jazz Extensions | `variation_jazz_extensions` | |
| Passing Tone Connector | `variation_passing_tone` | |

### Registering a generator

Add it to `ALL_DEFS`:

```lua
{ name = "My Generator", fn = variation_my_generator }
```

Optional fields:
- `cc_builder = some_function(take, item)` — returns an array of CC events to
  merge into the output (only `Power Harmonizer`'s CC74 riser uses this today).
- `skip_collision_resolve = true` — opts the generator out of the universal
  same-pitch/channel overlap resolver (see §7). Use this only when overlapping
  same-pitch output is part of the intended effect (currently only Ghost
  Delay: its echoes are meant to overlap a sustained original note).

The checkbox list, take naming (`"<name> [M<level>]"`), and Style/Instrument
preset filtering all key off `def.name` — **treat it as a stable identifier**,
not just a display label. If you rename a generator, update every
`STYLE_PRESETS`/`INSTRUMENT_PRESETS` entry that references the old name (they
match by exact string, and a silent mismatch just means the preset quietly
fails to toggle that generator — there is no validation warning for this). A
small standalone script that cross-checks every `toggles`/`allowed` string
against `ALL_DEFS` names is a good sanity check to run after any rename; see
§10 for the same idea applied as a repeatable test.

## 7. Universal Collision Resolver

`resolve_same_pitch_overlaps(notes)` runs on every generator's output (unless
`skip_collision_resolve` is set) before the mute "sentinel" note is appended
and the result is written. It groups notes by `(chan, pitch)`, and within each
group:

- Exact duplicate `(startppq, endppq)` pairs are de-duplicated to one note.
- Any remaining overlap is resolved by truncating the earlier note's `endppq`
  to the later note's `startppq`.

This exists to avoid voice-stealing / stuck-note behavior on monophonic-per-
voice synths from accidental overlaps introduced by a transformation. If a new
generator's design *depends on* overlapping same-pitch output, set
`skip_collision_resolve = true` on its `ALL_DEFS` entry rather than fighting
the resolver.

## 8. Style Presets & Instrument Presets

Two independent, composable preset layers, both ultimately just writing into
`UI_STATE` (they never touch `CFG` directly — `apply_madness` picks those
changes up at generation time).

### 8.1 The reference selection: `UI_STATE.toggle_baseline`

`UI_STATE.toggles[i]` is what's actually checked right now (and what the
engine reads to decide which generators to run). `UI_STATE.toggle_baseline[i]`
is "the last selection the user actually meant" — updated only by:

1. A manual checkbox click in `loop()`.
2. Applying a Style Preset (its `toggles` list becomes the new baseline).

**Never** update `toggle_baseline` from inside `apply_instrument_preset` — an
Instrument Preset is a *view* over the baseline, not a new baseline itself.
This distinction exists because of a real bug (see §11): without it, filtering
with one Instrument Preset and then switching to a more permissive one could
never re-check anything the first filter had removed, since the second
filter's "what's currently checked" input was already the first filter's
output.

### 8.2 `STYLE_PRESETS[idx]`

A table of fields to *set*: `madness`, `displace_div_idx`, `dia_harm_interval`,
`strum_dir`, `mirror_diatonic`, `ghost_drift_diatonic`, `harm_fifth_snap`,
`arp_pattern`, and `toggles` (an array of generator names — every checkbox is
unconditionally set to match this list, on or off, **and** this list becomes
the new `toggle_baseline`). Index `0` (`"Custom"`) has `nil` in the presets
array, so `apply_style_preset` returns immediately without touching anything
— the intentional "no-op" state, not a reset.

After setting toggles/baseline, `apply_style_preset` calls
`apply_instrument_preset(UI_STATE.instrument_preset)` so that whatever
Instrument filter was already active gets re-applied to the new selection
instead of silently disappearing.

### 8.3 `INSTRUMENT_PRESETS[idx]`

A table with `drum_mode` (optional) and `allowed` (an array of generator
names). `apply_instrument_preset`:

```lua
UI_STATE.toggles[i] = UI_STATE.toggle_baseline[i] and allowed[def.name] or false
```

— always derived from the **baseline**, never from the current `toggles`
state. Index `0` (`"Any / All"`) has `nil` in the presets array; instead of a
no-op, it actively restores `toggles[i] = toggle_baseline[i]` for every
generator, since "no filter" should mean "back to what you actually chose."

When adding a new preset of either kind, generator names in `toggles`/
`allowed` must exactly match `ALL_DEFS[i].name`.

## 9. Seed / RNG Reproducibility

Resolved once, at the top of `GenerateSelectedVariations`:

```lua
if UI_STATE.seed_fixed and UI_STATE.seed_value then
  used_seed = math.floor(UI_STATE.seed_value) % 2147483647
else
  used_seed = (os.time() + math.floor(r.time_precise() * 100000)) % 2147483647
end
math.randomseed(used_seed)
for _ = 1, 10 do math.random() end -- discard the first few draws (see §11)
UI_STATE.seed_value = used_seed -- always reflects what was actually used
```

Key points for anyone touching this:

- **`0` is a valid seed.** Don't reintroduce a `UI_STATE.seed_value ~= 0` guard
  as a way to detect "not set yet" — `seed_fixed` is the only thing that
  should gate this branch (see §11 for why this exact mistake happened once).
- The result is clamped to the **int32** range (`% 2147483647`) because the
  same value is also displayed in an `ImGui_InputInt` field, which is a native
  32-bit signed int — an unclamped value can silently wrap to something
  nonsensical in the widget.
- The **"New Seed" button** in `loop()` must use a high-resolution entropy
  source (`r.time_precise()`, sub-second) mixed with `os.time()`, never
  `os.time()` alone — `os.time()` only has 1-second resolution, so two clicks
  within the same second previously produced the *identical* value (see §11).

## 10. Generation Engine (`GenerateSelectedVariations`)

Order of operations:

1. Resolve the RNG seed (§9).
2. `apply_madness(UI_STATE.madness)`.
3. Validate the selected item/take and read+precompute the source notes' and
   CC events' project-time positions **once**, outside the per-generator loop
   (re-querying `MIDI_GetProjTimeFromPPQPos` per generator was a measured
   performance bug in an earlier version).
4. Compute `active_count` from `UI_STATE.toggles`; abort with a message box if
   zero.
5. `reaper.Undo_BeginBlock()`, then loop over `ALL_DEFS`. For each checked
   generator:
   - Create the new MIDI item on the next fixed lane.
   - Run the note remap + `def.fn(...)` + collision resolution + sentinel
     note + `write_notes` **inside its own `pcall`**.
   - On success, keep the lane and record the name in `succeeded`.
   - On failure, `reaper.DeleteTrackMediaItem` the now-empty orphaned item,
     reuse that lane number for the next generator, and record `{name, err}`
     in `failed`.
6. `reaper.Undo_EndBlock()` always runs, regardless of per-generator outcomes.
7. Report: silent on full success, a summary listing `#succeeded/#total` and
   each failure's error message otherwise.

**Do not** re-wrap the whole loop in a single outer `pcall` that swallows
per-generator errors — the per-generator isolation (point 5) is deliberate and
tested; a single generator's edge-case failure must never block the rest of
the batch or leave an orphaned empty item behind.

`I_NUMFIXEDLANES` is only ever **raised** to `max(existing, active_count + 1)`,
never lowered — shrinking it could hide/merge pre-existing content on higher
lanes from a previous run.

## 11. Common Pitfalls (read before editing seed/collision/preset code)

Real bugs found and fixed across this project's audit history, kept here so
they don't get reintroduced:

- **PPQ-relative constants must go through `scale_ticks`.** Several
  generators originally used bare tick literals calibrated for 960 PPQ, which
  silently broke (became inaudible or wildly exaggerated) on any project with
  a different resolution. If you add a new absolute-duration/tolerance
  constant, scale it (§4).
- **`reaper.TimeMap2_timeToBeats` returns `(beat_in_measure, measures, cml,
  fullbeats, cdenom)`** — not `(fullbeats, ...)`. Using the first return value
  where "total beats since project start" was intended silently produced a
  wrong PPQ-per-beat estimate for any item not in the project's first
  measure. Any code deriving `ppqbeat` from `TimeMap2_timeToBeats` must use
  the *4th* return value for a continuous beat count.
- **`os.time()` has 1-second resolution.** Never use it alone as an entropy
  source for anything the user can trigger faster than once per second (the
  "New Seed" button did, and appeared to "count up" instead of randomizing
  when clicked quickly — see §9).
- **`0` is a legitimate value, not a sentinel for "unset."** A seed-value
  guard that treated `0` as "no seed chosen yet" caused `Fixed Seed` to be
  silently ignored whenever the seed happened to be (or was manually set to)
  exactly `0` (§9).
- **A filter that only ever *removes* needs something to reset from.** The
  Instrument Preset system originally filtered directly off `UI_STATE.toggles`
  (the live, already-filtered state), so switching from a restrictive filter
  to a more permissive one could never re-check anything — there was no
  memory of what was true before the first filter ran. Fixed by introducing
  `toggle_baseline` (§8.1).
- **A collision-avoidance pass can fight a generator's actual design.** The
  universal same-pitch overlap resolver (§7) was originally applied
  unconditionally, which silently truncated Ghost Delay's intentionally
  overlapping echoes over a sustained note. Generators whose effect *depends*
  on overlapping output need `skip_collision_resolve = true`.
- **A single `pcall` around the whole generator loop hides which generator
  failed and aborts the rest of the batch.** Per-generator isolation (§10) was
  introduced specifically so one edge case doesn't cost the user the other 23
  variations, and so a failed attempt doesn't leave an empty orphaned item
  behind.
- **Drum Mode bypasses were added generator-by-generator and were incomplete
  more than once.** When adding a new pitch-altering generator, add its
  `CFG.DRUM_MODE` bypass in the same change — don't rely on a later audit to
  catch the omission.
- **Silent name mismatches between presets and `ALL_DEFS`.** Nothing
  validates at runtime that a `toggles`/`allowed` string actually matches a
  generator name — a typo just means that preset quietly does nothing for
  that entry. Cross-check after any rename (§6, §10).

## 12. ReaImGui Version Quirks

- `reaper.ImGui_PushFont(ctx, font, size)` requires the size as a **mandatory
  3rd argument** on current ReaImGui builds; the 2-argument form used up
  through an earlier version threw `expected 3 arguments minimum` and
  prevented the script from opening at all. Always pass the same size used in
  `ImGui_CreateFont`.
- `reaper.ImGui_ChildFlags_None` doesn't exist on older ReaImGui (pre-child-
  flags API); the script guards this with
  `local child_flags = r.ImGui_ChildFlags_None and 0 or false` so it degrades
  to the older boolean-flags calling convention instead of erroring. Keep
  this pattern for any other flag constant that might not exist across the
  ReaImGui versions your users are likely to have installed.

## 13. Testing

There's no REAPER-side automated test; instead, a **stub Reaper API** pattern
is used for regression testing during development:

1. Copy the script to a scratch file and change the specific `local function`
   / `local TABLE` declarations you need to exercise from outside (e.g.
   `GenerateSelectedVariations`, `CFG`, `UI_STATE`, `ALL_DEFS`, `scale_ticks`,
   individual `variation_*` functions, `apply_style_preset`,
   `apply_instrument_preset`) to plain globals, via `sed`. `apply_instrument_
   preset` is forward-declared as `local` with no body — for testing, turn
   that declaration into a plain (non-local) assignment too, or the later
   `function apply_instrument_preset(...)` definition will just populate a
   local your test script can't see.
2. Build a minimal `reaper` table with stub implementations of every REAPER
   API the script calls (`MIDI_GetNote`, `MIDI_InsertNote`,
   `CreateNewMIDIItemInProj`, `TimeMap2_timeToBeats` with the *real* multi-
   return signature — see §11, `ExtState` get/set backed by a Lua table,
   `DeleteTrackMediaItem`, etc.), assign it to `_G.reaper`, then `loadfile()`
   the scratch copy.
3. Drive the exposed functions directly and assert on the results (note
   counts, pitches, CFG values, lane numbers, error/undo call counts, which
   generators ended up checked after a preset...).

This has repeatedly caught real bugs that pure code review missed — every
entry in §11 was found this way, not by manual in-REAPER testing. New
non-trivial changes should get a corresponding stub-driven test rather than
relying on manual in-REAPER verification alone, since `luac -p` only proves
the file parses, not that it behaves correctly. A useful companion check: a
short script that regex-extracts every generator name referenced by
`STYLE_PRESETS`/`INSTRUMENT_PRESETS` and diffs it against `ALL_DEFS` names,
to catch silent typos (§6, §11) — cheap to run after any preset or rename
change.

## 14. Known Architectural Limitations

- **No generator chaining within one generation pass** — every checked
  generator always transforms the untouched source. The documented manual
  workaround (select an already-generated lane and re-run) is a real serial
  chain, but it's outside the engine's single-pass design. A first-class
  "chain" feature would need `GenerateSelectedVariations` to support an
  ordered list of `def.fn` calls per output lane instead of one `def` per
  lane — a significant change to the per-generator loop and to how presets
  express "what to run."
- **`detect_scale` assumes one static key for the whole item** — no
  modulation tracking, no modal/pentatonic output (see §5).
- **CC/pitch-bend copying happens once per active generator**, not once
  total — fine for typical sparse automation, but a source with very dense
  CC data and most/all of the 24 generators enabled will issue proportionally
  more `MIDI_InsertCC` calls.

## 15. Versioning & Changelog

Semantic-ish: a minor bump (`5.x.0`) for new generators/presets/features, a
patch bump (`5.x.y`) for bug fixes only. The `@changelog` block at the top of
the file is the authoritative history — keep it updated in the same commit as
the change, newest entry first. When a change fixes a real bug (as opposed to
adding a feature), consider also adding a line to §11 if the mistake is one a
future change could plausibly repeat.
