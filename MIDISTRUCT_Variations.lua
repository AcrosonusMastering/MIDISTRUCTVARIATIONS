-- @description MIDISTRUCT Variations
-- @version 4.0.0
-- @author Acrosonus Mastering
-- @copyright Copyright (C) 2026 Acrosonus Mastering. All rights reserved.
-- @license GPLV3
-- @about
--   MIDISTRUCT Variations — Intelligent MIDI Variation Generator
--
--   Analyzes the active MIDI take and creates 8 musical variations:
--     Take 2 · Syncopation       — Rhythmic displacement + groove humanization
--     Take 3 · Smart Velocity    — Beat-aware dynamics + sinusoidal accent curves
--     Take 4 · Octave & Simplify — Intelligent reduction + octave color shifts
--     Take 5 · Strummer          — Chord sweep / arpeggio with organic micro-timing
--     Take 6 · Gate / Staccato   — Aggressive rhythmic pluck transformer
--     Take 7 · Power Harmonizer  — Perfect fifth layering + sub-bass doubling
--     Take 8 · Ghost Delay       — MIDI echo with pitch drift (dub tape delay feel)
--     Take 9 · Melodic Mirror    — Bach-style melodic inversion around pitch axis
--
--   Features:
--     · "Madness Dial" (1–10) scales all algorithm intensities — remembered via ExtState
--     · Strummer organic micro-timing (±random ticks per strum step)
--     · Ghost Delay pitch drift: echoes rise or fall in semitones each repeat
--     · Mirror pitch-fold: out-of-range notes are folded back by octave (not clamped)
--     · CC74 smoothstep filter riser in Take 7
--     · Full undo block + Madness level stamped in every take name
-- @website https://www.instagram.com/acrosonus_mastering_studio/

--------------------------------------------------------------------------------
-- DEFAULT CONFIGURATION
-- All values below are overridden at runtime by apply_madness().
--------------------------------------------------------------------------------

local CFG = {
  MADNESS             = 5,

  -- Syncopation
  SYNC_CHANCE         = 0.30,
  SYNC_HUMANIZE_MAX   = 10,
  SYNC_MICRO_MAX      = 3,

  -- Smart Velocity
  VEL_DOWNBEAT_BOOST  = 1.15,
  VEL_OFFBEAT_CUT     = 0.80,
  VEL_ACCENT_SWING    = 0.08,
  VEL_DOWNBEAT_NEAR   = 0.08,
  VEL_HUMANIZE_MAX    = 4,

  -- Octave & Simplify
  SIMP_REMOVE_CHANCE  = 0.20,
  SIMP_SHORT_BIAS     = 1.6,
  SIMP_OCTAVE_CHANCE  = 0.15,
  SIMP_LEGATO_GLUE    = 0.92,

  -- Strummer
  STRUM_TICK_OFFSET   = 15,
  STRUM_VEL_DECAY     = 0.92,
  STRUM_DIRECTION     = "alternate",  -- "up" | "down" | "alternate"
  STRUM_HUMAN_MAX     = 2,            -- ±ticks of random jitter per strum step

  -- Gate / Staccato
  GATE_DURATION_RATIO = 0.25,
  GATE_VEL_BOOST      = 1.20,
  GATE_MIN_TICKS      = 20,

  -- Power Harmonizer
  HARM_FIFTH_SEMIS    = 7,
  HARM_SUB_SEMIS      = -12,
  HARM_ADD_FIFTH      = true,
  HARM_ADD_SUB        = true,
  HARM_FIFTH_VEL_MULT = 0.80,
  HARM_SUB_VEL_MULT   = 0.70,

  -- CC Automation Riser (written into Power Harmonizer take)
  CC_RISER_ENABLE     = true,
  CC_RISER_NUM        = 74,    -- 74=filter cutoff, 1=modwheel, 11=expression
  CC_RISER_STEPS      = 32,    -- resolution (more steps = smoother curve)
  CC_RISER_START_VAL  = 0,
  CC_RISER_END_VAL    = 127,
  CC_CHANNEL          = 0,     -- MIDI channel (0-based = ch1)

  -- Ghost Delay (NEW in v2.1)
  GHOST_REPEATS       = 3,     -- number of echo copies per original note
  GHOST_INTERVAL_DIV  = 2,     -- interval as 1/N beat (2=eighth, 4=sixteenth, 3=triplet)
  GHOST_VEL_DECAY     = 0.50,  -- velocity multiplier per echo (0.50 = halves each time)
  GHOST_PITCH_DRIFT   = 0,     -- semitones added to each successive echo (0=none, 1=up, -1=down)
  GHOST_KEEP_ORIGINAL = true,  -- keep original notes alongside the echoes

  -- Melodic Mirror (NEW in v2.1)
  MIRROR_AXIS_MODE    = "median", -- "median"=note median pitch | "center"=MIDI mid (60)
  MIRROR_FOLD_OCTAVE  = true,    -- fold out-of-range notes by octave (true) vs hard clamp (false)

  -- Retrograde (NEW in v4)
  RETRO_PORTION       = 0.50,   -- fraction of item (from the end) to retrograde (0.0–1.0)

  -- Ratchet / Stutter (NEW in v4)
  RATCH_CHANCE        = 0.20,   -- probability a long note gets ratcheted
  RATCH_DIVISIONS     = 4,      -- number of sub-notes to split into (2=eighths, 4=16ths, 8=32nds)
  RATCH_VEL_DECAY     = 0.85,   -- velocity multiplier per ratchet step
  RATCH_LONG_BIAS     = 1.5,    -- multiplier: longer notes are more likely to be ratcheted

  -- Steve Reich Phasing (NEW in v4)
  PHASE_GRID_BEATS    = 7,      -- loop pattern every N beats (odd = polymétrique)
  PHASE_OFFSET_TICKS  = 10,     -- additional tick nudge per beat for micro-phasing feel

  -- Chord Shatter (NEW in v4)
  SHAT_CHANCE         = 0.70,   -- probability a chord gets shattered (vs passed through)
  SHAT_STEP_DIV       = 2,      -- step size = ppqbeat / N (2=eighth, 4=sixteenth)
  SHAT_OCTAVE_CHANCE  = 0.20,   -- probability of random octave jump on a shattered note
  SHAT_VEL_DECAY      = 0.90,   -- velocity decay across shatter steps
}

