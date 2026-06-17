# TODO — claude-sound-alerts

Status: **v1.3.0**. External config engine + adaptive `done` gate + per-session marker +
**shuffle-bag rotation**. Configuration via `~/.claude/sound-alerts.local.conf` (enabled / volume /
doneMode / doneMinSeconds + per-sound `disabled=`) with robust defaults in the script. Distributed
from the public GitHub repo `furesipaolo-design/claude-sound-alerts` (MIT-licensed code). Test
harness: `scripts/test-engine.sh` (16). Pool: **30 sounds** (10 permission · 9 question · 11 done),
all peak-normalized to −1 dBFS. Cross-platform player (afplay / ffplay / mpv / mpg123).

---

## Done
- [x] Config outside the cache + read in `play.sh` (master on/off, volume, per-sound filter).
- [x] Adaptive `done` gate (`doneMode`/`doneMinSeconds`) with per-session marker.
- [x] **v1.2.1 — fix "no sound after restart" regression**: removed the `SA_*='${user_config.*}'`
      injection from the hooks (the token isn't reliably expanded for default values → the hook
      failed before launching `play.sh`). Also dropped the `userConfig` block from `plugin.json`:
      config now only via the conf file + defaults.
- [x] `git init` + GitHub repo + marketplace served from GitHub (no longer from a local path).
- [x] Volume configurable (via the conf file).
- [x] **v1.2.2 — sound audit + 6s cap**: `passed` re-derived from the original (crisp attack);
      `continued` trimmed 2.0s off the head so the "To Be Continued" climax lands within the cap.
      Global playback cap 5s → **6s**. Pre-trim originals saved in `sounds/_originals/done/`.
- [x] **v1.2.3 — +32 new sounds + pool normalization**: added memes from myinstants (10
      permission, 10 question, 12 done; dropped `vinedramatic` duplicate and `rubberduck`).
      `fart`/`whyrunning` head-trimmed for the climax. **Whole pool (42) normalized to −1 dBFS**.
      Leading digital silence stripped.
- [x] **Public release**: repo made public, **MIT** license (code), cross-platform player,
      bilingual README (EN/IT), git history squashed to a clean commit (no email / local paths).
- [x] **v1.3.0 — shuffle-bag rotation + pool trim + audio fixes**: replaced the memoryless
      `RANDOM % N` pick (clustered, starved some clips) with a **shuffle bag** — every sound plays
      once per cycle before any repeat, no immediate repeat across cycles; per-category state in
      `$SOUND_ALERTS_STATE_DIR` (default `/tmp`). Pruned 12 annoying clips (42 → **30**: 10/9/11).
      Fixed `noice` (single-sample spike was blocking loudness: declick + `speechnorm`, −24.6 →
      −13.6 LUFS) and `sorrybro` (trimmed the duplicated second utterance, 4.0s → 1.3s). +2 tests.

## Nice-to-have
- [ ] Further refine the shuffle-bag rotation (tuning / heuristics) — revisit when/if it proves worthwhile.
- [ ] More "of-the-moment" viral variants in the pools (periodic refresh from myinstants).
- [ ] Targeted trim of the >6s clips whose punchline lands after the cap (e.g. `titanicfail`).
- [ ] Submit to the official Anthropic plugin marketplace (separate submission).

## Reminder
- After any change: `commit` + `push`, then `claude plugin update claude-sound-alerts@sound-alerts`
  (and restart to apply the hooks).
