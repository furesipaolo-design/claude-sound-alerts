# 🔊 claude-sound-alerts

**English** · [Italiano](#-claude-sound-alerts--italiano)

A plugin for **Claude Code** that fires a **viral meme sound effect** every time Claude stops — so, while working in **auto mode**, you notice it without staring at the screen. Three situations, three distinct sound families (each a **shuffle-bag** pool — every sound plays once before any repeats, so they don't get old).

## What plays, and when

| Situation | When it fires | Hook | Sound pool |
|---|---|---|---|
| 🟡 **Needs permission** | Claude stops waiting for your approval | `Notification` / `permission_prompt` | vine boom · bruh · emotional damage · FAHHH · dramatic fart · GTA wasted · no god please no · just do it · alerta · titanic flute fail |
| 🔵 **Question** | Claude uses the multiple-choice question tool | `PreToolUse` / `AskUserQuestion` | huh? · what? · sus · mario jump · a few moments later · his name is Jeff · crickets · sorry bro · pause that |
| 🟢 **Done** | Claude finished its turn and hands you back control | `Stop` | GTA mission passed · to be continued · wow · heavenly music · turn down for what · monte · pretty good · hehe boi · easy · noice · abrakadabra |

Why these three triggers: in auto mode Claude doesn't stop between tools, so **Stop** coincides with the real "I'm done"; **permission** and **question** are the only other moments when you actually need to get back to the keyboard.

> **Anti-duplicate**: when Claude stops for a permission or a question, **Stop** can fire *too*. The script keeps a per-session marker (`/tmp/claude-sound-alerts.<session>.last`): if a permission/question alert played in the last 4 seconds, the "done" sound is skipped. No fanfare glued onto the question.
>
> "Done" also has a **duration gate** (see [Configuration](#configuration)): by default it only plays if the turn lasted long enough, so in auto mode it fires but on short chat replies it stays quiet.

Each sound is capped at **6 seconds** and runs in the **background**: it never slows Claude down.

## Requirements

- **macOS**: works out-of-the-box (uses `afplay`, included with the system).
- **Linux**: needs a command-line player among `ffplay` (the `ffmpeg` package), `mpv` or `mpg123`. Without any of these the plugin still installs but stays silent, **without errors**.
- **Windows**: not supported (no player detected → silent).
- The sounds are `.mp3` files bundled in `sounds/`: works **offline**, no runtime download.

## Installation

### Option A — persistent install (recommended)
From inside Claude Code (slash command):
```
/plugin marketplace add furesipaolo-design/claude-sound-alerts
/plugin install claude-sound-alerts@sound-alerts
/reload-plugins
```
Or from the terminal:
```bash
claude plugin marketplace add furesipaolo-design/claude-sound-alerts
claude plugin install claude-sound-alerts@sound-alerts
```
Verify with `/hooks` (you should see UserPromptSubmit/Notification/PreToolUse/Stop) or `/plugin list`.
What changes on disk: entries in `~/.claude/settings.json` (`extraKnownMarketplaces` + `enabledPlugins`). Reversible with `/plugin uninstall`.

### Option B — quick try from a local clone (one session, touches nothing)
```bash
git clone https://github.com/furesipaolo-design/claude-sound-alerts.git
claude --plugin-dir ./claude-sound-alerts
```

### Option C — without the plugin system (direct hooks)
If you'd rather not use the plugin system, copy the `hooks` block from [`settings-snippet.json`](settings-snippet.json) into `~/.claude/settings.json` (merge), replacing `PLUGIN_DIR` with the real path.

## Try the sounds
```bash
./scripts/test-sounds.sh        # plays every effect, category by category
./scripts/play.sh permission    # one random sound from the "permission" category
```

## Configuration

All options are **optional**: with no configuration the plugin runs on defaults (sounds on, full volume, "done" only for turns ≥ 15s). To customize, create `~/.claude/sound-alerts.local.conf` (start from [`sound-alerts.local.conf.example`](sound-alerts.local.conf.example)). The file lives **outside the plugin cache** — it survives reinstalls/updates — and takes effect **on the fly**: no restart needed.

| Key | Values | Default | Effect |
|---|---|---|---|
| `enabled` | `true`/`false` | `true` | Master on/off for all sounds |
| `volume` | `0.0`–`1.0` | `1.0` | Volume |
| `doneMode` | `worked`/`always` | `worked` | `worked`: "done" only plays if the turn lasted ≥ `doneMinSeconds` (quiet on small talk, perfect in auto mode). `always`: every turn end. |
| `doneMinSeconds` | integer | `15` | Minimum turn duration in `worked` mode |
| `disabled` | `<cat>/<file>` or `<cat>` | — | **Turns off a single sound** (`disabled=question/sus`) or a whole category (`disabled=done`). Repeatable. |

Check the engine without playing anything: `./scripts/test-engine.sh`.

> **Note (v1.2.1):** v1.2.0 tried to expose these options as native plugin settings (`userConfig`) by injecting them into the hooks via `${user_config.*}`. That token doesn't expand reliably — especially for default values — and made the whole hook fail → **no sound after a restart**. v1.2.1 removes it: configuration lives only in the file above, with robust defaults in the script.

## Customizing
- **Change/add sounds**: drop an `.mp3` into the category folder (`sounds/permission|question/done`). They're picked at random, no other step.
- **Remove a sound**: delete the `.mp3`.
- **Max duration**: the `CAP` variable in [`scripts/play.sh`](scripts/play.sh).
- **Anti-duplicate window**: the `4` in `scripts/play.sh` (seconds).

## Structure
```
claude-sound-alerts/
├── .claude-plugin/
│   ├── plugin.json          # plugin manifest
│   └── marketplace.json     # catalog (makes the plugin installable)
├── hooks/
│   └── hooks.json           # the 4 hooks → UserPromptSubmit (turn start) + play.sh <category>
├── scripts/
│   ├── play.sh              # picks a random sound and plays it (config, gate, anti-duplicate)
│   ├── lib-config.sh        # shared config-reading functions (conf file + defaults)
│   ├── turn-start.sh        # records the turn start (UserPromptSubmit hook) for the gate
│   ├── test-engine.sh       # checks the engine in DRY_RUN (no sound)
│   └── test-sounds.sh       # audio preview
├── sounds/
│   ├── permission/  question/  done/
│   └── _originals/          # backup of pre-editing sounds (out of the pool, gitignored)
├── sound-alerts.local.conf.example   # user config template
└── settings-snippet.json    # no-plugin fallback
```

## Note: local vs remote
If Claude Code runs locally on your machine (VS Code extension or CLI), the sounds play there — all good. If instead you use it on a **remote** machine (SSH, dev container, Codespaces, web), the player would run **there**, not on your computer: in that case you wouldn't hear anything in your headphones (you'd need a local-side trigger).

## License
The **code** (scripts, hooks, manifests, configuration) is released under the **MIT** license — see [LICENSE](LICENSE).

## Credits & sound sources
The effects are short meme clips taken from **[myinstants.com](https://www.myinstants.com)**, where they are freely accessible and shared by the community. Many derive from third-party works and trademarks (e.g. *GTA*, *Taco Bell*, *Among Us*, *Mortal Kombat*, *Titanic*, *Formula 1* and various memes/creators): **all rights remain with their respective owners**. They are bundled for **demonstrative, non-commercial, personal entertainment** purposes only.

> ⚠️ The MIT license covers **the code only**, not the audio files. If you hold the rights to a clip and want it removed, open an *issue*: we'll take it down right away.

<br>

---

<br>

# 🔊 claude-sound-alerts — Italiano

[English](#-claude-sound-alerts) · **Italiano**

Plugin per **Claude Code** che spara un **effetto sonoro meme virale** ogni volta che Claude si ferma — così, lavorando in **auto mode**, te ne accorgi senza fissare lo schermo. Tre situazioni, tre famiglie di suoni distinte (un pool **shuffle-bag** per ognuna — ogni suono esce una volta prima di ripetersi, così non stancano).

## Cosa suona, e quando

| Situazione | Quando scatta | Hook | Pool di suoni |
|---|---|---|---|
| 🟡 **Serve un permesso** | Claude si ferma perché aspetta una tua approvazione | `Notification` / `permission_prompt` | vine boom · bruh · emotional damage · FAHHH · dramatic fart · GTA wasted · no god please no · just do it · alerta · titanic flute fail |
| 🔵 **Domanda (questionario)** | Claude usa lo strumento di domanda a scelta multipla | `PreToolUse` / `AskUserQuestion` | huh? · what? · sus · mario jump · a few moments later · his name is Jeff · crickets · sorry bro · pause that |
| 🟢 **Completato** | Claude ha finito il turno e ti ridà la palla | `Stop` | GTA mission passed · to be continued · wow · heavenly music · turn down for what · monte · pretty good · hehe boi · easy · noice · abrakadabra |

Perché proprio questi tre trigger: in auto mode Claude non si ferma tra un tool e l'altro, quindi lo **Stop** coincide con il vero "ho finito"; il **permesso** e la **domanda** sono gli unici altri momenti in cui ti serve davvero tornare alla tastiera.

> **Anti-doppione**: quando Claude si ferma per un permesso o una domanda può scattare *anche* lo Stop. Lo script tiene un marcatore per-sessione (`/tmp/claude-sound-alerts.<sessione>.last`): se un alert permesso/domanda è suonato negli ultimi 4 secondi, il suono di "completato" viene saltato. Niente fanfara appiccicata alla domanda.
>
> Il "completato" ha anche un **gate sulla durata** (vedi [Configurazione](#configurazione)): di default suona solo se il turno è durato abbastanza, così in auto-mode parte ma sulle risposte brevi in chat resta zitto.

Ogni suono è limitato a **6 secondi** e parte in **background**: non rallenta mai Claude.

## Requisiti

- **macOS**: funziona out-of-the-box (usa `afplay`, incluso nel sistema).
- **Linux**: serve un player da terminale tra `ffplay` (pacchetto `ffmpeg`), `mpv` o `mpg123`. Senza nessuno di questi il plugin si installa lo stesso ma resta muto, **senza dare errori**.
- **Windows**: non supportato (nessun player rilevato → muto).
- I suoni sono `.mp3` inclusi in `sounds/`: funziona **offline**, niente download a runtime.

## Installazione

### Opzione A — installazione persistente (consigliata)
Da dentro Claude Code (slash command):
```
/plugin marketplace add furesipaolo-design/claude-sound-alerts
/plugin install claude-sound-alerts@sound-alerts
/reload-plugins
```
Oppure da terminale:
```bash
claude plugin marketplace add furesipaolo-design/claude-sound-alerts
claude plugin install claude-sound-alerts@sound-alerts
```
Verifica con `/hooks` (devono comparire UserPromptSubmit/Notification/PreToolUse/Stop) o `/plugin list`.
Cosa cambia su disco: voci in `~/.claude/settings.json` (`extraKnownMarketplaces` + `enabledPlugins`). Reversibile con `/plugin uninstall`.

### Opzione B — prova al volo da una clone locale (una sessione, non tocca niente)
```bash
git clone https://github.com/furesipaolo-design/claude-sound-alerts.git
claude --plugin-dir ./claude-sound-alerts
```

### Opzione C — senza plugin (hook diretti)
Se preferisci non usare il sistema-plugin, copia il blocco `hooks` da [`settings-snippet.json`](settings-snippet.json) dentro `~/.claude/settings.json` (merge), sostituendo `PLUGIN_DIR` col path reale.

## Provare i suoni
```bash
./scripts/test-sounds.sh        # riproduce tutti gli effetti, categoria per categoria
./scripts/play.sh permission    # un suono a caso dalla categoria "permesso"
```

## Configurazione

Tutte le opzioni sono **opzionali**: senza configurazione il plugin gira sui default (suoni attivi, volume pieno, "completato" solo per turni ≥ 15s). Per personalizzare crea `~/.claude/sound-alerts.local.conf` (parti da [`sound-alerts.local.conf.example`](sound-alerts.local.conf.example)). Il file vive **fuori dalla cache** del plugin — sopravvive a reinstall/update — e vale **al volo**: nessun restart.

| Chiave | Valori | Default | Effetto |
|---|---|---|---|
| `enabled` | `true`/`false` | `true` | Master on/off di tutti i suoni |
| `volume` | `0.0`–`1.0` | `1.0` | Volume |
| `doneMode` | `worked`/`always` | `worked` | `worked`: il "completato" suona solo se il turno è durato ≥ `doneMinSeconds` (silenzioso sulle chiacchiere, perfetto in auto-mode). `always`: a ogni fine turno. |
| `doneMinSeconds` | intero | `15` | Durata minima del turno in modalità `worked` |
| `disabled` | `<cat>/<file>` o `<cat>` | — | **Spegne un singolo suono** (`disabled=question/sus`) o un'intera categoria (`disabled=done`). Ripetibile. |

Verifica il motore senza suonare: `./scripts/test-engine.sh`.

> **Nota (v1.2.1):** la 1.2.0 provava a esporre queste opzioni come *impostazioni native* del plugin (`userConfig`) iniettandole negli hook via `${user_config.*}`. Quel token non si espande in modo affidabile — soprattutto sui valori di default — e faceva fallire l'esecuzione dell'intero hook → **nessun suono dopo un riavvio**. La 1.2.1 lo rimuove: la configurazione vive solo nel file qui sopra, con default robusti nello script.

## Personalizzare
- **Cambiare/aggiungere suoni**: butta un `.mp3` nella cartella della categoria (`sounds/permission|question/done`). Vengono pescati a caso, nessun altro passo.
- **Togliere un suono**: cancella l'`.mp3`.
- **Durata massima**: variabile `CAP` in [`scripts/play.sh`](scripts/play.sh).
- **Finestra anti-doppione**: il `4` in `scripts/play.sh` (secondi).

## Nota: locale vs remoto
Se Claude Code gira in locale sulla tua macchina (estensione VS Code o CLI), i suoni partono lì, tutto ok. Se invece lo usi su una macchina **remota** (SSH, dev container, Codespaces, web), il player girerebbe **là**, non sul tuo computer: in quel caso non sentiresti nulla in cuffia (servirebbe un trigger lato locale).

## Licenza
Il **codice** (script, hook, manifest, configurazione) è rilasciato sotto licenza **MIT** — vedi [LICENSE](LICENSE).

## Crediti & fonti dei suoni
Gli effetti sono brevi clip meme prese da **[myinstants.com](https://www.myinstants.com)**, dove sono liberamente accessibili e condivise dalla community. Molte derivano da opere e marchi di terzi (es. *GTA*, *Taco Bell*, *Among Us*, *Mortal Kombat*, *Titanic*, *Formula 1* e vari meme/creator): **tutti i diritti restano dei rispettivi proprietari**. Sono inclusi a solo scopo **dimostrativo, non commerciale e di intrattenimento personale**.

> ⚠️ La licenza MIT copre **solo il codice**, non i file audio. Se sei titolare dei diritti di una clip e vuoi che venga rimossa, apri una *issue*: la togliamo subito.