--------------------------------------------------------------------------------
-- MADNESS DIAL
-- Scales every parameter from a calm baseline to full creative chaos.
-- Called once at startup after the user inputs their level.
--------------------------------------------------------------------------------

local function apply_madness(level)
  local t = (level - 1) / 9.0   -- normalize to 0.0 – 1.0

  -- Linear interpolation between calm and chaos extremes
  local function dial(calm, chaos) return calm + (chaos - calm) * t end

  CFG.MADNESS             = level

  -- Syncopation: gentle nudge → massive rhythmic displacement
  CFG.SYNC_CHANCE         = dial(0.10, 0.80)
  CFG.SYNC_HUMANIZE_MAX   = math.floor(dial(3,  30))
  CFG.SYNC_MICRO_MAX      = math.floor(dial(1,  15))

  -- Velocity: subtle shaping → extreme dynamic contrast
  CFG.VEL_DOWNBEAT_BOOST  = dial(1.05, 1.40)
  CFG.VEL_OFFBEAT_CUT     = dial(0.92, 0.50)
  CFG.VEL_ACCENT_SWING    = dial(0.03, 0.20)
  CFG.VEL_HUMANIZE_MAX    = math.floor(dial(2,  15))

  -- Simplification: light cull → aggressive reduction
  CFG.SIMP_REMOVE_CHANCE  = dial(0.05, 0.55)
  CFG.SIMP_SHORT_BIAS     = dial(1.2,  3.0)
  CFG.SIMP_OCTAVE_CHANCE  = dial(0.05, 0.45)
  CFG.SIMP_LEGATO_GLUE    = dial(0.99, 0.70)

  -- Strummer: tight strum → wide, slow sweep arp
  CFG.STRUM_TICK_OFFSET   = math.floor(dial(8,   40))
  CFG.STRUM_VEL_DECAY     = dial(0.98, 0.72)

  -- Gate: moderate cut → extreme micro-staccato pluck
  CFG.GATE_DURATION_RATIO = dial(0.40, 0.08)
  CFG.GATE_VEL_BOOST      = dial(1.10, 1.45)

  -- Harmonizer: polite layers → loud, wall-of-sound unison
  CFG.HARM_FIFTH_VEL_MULT = dial(0.70, 1.00)
  CFG.HARM_SUB_VEL_MULT   = dial(0.50, 0.92)

  -- Strummer humanize: tight → loose organic feel
  CFG.STRUM_HUMAN_MAX     = math.floor(dial(1, 6))

  -- Ghost Delay: short tight echoes → long drifting tape echoes
  CFG.GHOST_REPEATS       = math.floor(dial(2, 5))
  CFG.GHOST_VEL_DECAY     = dial(0.60, 0.35)
  -- Pitch drift activates above Madness 6
  CFG.GHOST_PITCH_DRIFT   = (t >= 0.6) and 1 or 0

  -- Retrograde: partial reverse → full item reverse
  CFG.RETRO_PORTION       = dial(0.15, 1.0)

  -- Ratchet: occasional subdivision → frantic glitch
  CFG.RATCH_CHANCE        = dial(0.08, 0.55)
  CFG.RATCH_DIVISIONS     = math.floor(dial(2, 8))
  CFG.RATCH_VEL_DECAY     = dial(0.95, 0.65)
  CFG.RATCH_LONG_BIAS     = dial(1.2, 3.0)

  -- Phasing: slight metric offset → radical polymetric shift
  CFG.PHASE_GRID_BEATS    = math.floor(dial(7, 3))   -- 7→3 (more dissonant at high madness)
  CFG.PHASE_OFFSET_TICKS  = math.floor(dial(4, 24))

  -- Chord Shatter: tidy arpeggio → chaotic explosion
  CFG.SHAT_CHANCE         = dial(0.30, 0.95)
  CFG.SHAT_STEP_DIV       = math.floor(dial(2, 8))
  CFG.SHAT_OCTAVE_CHANCE  = dial(0.05, 0.50)
  CFG.SHAT_VEL_DECAY      = dial(0.97, 0.70)
end

--------------------------------------------------------------------------------
-- UTILITIES
--------------------------------------------------------------------------------

local function clamp(v, lo, hi)
  return math.max(lo, math.min(hi, v))
end

local function chance(p)
  return math.random() < p
end

