---
description: Mail triage — what needs a reply or action, with tasks created
allowed-tools: mcp__gmail__search_emails, mcp__gmail__read_email, mcp__gmail__draft_email, Bash(~/.claude/skills/assistant/pa:*), Read, Write, Edit
---

Triage the last ${1:-7} days of mail following the "Mail" section of the `assistant` skill:
search `is:unread newer_than:${1:-7}d category:primary`, drop newsletters and notifications,
split the rest into "needs a reply" / "deadline" / "FYI".
Create `pa task` for everything with a deadline and `pa event` for appointments; draft replies.
Don't send, delete or archive anything without an explicit command.
