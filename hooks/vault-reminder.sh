#!/bin/bash
# Stop hook: remind the session to write personal facts into the vault.
# Fires in sessions started in $HOME (assistant mode) and in any session that used the
# assistant skill. Silent if vault notes already changed today. Once per stop:
# the second stop arrives with stop_hook_active=true.
set -u
input=$(cat)

[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

if [ "$PWD" != "$HOME" ]; then
  t=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
  [ -f "$t" ] || exit 0
  grep -qE '"skill" *: *"assistant"|<command-name>/(agenda|inbox|recap)' "$t" || exit 0
fi

V="${VAULT:-$HOME/Vault}"
[ -n "$(/usr/bin/find -L "$V/Identity" "$V/Tracks" "$V/Assistant" "$V/Index.md" -name '*.md' -mtime -1 2>/dev/null)" ] && exit 0

jq -n --arg r "The vault was not updated today. If something personal came up in this session, decide where it goes and write it down before finishing:
• a new or changed fact (address, policy number, bank details, job) → edit the right file in $V/Identity/;
• an ongoing matter moved → append to its file in $V/Tracks/, update status: and note:;
• a new ongoing matter → create a track with frontmatter type/status/updated/note;
• agreements, amounts, case numbers, decisions → append to $V/Assistant/Journal/<today>.md.
If the session was purely technical or nothing new was decided, say so in one line and finish." '{decision:"block", reason:$r}'