local function median_length(notes)
  if #notes == 0 then return 0 end
  local lengths = {}
  for _, n in ipairs(notes) do lengths[#lengths + 1] = n.endppq - n.startppq end
  table.sort(lengths)
  return lengths[math.ceil(#lengths / 2)]
end

local function copy_notes(src)
  local dst = {}
  for i, n in ipairs(src) do
    dst[i] = {
      selected = n.selected, muted = n.muted,
      startppq = n.startppq, endppq = n.endppq,
      chan = n.chan, pitch = n.pitch, vel = n.vel,
    }
  end
  return dst
end

--------------------------------------------------------------------------------
-- MIDI I/O HELPERS
--------------------------------------------------------------------------------

local function read_notes(take)
  local notes, idx = {}, 0
  while true do
    local ok, sel, mut, s, e, ch, p, v = reaper.MIDI_GetNote(take, idx)
    if not ok then break end
    notes[#notes + 1] = { selected=sel, muted=mut, startppq=s, endppq=e, chan=ch, pitch=p, vel=v }
    idx = idx + 1
  end
  return notes
end

local function get_ppq_per_beat(take)
  local pos0     = reaper.MIDI_GetProjTimeFromPPQPos(take, 0)
  local beats    = reaper.TimeMap2_timeToBeats(0, pos0)
  local t1beat   = reaper.TimeMap2_beatsToTime(0, beats + 1, nil)
  local ppq1     = reaper.MIDI_GetPPQPosFromProjTime(take, t1beat)
  if ppq1 <= 0 then ppq1 = 960 end
  return ppq1
end

local function get_item_length_ppq(take, item)
  local len_sec   = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local pos_sec   = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local ppq_start = reaper.MIDI_GetPPQPosFromProjTime(take, pos_sec)
  local ppq_end   = reaper.MIDI_GetPPQPosFromProjTime(take, pos_sec + len_sec)
  return math.max(ppq_end - ppq_start, 0)
end

--------------------------------------------------------------------------------
-- MIDI WRITE HELPERS
-- Uses MIDI_InsertNote and MIDI_InsertCC — confirmed working on REAPER 7.71
-- with takes created by CreateNewMIDIItemInProj.
--------------------------------------------------------------------------------

--- Write notes and optional CC events into a take.
--- Requires: take created by CreateNewMIDIItemInProj (valid MIDI source).
local function write_notes(take, notes, cc_evts)
  reaper.MIDI_DisableSort(take)

  for _, n in ipairs(notes) do
    reaper.MIDI_InsertNote(take,
      n.selected, n.muted,
      n.startppq, n.endppq,
      n.chan, n.pitch, n.vel,
      false)
  end

  if cc_evts then
    for _, cc in ipairs(cc_evts) do
      reaper.MIDI_InsertCC(take,
        false, false,
        cc.ppq, 0xB0, cc.chan, cc.num, cc.val)
    end
  end

  reaper.MIDI_Sort(take)
end

--- Build CC riser event list for Power Harmonizer.
local function build_cc_riser(take, item)
  local total_ppq = get_item_length_ppq(take, item)
  local steps     = CFG.CC_RISER_STEPS
  local range     = CFG.CC_RISER_END_VAL - CFG.CC_RISER_START_VAL
  local cc_evts   = {}
  for i = 0, steps do
    local t        = i / steps
    local smooth_t = t * t * (3 - 2 * t)
    local ppq_pos  = math.floor(total_ppq * t)
    local cc_val   = clamp(math.floor(CFG.CC_RISER_START_VAL + range * smooth_t), 0, 127)
    cc_evts[#cc_evts + 1] = { ppq = ppq_pos, chan = CFG.CC_CHANNEL,
                               num = CFG.CC_RISER_NUM, val = cc_val }
  end
  return cc_evts
end

--------------------------------------------------------------------------------
-- VARIATION 1 · SYNCOPATION
-- Shifts SYNC_CHANCE fraction of notes forward by half a beat.
-- Non-shifted notes receive micro-drift so even the "dry" notes feel human.
--------------------------------------------------------------------------------

local function variation_syncopation(notes, ppqbeat, item_len_ppq)
  local half_beat = ppqbeat / 2

  for _, n in ipairs(notes) do
    local dur = n.endppq - n.startppq
    if chance(CFG.SYNC_CHANCE) then
      local human     = math.random(-CFG.SYNC_HUMANIZE_MAX, CFG.SYNC_HUMANIZE_MAX)
      local new_start = math.max(0, n.startppq + half_beat + human)
      if item_len_ppq then new_start = math.min(new_start, item_len_ppq - 1) end
      n.startppq = new_start
      n.endppq   = item_len_ppq and math.min(new_start + dur, item_len_ppq) or new_start + dur
    else
      local micro    = math.random(-CFG.SYNC_MICRO_MAX, CFG.SYNC_MICRO_MAX)
      n.startppq     = math.max(0, n.startppq + micro)
      n.endppq       = n.startppq + dur
    end
  end

  table.sort(notes, function(a, b) return a.startppq < b.startppq end)
  return notes
end

--------------------------------------------------------------------------------
-- VARIATION 2 · SMART VELOCITY
-- Downbeat/off-beat shaping + sinusoidal swell + humanization.
--------------------------------------------------------------------------------

local function variation_smart_velocity(notes, ppqbeat)
  for _, n in ipairs(notes) do
    local phase  = (n.startppq % ppqbeat) / ppqbeat
    local v      = n.vel

    if phase < CFG.VEL_DOWNBEAT_NEAR or phase > (1.0 - CFG.VEL_DOWNBEAT_NEAR) then
      v = v * CFG.VEL_DOWNBEAT_BOOST   -- on the beat: accent
    else
      v = v * CFG.VEL_OFFBEAT_CUT      -- between beats: soften
    end

    -- Cosine swell: breathes dynamism across each beat subdivision
    local swell = 1.0 + CFG.VEL_ACCENT_SWING * math.cos(phase * 2 * math.pi)
    v = v * swell

    -- Final human imperfection layer
    v = v + math.random(-CFG.VEL_HUMANIZE_MAX, CFG.VEL_HUMANIZE_MAX)
    n.vel = clamp(math.floor(v + 0.5), 1, 127)
  end
  return notes
end

--------------------------------------------------------------------------------
-- VARIATION 3 · OCTAVE & SIMPLIFICATION
-- Weighted removal of short notes + directional octave shift + legato-glue.
--------------------------------------------------------------------------------

local function variation_octave_simplify(notes, ppqbeat)
  local med     = median_length(notes)
  local surv    = {}

  for _, n in ipairs(notes) do
    local len_ratio  = (med > 0) and ((n.endppq - n.startppq) / med) or 1.0
    local prob       = math.min(CFG.SIMP_REMOVE_CHANCE * (CFG.SIMP_SHORT_BIAS / math.max(len_ratio, 0.1)), 0.85)
    if not chance(prob) then surv[#surv + 1] = n end
  end

  if #surv == 0 and #notes > 0 then
    local n = notes[1]
    surv[1] = { selected=n.selected, muted=n.muted,
                startppq=n.startppq, endppq=n.endppq,
                chan=n.chan, pitch=n.pitch, vel=n.vel }
  end

  for _, n in ipairs(surv) do
    if chance(CFG.SIMP_OCTAVE_CHANCE) then
      local dir = (n.pitch < 60) and 1 or -1
      if chance(0.10) then dir = -dir end
      n.pitch = clamp(n.pitch + dir * 12, 0, 127)
    end
  end

  -- Legato-glue: stretch each note towards the next note's start position.
  -- Same-pitch guard: if the next note has the same pitch, leave a 2-tick gap
  -- to prevent note-on/note-off collision artifacts on VSTs.
  table.sort(surv, function(a, b) return a.startppq < b.startppq end)
  for i = 1, #surv - 1 do
    local cur     = surv[i]
    local nxt     = surv[i + 1]
    local gap     = nxt.startppq - cur.startppq
    local new_end = cur.startppq + math.floor(gap * CFG.SIMP_LEGATO_GLUE)
    if new_end > cur.endppq then
      if cur.pitch == nxt.pitch then
        new_end = math.min(new_end, nxt.startppq - 2)
      end
      if new_end > cur.endppq then cur.endppq = new_end end
    end
  end

  return surv
end

--------------------------------------------------------------------------------
-- VARIATION 4 · STRUMMER / ARPEGGIATOR
--
-- Groups simultaneous notes (chords) by PPQ position (±2 tick tolerance).
-- Staggered by STRUM_TICK_OFFSET ticks per step, sorted by pitch.
-- Velocity decays across the sweep for a natural fingerpick/strum feel.
-- Direction alternates per group ("up" / "down") for rhythmic variety.
--------------------------------------------------------------------------------

local function variation_strummer(notes, ppqbeat, item_len_ppq)
  local TOLERANCE = 2
  local groups, used = {}, {}

  table.sort(notes, function(a, b) return a.startppq < b.startppq end)

  for i, n in ipairs(notes) do
    if not used[i] then
      local g = { startppq = n.startppq, notes = { n } }
      used[i] = true
      for j = i + 1, #notes do
        if not used[j] and math.abs(notes[j].startppq - n.startppq) <= TOLERANCE then
          g.notes[#g.notes + 1] = notes[j]
          used[j] = true
        end
      end
      groups[#groups + 1] = g
    end
  end

  local output      = {}
  local group_index = 0

  for _, g in ipairs(groups) do
    group_index = group_index + 1
    local gn    = g.notes

    if #gn <= 1 then
      output[#output + 1] = gn[1]
    else
      local go_up
      if CFG.STRUM_DIRECTION == "up" then
        go_up = true
      elseif CFG.STRUM_DIRECTION == "down" then
        go_up = false
      else
        go_up = (group_index % 2 == 1)
      end

      if go_up then
        table.sort(gn, function(a, b) return a.pitch < b.pitch end)
      else
        table.sort(gn, function(a, b) return a.pitch > b.pitch end)
      end

      for step, n in ipairs(gn) do
        local jitter     = math.random(-CFG.STRUM_HUMAN_MAX, CFG.STRUM_HUMAN_MAX)
        local tick_shift = math.max((step - 1) * CFG.STRUM_TICK_OFFSET + jitter, 0)
        local new_start  = g.startppq + tick_shift

        -- Discard strum steps that land beyond the item boundary
        if item_len_ppq and new_start >= item_len_ppq then break end

        local dur       = n.endppq - n.startppq
        local new_end   = item_len_ppq and math.min(new_start + dur, item_len_ppq)
                                       or  new_start + dur
        local vel_scale = CFG.STRUM_VEL_DECAY ^ (step - 1)

        output[#output + 1] = {
          selected = n.selected, muted = n.muted,
          startppq = new_start,  endppq = new_end,
          chan     = n.chan,     pitch  = n.pitch,
          vel      = clamp(math.floor(n.vel * vel_scale + 0.5), 1, 127),
        }
      end
    end
  end

  table.sort(output, function(a, b) return a.startppq < b.startppq end)
  return output
end

--------------------------------------------------------------------------------
-- VARIATION 5 · GATE / STACCATO
--
-- Cuts every note to GATE_DURATION_RATIO of original length (default: 25%).
-- Boosts velocity to compensate for lost sustain (mimics a hard pluck attack).
-- GATE_MIN_TICKS prevents inaudible sub-threshold note fragments.
--------------------------------------------------------------------------------

local function variation_gate_staccato(notes, ppqbeat)
  for _, n in ipairs(notes) do
    local orig_dur = n.endppq - n.startppq
    local new_dur  = math.max(math.floor(orig_dur * CFG.GATE_DURATION_RATIO), CFG.GATE_MIN_TICKS)
    n.endppq = n.startppq + new_dur
    n.vel    = clamp(math.floor(n.vel * CFG.GATE_VEL_BOOST + 0.5), 1, 127)
  end
  return notes
end

--------------------------------------------------------------------------------
-- VARIATION 6 · POWER HARMONIZER
--
-- Adds a perfect fifth (+7 semis) and sub-bass (-12 semis) copy of each note.
-- The fifth is snapped to the nearest pitch present in the detected scale so
-- it stays diatonic — avoids chromatic clashes in tonal material.
-- Sub-bass is always a clean octave down (no scale dependency needed).
-- A CC74 smoothstep filter riser is written after the notes (optional).
--------------------------------------------------------------------------------

--- Detect the pitch-class set used in the source notes (scale fingerprint).
--- Returns a set table: scale[pitch_class] = true for each class present.
local function detect_scale(notes)
  local scale = {}
  for _, n in ipairs(notes) do
    scale[n.pitch % 12] = true
  end
  return scale
end

--- Snap a pitch to the nearest pitch-class present in the scale.
--- Searches ±6 semitones from the candidate and returns the closest match.
local function snap_to_scale(pitch, scale)
  if scale[pitch % 12] then return pitch end  -- already in scale
  for delta = 1, 6 do
    if scale[(pitch + delta) % 12] then return pitch + delta end
    if scale[(pitch - delta) % 12] then return pitch - delta end
  end
  return pitch  -- fallback: no scale match found, keep as-is
end

local function variation_power_harmonizer(notes, ppqbeat)
  local output = {}
  local scale  = detect_scale(notes)

  for _, n in ipairs(notes) do
    output[#output + 1] = n  -- original note

    if CFG.HARM_ADD_FIFTH then
      local fp_raw = n.pitch + CFG.HARM_FIFTH_SEMIS
      -- Snap the fifth to the nearest scale tone to keep it diatonic
      local fp = snap_to_scale(fp_raw, scale)
      fp = clamp(fp, 0, 127)
      if fp ~= n.pitch then   -- don't add a unison if snap collapsed to original
        output[#output + 1] = {
          selected = n.selected, muted = n.muted,
          startppq = n.startppq, endppq = n.endppq,
          chan     = n.chan,     pitch  = fp,
          vel      = clamp(math.floor(n.vel * CFG.HARM_FIFTH_VEL_MULT + 0.5), 1, 127),
        }
      end
    end

    if CFG.HARM_ADD_SUB then
      local sp = n.pitch + CFG.HARM_SUB_SEMIS
      if sp >= 0 then
        output[#output + 1] = {
          selected = n.selected, muted = n.muted,
          startppq = n.startppq, endppq = n.endppq,
          chan     = n.chan,     pitch  = sp,
          vel      = clamp(math.floor(n.vel * CFG.HARM_SUB_VEL_MULT + 0.5), 1, 127),
        }
      end
    end
  end

  table.sort(output, function(a, b) return a.startppq < b.startppq end)
  return output
end

--------------------------------------------------------------------------------
-- VARIATION 7 · GHOST DELAY
--
-- MIDI echo engine: each original note spawns GHOST_REPEATS copies, each
-- shifted forward by (ppqbeat / GHOST_INTERVAL_DIV) ticks and halved in
-- velocity. Optional pitch drift adds +/-1 semitone per repeat, simulating
-- the warble of an analog tape delay or a pitched send.
--
-- Echoes that would start beyond the item boundary are silently discarded.
-- At Madness 1–5 → tight eighth-note echoes, no pitch drift, clean decay.
-- At Madness 6–10 → up to 5 repeats, velocity crumbles fast, pitch rises.
--------------------------------------------------------------------------------

local function variation_ghost_delay(notes, ppqbeat, item_len_ppq)
  local interval = math.floor(ppqbeat / CFG.GHOST_INTERVAL_DIV)
  local output   = {}

  for _, n in ipairs(notes) do
    if CFG.GHOST_KEEP_ORIGINAL then
      output[#output + 1] = n
    end

    local vel       = n.vel
    local acc_drift = 0

    for rep = 1, CFG.GHOST_REPEATS do
      local echo_start = n.startppq + interval * rep

      -- Test boundary BEFORE computing decay — discard cleanly if out of range
      if item_len_ppq and echo_start >= item_len_ppq then break end

      vel       = vel * CFG.GHOST_VEL_DECAY
      acc_drift = acc_drift + CFG.GHOST_PITCH_DRIFT

      local echo_dur = n.endppq - n.startppq
      echo_dur = math.max(math.floor(echo_dur * (0.9 ^ rep)), 20)
      if item_len_ppq then
        echo_dur = math.min(echo_dur, item_len_ppq - echo_start)
      end

      if echo_dur > 0 then
        output[#output + 1] = {
          selected = false,
          muted    = n.muted,
          startppq = echo_start,
          endppq   = echo_start + echo_dur,
          chan     = n.chan,
          pitch    = clamp(n.pitch + acc_drift, 0, 127),
          vel      = clamp(math.floor(vel + 0.5), 1, 127),
        }
      end
    end
  end

  table.sort(output, function(a, b) return a.startppq < b.startppq end)
  return output
end

--------------------------------------------------------------------------------
-- VARIATION 8 · MELODIC MIRROR  (NEW in v2.1)
--
-- Classic Bach / serial-music technique: reflects every note around a pitch
-- axis so that intervals are inverted (what went up now goes down by the same
-- amount).
--
-- Axis modes:
--   "median" → axis = median pitch of the source material (contextual)
--   "center" → axis = MIDI note 60 (C4), good for fixed-key compositions
--
-- Out-of-range handling (MIRROR_FOLD_OCTAVE = true):
--   Notes below 0 or above 127 are folded back by an octave rather than
--   clamped. This preserves the harmonic interval structure whereas a hard
--   clamp collapses multiple distinct notes onto the same pitch.
--
-- Result: an instant counter-melody or inverted bass line that harmonically
-- mirrors your original — a composition tool you'd normally spend hours on.
--------------------------------------------------------------------------------

local function variation_melodic_mirror(notes, ppqbeat)
  if #notes == 0 then return notes end

  -- Determine the axis pitch
  local axis
  if CFG.MIRROR_AXIS_MODE == "center" then
    axis = 60   -- C4: neutral MIDI center
  else
    -- Median pitch of source notes (musically grounded axis)
    local pitches = {}
    for _, n in ipairs(notes) do pitches[#pitches + 1] = n.pitch end
    table.sort(pitches)
    axis = pitches[math.ceil(#pitches / 2)]
  end

  --- Fold a pitch back into 0–127 by shifting by octaves (preserves interval color)
  local function fold_pitch(p)
    while p < 0   do p = p + 12 end
    while p > 127 do p = p - 12 end
    return p
  end

  for _, n in ipairs(notes) do
    local mirrored = 2 * axis - n.pitch
    if CFG.MIRROR_FOLD_OCTAVE then
      n.pitch = fold_pitch(mirrored)
    else
      n.pitch = clamp(mirrored, 0, 127)
    end
  end

  table.sort(notes, function(a, b)
    if a.startppq ~= b.startppq then return a.startppq < b.startppq end
    return a.pitch < b.pitch
  end)

  -- Deduplicate: remove notes that share the same startppq AND pitch after
  -- inversion + fold (fold can collapse distinct pitches onto the same class).
  local deduped = {}
  local seen    = {}  -- key: "startppq_pitch"
  for _, n in ipairs(notes) do
    local key = n.startppq .. "_" .. n.pitch
    if not seen[key] then
      seen[key] = true
      deduped[#deduped + 1] = n
    end
  end

  return deduped
end

--------------------------------------------------------------------------------
-- VARIATION 9 · RETROGRADE (v4)
--
-- Bach / Messiaen time-reversal: plays the melody backwards.
-- RETRO_PORTION controls how much of the item (from the end) is reversed.
-- At Madness 1 → only the last 15% is flipped (subtle break effect).
-- At Madness 10 → the entire item is mirrored in time.
--
-- Algorithm: find the time span [cutoff, item_end], mirror all notes in it
-- around the midpoint of that span, then sort everything by start time.
-- Notes outside the reversed window are passed through unchanged.
--------------------------------------------------------------------------------

local function variation_retrograde(notes, ppqbeat, item_len_ppq)
  if #notes == 0 or item_len_ppq <= 0 then return notes end

  -- Determine the window to reverse
  local cutoff = math.floor(item_len_ppq * (1.0 - CFG.RETRO_PORTION))
  local span   = item_len_ppq - cutoff   -- PPQ length of the reversed section

  local output = {}

  for _, n in ipairs(notes) do
    if n.startppq < cutoff then
      -- Outside the window: pass through unchanged
      output[#output + 1] = n
    else
      -- Inside the window: mirror around the midpoint of [cutoff, item_len_ppq]
      -- new_end   = cutoff + (item_len_ppq - n.startppq)
      -- new_start = cutoff + (item_len_ppq - n.endppq)
      local dur       = n.endppq - n.startppq
      local new_start = cutoff + (item_len_ppq - n.endppq)
      local new_end   = new_start + dur

      -- Clamp to [cutoff, item_len_ppq]
      new_start = math.max(new_start, cutoff)
      new_end   = math.min(new_end, item_len_ppq)
      if new_end <= new_start then new_end = new_start + 1 end

      output[#output + 1] = {
        selected = n.selected, muted = n.muted,
        startppq = new_start,  endppq = new_end,
        chan = n.chan, pitch = n.pitch, vel = n.vel,
      }
    end
  end

  table.sort(output, function(a, b) return a.startppq < b.startppq end)
  return output
end

--------------------------------------------------------------------------------
-- VARIATION 10 · RATCHET / STUTTER (v4)
--
-- IDM / Trap glitch: long notes are subdivided into rapid-fire bursts.
-- Longer notes are more likely to be ratcheted (RATCH_LONG_BIAS).
-- The number of sub-notes (RATCH_DIVISIONS) and velocity decay per step
-- both scale with Madness — from subtle 2-note splits to 8-way micro-bursts.
--
-- Velocity decays across each ratchet step for a natural "machine gun" feel.
-- Short notes (below median) are passed through unchanged.
--------------------------------------------------------------------------------

local function variation_ratchet(notes, ppqbeat)
  local med    = median_length(notes)
  local output = {}

  for _, n in ipairs(notes) do
    local dur = n.endppq - n.startppq

    -- Probability of ratcheting scales with note length vs median
    local len_ratio  = (med > 0) and (dur / med) or 1.0
    local ratch_prob = CFG.RATCH_CHANCE * math.min(len_ratio * CFG.RATCH_LONG_BIAS, 4.0)

    if dur < ppqbeat / 4 or not chance(ratch_prob) then
      -- Too short or not selected: pass through
      output[#output + 1] = n
    else
      -- Subdivide into RATCH_DIVISIONS equal sub-notes
      local divs     = math.max(2, CFG.RATCH_DIVISIONS)
      local sub_dur  = math.floor(dur / divs)
      if sub_dur < 10 then sub_dur = 10 end

      for step = 0, divs - 1 do
        local sub_start = n.startppq + step * sub_dur
        local sub_end   = sub_start + sub_dur

        -- Last sub-note fills remaining duration for clean alignment
        if step == divs - 1 then sub_end = n.endppq end

        local vel_scale = CFG.RATCH_VEL_DECAY ^ step
        output[#output + 1] = {
          selected = n.selected, muted = n.muted,
          startppq = sub_start,  endppq = sub_end,
          chan = n.chan, pitch = n.pitch,
          vel  = clamp(math.floor(n.vel * vel_scale + 0.5), 1, 127),
        }
      end
    end
  end

  table.sort(output, function(a, b) return a.startppq < b.startppq end)
  return output
end

--------------------------------------------------------------------------------
-- VARIATION 11 · STEVE REICH PHASING (v4)
--
-- Polymetric phasing: notes are relocated onto a repeating grid of N beats
-- where N is odd or prime (PHASE_GRID_BEATS). This creates a Reichian phase
-- relationship — the pattern drifts against a 4/4 grid and never realigns
-- until lcm(N, bar_length) beats have passed.
--
-- A micro tick-nudge (PHASE_OFFSET_TICKS × beat_number) adds a subtle
-- acceleration/deceleration feel across the item, referencing Reich's actual
-- technique of gradually speeding up one tape loop vs another.
--
-- Pitch and velocity are preserved exactly — only timing changes.
-- Madness controls grid size (7→3 beats) and nudge depth.
--------------------------------------------------------------------------------

local function variation_reich_phasing(notes, ppqbeat, item_len_ppq)
  if #notes == 0 then return notes end

  local grid_ppq  = ppqbeat * CFG.PHASE_GRID_BEATS   -- one phase cycle in PPQ
  local output    = {}

  for _, n in ipairs(notes) do
    local dur = n.endppq - n.startppq

    -- Find which phase cycle this note falls in
    local cycle       = math.floor(n.startppq / grid_ppq)
    local pos_in_grid = n.startppq % grid_ppq

    -- Beat index within the cycle (for nudge calculation)
    local beat_in_cycle = math.floor(pos_in_grid / ppqbeat)

    -- Apply micro-nudge that accumulates per beat (Reich acceleration feel)
    local nudge     = beat_in_cycle * CFG.PHASE_OFFSET_TICKS
    local new_start = cycle * grid_ppq + pos_in_grid + nudge
    local new_end   = new_start + dur

    -- Wrap if beyond item boundary
    if item_len_ppq and item_len_ppq > 0 then
      new_start = new_start % item_len_ppq
      new_end   = new_start + dur
      if new_end > item_len_ppq then new_end = item_len_ppq end
    end

    if new_end > new_start then
      output[#output + 1] = {
        selected = n.selected, muted = n.muted,
        startppq = new_start,  endppq = new_end,
        chan = n.chan, pitch = n.pitch, vel = n.vel,
      }
    end
  end

  table.sort(output, function(a, b) return a.startppq < b.startppq end)
  return output
end

--------------------------------------------------------------------------------
-- VARIATION 12 · CHORD SHATTER (v4)
--
-- Explodes chords into melodic arpeggios — the complement of Strummer.
-- Where Strummer nudges notes slightly, Shatter disperses them fully across
-- the grid, optionally adding random octave jumps for a "deconstructed" feel.
--
-- Algorithm:
--   1. Group simultaneous notes (±2 tick tolerance) — same as Strummer.
--   2. Keep the lowest note (bass) on the original beat.
--   3. Scatter remaining notes onto successive grid steps (ppqbeat / SHAT_STEP_DIV).
--   4. At Madness 6+, random octave jumps (±1 octave) add harmonic color.
--   5. Velocity decays across the arpeggio steps.
--
-- At Madness 1: clean eighth-note arpeggio, no octave jumps.
-- At Madness 10: 1/8th-note steps, 50% octave jump chance, fast decay.
--------------------------------------------------------------------------------

local function variation_chord_shatter(notes, ppqbeat, item_len_ppq)
  local TOLERANCE = 2
  local groups, used = {}, {}

  table.sort(notes, function(a, b) return a.startppq < b.startppq end)

  for i, n in ipairs(notes) do
    if not used[i] then
      local g = { startppq = n.startppq, notes = { n } }
      used[i] = true
      for j = i + 1, #notes do
        if not used[j] and math.abs(notes[j].startppq - n.startppq) <= TOLERANCE then
          g.notes[#g.notes + 1] = notes[j]
          used[j] = true
        end
      end
      groups[#groups + 1] = g
    end
  end

  local step_ppq = math.max(math.floor(ppqbeat / CFG.SHAT_STEP_DIV), 10)
  local output   = {}

  for _, g in ipairs(groups) do
    local gn = g.notes

    if #gn <= 1 or not chance(CFG.SHAT_CHANCE) then
      -- Single note or not selected: pass through unchanged
      for _, n in ipairs(gn) do output[#output + 1] = n end
    else
      -- Sort low-to-high: keep bass on the beat
      table.sort(gn, function(a, b) return a.pitch < b.pitch end)

      for step, n in ipairs(gn) do
        local new_start = g.startppq + (step - 1) * step_ppq
        local dur       = n.endppq - n.startppq

        -- Clamp to item boundary
        if item_len_ppq and new_start >= item_len_ppq then break end
        local new_end = item_len_ppq and math.min(new_start + dur, item_len_ppq)
                                     or  new_start + dur

        -- Optional octave jump on non-bass notes (step > 1)
        local pitch = n.pitch
        if step > 1 and chance(CFG.SHAT_OCTAVE_CHANCE) then
          local oct_dir = chance(0.5) and 12 or -12
          local jumped  = pitch + oct_dir
          if jumped >= 0 and jumped <= 127 then pitch = jumped end
        end

        local vel_scale = CFG.SHAT_VEL_DECAY ^ (step - 1)
        output[#output + 1] = {
          selected = n.selected, muted = n.muted,
          startppq = new_start,  endppq = new_end,
          chan = n.chan, pitch = pitch,
          vel  = clamp(math.floor(n.vel * vel_scale + 0.5), 1, 127),
        }
      end
    end
  end

  table.sort(output, function(a, b) return a.startppq < b.startppq end)
  return output
end

--------------------------------------------------------------------------------
-- EXTSTATE — persist Madness Dial value across sessions
--------------------------------------------------------------------------------

local EXT_SECTION = "AcrosonusMastering"
local EXT_KEY     = "MIDISTRUCT_madness"

local function load_last_madness()
  local val = reaper.GetExtState(EXT_SECTION, EXT_KEY)
  local n   = tonumber(val)
  if n and n >= 1 and n <= 10 then return math.floor(n) end
  return 5   -- factory default
end

local function save_last_madness(level)
  reaper.SetExtState(EXT_SECTION, EXT_KEY, tostring(level), true)  -- true = persist to disk
end

--------------------------------------------------------------------------------
-- MADNESS DIAL DIALOG
-- Pre-fills with the last used value retrieved from REAPER's ExtState store.
-- Returns level (1–10) or nil if the user cancelled.
--------------------------------------------------------------------------------

local function ask_madness_level()
  local last = load_last_madness()   -- remembered from previous run

  local ok, raw = reaper.GetUserInputs(
    "MIDISTRUCT Variations v4  |  Acrosonus Mastering",
    1,
    string.format("Madness Dial  (1 = subtle    10 = chaos)  [last: %d]:", last),
    tostring(last)                   -- pre-fill with last used value
  )
  if not ok then return nil end

  local level = tonumber(raw)
  if not level or level ~= level then  -- NaN guard
    reaper.MB("Please enter a number between 1 and 10.", "MIDISTRUCT Variations", 0)
    return nil
  end
  level = math.floor(clamp(level, 1, 10))
  save_last_madness(level)           -- persist for next run
  return level
end

--------------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------------

local function main()
  math.randomseed(os.time() + math.floor(reaper.time_precise() * 100000))
  for _ = 1, 10 do math.random() end

  local madness = ask_madness_level()
  if not madness then return end
  apply_madness(madness)

  local item = reaper.GetSelectedMediaItem(0, 0)
  if not item then
    reaper.MB("No media item selected.\n\nSelect a MIDI item and run again.",
      "MIDISTRUCT Variations", 0); return
  end

  local src_take = reaper.GetActiveTake(item)
  if not src_take or not reaper.TakeIsMIDI(src_take) then
    reaper.MB("Active take is not MIDI.\n\nSelect a MIDI item and run again.",
      "MIDISTRUCT Variations", 0); return
  end

  local src_notes = read_notes(src_take)
  if #src_notes == 0 then
    reaper.MB("No notes found in the active take.\n\nAdd some notes and run again.",
      "MIDISTRUCT Variations", 0); return
  end

  reaper.Undo_BeginBlock()

  local track     = reaper.GetMediaItemTrack(item)
  local item_pos  = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len  = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

  -- Enable Fixed Item Lanes on the source track so all variations
  -- appear as stacked lanes rather than overlapping items.
  -- I_FOLDERDEPTH is irrelevant here — we stay on one track.
  reaper.SetMediaTrackInfo_Value(track, "I_NUMFIXEDLANES", 13)  -- 1 original + 12 variations

  -- Pin the original item to lane 0 explicitly
  reaper.SetMediaItemInfo_Value(item, "I_FIXEDLANE", 0)

  local defs = {
    { name = "Syncopation",       fn = variation_syncopation },
    { name = "Smart Velocity",    fn = variation_smart_velocity },
    { name = "Octave & Simplify", fn = variation_octave_simplify },
    { name = "Strummer",          fn = variation_strummer },
    { name = "Gate / Staccato",   fn = variation_gate_staccato },
    { name = "Power Harmonizer",  fn = variation_power_harmonizer,
      cc_builder = function(take, it) return build_cc_riser(take, it) end },
    { name = "Ghost Delay",       fn = variation_ghost_delay },
    { name = "Melodic Mirror",    fn = variation_melodic_mirror },
    { name = "Retrograde",        fn = variation_retrograde },
    { name = "Ratchet / Stutter", fn = variation_ratchet },
    { name = "Reich Phasing",     fn = variation_reich_phasing },
    { name = "Chord Shatter",     fn = variation_chord_shatter },
  }

  for i, def in ipairs(defs) do
    -- Create variation item on the SAME track as the original
    local new_item = reaper.CreateNewMIDIItemInProj(track, item_pos, item_pos + item_len, false)
    if not new_item then
      reaper.MB("Failed to create item for: " .. def.name, "MIDISTRUCT", 0)
    else
      -- Assign to lane i (1-8), original is on lane 0
      reaper.SetMediaItemInfo_Value(new_item, "I_FIXEDLANE", i)
      reaper.SetMediaItemInfo_Value(new_item, "B_LOOPSRC", 0)

      local new_take = reaper.GetActiveTake(new_item)
      reaper.GetSetMediaItemTakeInfo_String(new_take, "P_NAME",
        string.format("%s  [M%d]", def.name, madness), true)

      -- ── ABSOLUTE TIME CONVERSION (source PPQ → project time → target PPQ) ──
      -- The source MIDI file may have a different PPQ resolution than REAPER's
      -- default (e.g. 480 PPQ imported .mid vs 960 PPQ new items). Copying raw
      -- PPQ values directly causes all notes to be compressed to the left.
      -- Fix: convert each note position via absolute project time as the bridge.
      local mapped_notes = {}
      local max_end_ppq  = 0

      for _, n in ipairs(src_notes) do
        local proj_start = reaper.MIDI_GetProjTimeFromPPQPos(src_take, n.startppq)
        local proj_end   = reaper.MIDI_GetProjTimeFromPPQPos(src_take, n.endppq)
        local m_start    = math.floor(reaper.MIDI_GetPPQPosFromProjTime(new_take, proj_start) + 0.5)
        local m_end      = math.floor(reaper.MIDI_GetPPQPosFromProjTime(new_take, proj_end)   + 0.5)
        if m_end <= m_start then m_end = m_start + 1 end
        mapped_notes[#mapped_notes + 1] = {
          selected = n.selected, muted = n.muted,
          startppq = m_start, endppq = m_end,
          chan = n.chan, pitch = n.pitch, vel = n.vel,
        }
        if m_end > max_end_ppq then max_end_ppq = m_end end
      end

      -- PPQ metrics for the new item (REAPER default 960 PPQ)
      local new_ppqbeat      = get_ppq_per_beat(new_take)
      local new_item_len_ppq = get_item_length_ppq(new_take, new_item)
      local sentinel_ppq     = max_end_ppq + new_ppqbeat  -- 1 beat margin

      -- Apply variation algorithm on correctly-mapped notes
      local notes   = def.fn(mapped_notes, new_ppqbeat, new_item_len_ppq)
      local cc_evts = def.cc_builder and def.cc_builder(new_take, new_item) or nil

      -- Sentinel note to anchor MIDI source length to full item duration
      notes[#notes + 1] = {
        selected = false, muted = true,
        startppq = math.max(sentinel_ppq - 1, 0),
        endppq   = sentinel_ppq,
        chan = 0, pitch = 0, vel = 1,
      }

      write_notes(new_take, notes, cc_evts)

      reaper.SetMediaItemInfo_Value(new_item, "D_LENGTH", item_len)
      reaper.UpdateItemInProject(new_item)
    end
  end

  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(item, true)
  reaper.Undo_EndBlock(
    string.format("MIDISTRUCT Variations v4 — 12 fixed lanes, Madness %d", madness), -1)
  reaper.UpdateArrange()

  local cc_line    = CFG.CC_RISER_ENABLE
    and ("\n  + CC" .. CFG.CC_RISER_NUM .. " filter riser") or ""
  local drift_line = (CFG.GHOST_PITCH_DRIFT ~= 0)
    and string.format("  (pitch drift: %+d semi/echo)", CFG.GHOST_PITCH_DRIFT) or ""

  reaper.MB(
    string.format(
      "MIDISTRUCT Variations v4  |  Madness: %d / 10\n\n"
      .. "12 variations created as Fixed Lanes on your track:\n\n"
      .. "  Lane 0   Original (unchanged)\n"
      .. "  Lane 1   Syncopation\n"
      .. "  Lane 2   Smart Velocity\n"
      .. "  Lane 3   Octave & Simplify\n"
      .. "  Lane 4   Strummer\n"
      .. "  Lane 5   Gate / Staccato\n"
      .. "  Lane 6   Power Harmonizer%s\n"
      .. "  Lane 7   Ghost Delay%s\n"
      .. "  Lane 8   Melodic Mirror  (axis: %s)\n"
      .. "  Lane 9   Retrograde  (%.0f%% of item reversed)\n"
      .. "  Lane 10  Ratchet / Stutter\n"
      .. "  Lane 11  Reich Phasing  (grid: %d beats)\n"
      .. "  Lane 12  Chord Shatter\n\n"
      .. "Click lane headers to solo/mute.\n"
      .. "Use REAPER's comp tool to build a composite from all lanes.",
      madness, cc_line, drift_line, CFG.MIRROR_AXIS_MODE,
      CFG.RETRO_PORTION * 100,
      CFG.PHASE_GRID_BEATS
    ),
    "MIDISTRUCT Variations  |  Acrosonus Mastering", 0
  )
end

main()
