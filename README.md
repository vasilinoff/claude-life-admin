# Claude Life Admin

A personal assistant for life admin built from [Claude Code](https://claude.com/claude-code),
a folder of Markdown and two hooks. It turns letters into dated tasks, keeps a file for every
ongoing matter and pings you only when something happened.

Write-up: _link to the blog post_

```
You / Gmail / launchd ──► Claude Code + assistant skill ──► pa ──► Google Calendar & Tasks
                                     │
                                     └──► ~/Vault (Obsidian): Identity/ · Tracks/ · Journal/ · Index.md
                          hooks: PostToolUse → vault-sync.py · Stop → vault-reminder.sh
```

## What's inside

| Path | What it is |
|---|---|
| `skill/SKILL.md` | The assistant's job description: behaviour, what matters, what is noise, where facts go |
| `skill/pa` | Stdlib-only Python CLI over Google Calendar + Tasks: `agenda`, `event`, `cancel`, `task`, `done`, `recent`, `auth` |
| `hooks/vault-sync.py` | PostToolUse: stamps `updated:` and rebuilds the tracks table in `Index.md` (`--selftest` included) |
| `hooks/vault-reminder.sh` | Stop: if nothing in the vault changed today, asks the session to write things down |
| `commands/` | `/agenda`, `/inbox`, `/recap` slash commands |
| `sweep/` | Headless `claude -p` mail triage every 3 hours via launchd; prints `NOTHING` when quiet |
| `vault-template/` | Starter vault: `Index.md`, `Identity/`, `Tracks/`, `Assistant/Journal/` |

## Install (macOS)

```bash
git clone https://github.com/vasilinoff/claude-life-admin && cd claude-life-admin

cp -R vault-template ~/Vault                      # or symlink ~/Vault to an iCloud folder
mkdir -p ~/.claude/skills/assistant ~/.claude/hooks ~/.claude/commands
cp skill/* ~/.claude/skills/assistant/
cp hooks/vault-sync.py hooks/vault-reminder.sh ~/.claude/hooks/
cp commands/*.md ~/.claude/commands/
python3 ~/.claude/hooks/vault-sync.py --selftest
```

1. Merge `hooks/settings.example.json` into `~/.claude/settings.json`.
2. Create a Google Cloud OAuth client of type **Desktop app** with the Calendar and Tasks APIs
   enabled, save it as `~/.pa/client.json`, then run `~/.claude/skills/assistant/pa auth`.
3. Connect a Gmail MCP server to Claude Code for mail triage.
4. Edit the "What matters, what is noise" lists in `SKILL.md`. This shapes the assistant most.
5. Optional: copy `sweep/AssistantSweep.sh` to `~/bin/`, fix the path in the plist, load it with `launchctl`.

The vault path defaults to `~/Vault`; set `VAULT` to change it.

## Or let Claude build it

Start Claude Code in your home directory, point it at this repo and say:
"Set this up for me step by step, ask before anything irreversible."

## License

MIT
