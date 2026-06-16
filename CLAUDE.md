# Claude Sound Alerts — CLAUDE.md

A plugin for **Claude Code** that fires a meme sound effect when Claude stops (permission / question / done), so you can work in **auto mode** without staring at the screen. Current version: **v1.3.0**.

## Orientation

- **3 events → 3 hooks**: `Notification`/`permission_prompt` (permission) · `PreToolUse`+`AskUserQuestion` (question) · `Stop` (done). Anti-duplicate via an **adaptive "done" gate** (if a permission/question alert played recently, the "done" sound is suppressed).
- **Config**: a single file **`~/.claude/sound-alerts.local.conf`** (enabled / volume / doneMode / doneMinSeconds + `disabled=<cat>/<file>`) with robust defaults in the script. It lives **OUTSIDE the plugin cache**, so it survives reinstalls. *(v1.2.0 used native `userConfig` injected into the hooks via `${user_config.*}`: removed in v1.2.1 because the token doesn't expand for default values and broke the hooks → "no sound after restart".)*
- **Execution**: runs from the plugin cache (`${CLAUDE_PLUGIN_ROOT}`), not from the source tree. The player runs in the background, never blocking (6s cap). Cross-platform: `afplay` (macOS) → `ffplay`/`mpv`/`mpg123` (Linux) → silent if none is found.
- **Rotation** (v1.3.0): a **shuffle bag**, not plain random — every sound in a category plays once before any repeats (state per-category in `$SOUND_ALERTS_STATE_DIR`, default `/tmp/claude-sound-alerts.bag.<cat>`), avoiding immediate repeats across cycle boundaries. Replaced the old memoryless `RANDOM % N` that clustered and starved some clips.
- **Key files**: `hooks/`, `scripts/play.sh`, `sounds/<permission|question|done>/`, `README.md`, `TODO.md`, `sound-alerts.local.conf.example`, `settings-snippet.json` (no-plugin fallback).
- Public **GitHub repo** (code under MIT; the audio are third-party meme clips, see README). `docs/`, `sounds/_originals/` and internal notes are **gitignored** (out of the repo).
