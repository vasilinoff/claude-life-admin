#!/bin/zsh
# Headless assistant run every 3 hours: mail -> calendar/tasks -> journal -> spending.
# Started by launchd (see com.example.assistant-sweep.plist); can be run by hand.
set -uo pipefail

VAULT="${VAULT:-$HOME/Vault}"
CLAUDE="$HOME/.local/bin/claude"
LOG="$VAULT/Assistant/sweep.log"
ERR="$VAULT/Assistant/sweep.err"
CSV="$VAULT/Finance/Spending.csv"
STAMP="$VAULT/Assistant/.sweep-last"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin"

mkdir -p "$VAULT/Assistant" "$VAULT/Finance"
[ -f "$CSV" ] || echo "date,merchant,amount,what,gmail_id" > "$CSV"

# Mail window = time since the last successful run (+1h overlap), clamped to 4..48 hours.
# If the laptop slept half a day, the window grows and nothing is lost.
if [ -f "$STAMP" ]; then
  AGE_H=$(( ( $(date +%s) - $(stat -f %m "$STAMP") ) / 3600 + 1 ))
else
  AGE_H=48
fi
[ "$AGE_H" -lt 4 ] && AGE_H=4
[ "$AGE_H" -gt 48 ] && AGE_H=48

PROMPT=$(cat <<'PROMPT_EOF'
You are my personal assistant running unattended: nobody can answer questions, so decide yourself
and log doubts in the journal. Follow the assistant skill (~/.claude/skills/assistant/SKILL.md).
Calendar and tasks via ~/.claude/skills/assistant/pa; personal facts and ongoing matters in the vault (see its Index.md).
This run repeats every 3 hours and the mail window overlaps the previous run: check that something
doesn't exist yet before creating it. No new mail: say so in one line, invent nothing, don't touch the journal.

Steps:
1. Mail: mcp__gmail__search_emails "newer_than:__WINDOW__h". Skip ads and newsletters.
   Confirmed date and time (appointment, delivery, visit) -> pa event; run `pa agenda 14` first to avoid duplicates.
   A deadline or "need to do" -> pa task with a concrete date. A request without confirmation is a task to follow up, not an event.
   Never delete, archive or send anything. Needs a reply -> create a draft with mcp__gmail__draft_email.
2. Journal __VAULT__/Assistant/Journal/<today YYYY-MM-DD>.md: append (never overwrite) what arrived,
   what you created, what needs a human decision. Create the file if missing. Don't log empty runs.
3. Tracks: if a letter moves a matter in __VAULT__/Tracks/, update that track (facts, status:, note:). Don't touch updated:, a hook sets it.
4. Spending: purchase, charge, invoice and refund emails from this window -> append rows to __VAULT__/Finance/Spending.csv
   as date,merchant,amount,what,gmail_id (dot as decimal separator, refunds negative, `what` short and without commas).
   Use the total actually paid. Skip rows whose gmail_id is already in the file (grep first).
5. Stdout: a 5-10 line summary: new events, new tasks, spending, what needs attention.
   If nothing new appeared, the output must be exactly one word: NOTHING.
PROMPT_EOF
)
PROMPT="${PROMPT//__WINDOW__/$AGE_H}"
PROMPT="${PROMPT//__VAULT__/$VAULT}"

cd "$HOME" || exit 1
{ echo; echo "=== $(date '+%Y-%m-%d %H:%M') (window ${AGE_H}h) ==="; } >> "$LOG"

OUT=$("$CLAUDE" -p "$PROMPT" \
  --allowedTools "mcp__gmail Bash Read Write Edit Glob Grep" \
  --model sonnet 2>>"$ERR")
STATUS=$?
echo "$OUT" >> "$LOG"

notify() {
  # pass text as an argument so quotes in it can't break the AppleScript
  osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "Assistant"' -e 'end run' "$1" >/dev/null 2>&1 || true
}

if [ $STATUS -eq 0 ]; then
  touch "$STAMP"
  # Notify only when there is something to say.
  [ "${OUT#NOTHING}" = "$OUT" ] && notify "$(echo "$OUT" | tr '\n' ' ' | cut -c1-180)"
else
  notify "Sweep failed, see $ERR"
fi
exit $STATUS
