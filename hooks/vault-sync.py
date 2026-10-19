#!/usr/bin/env python3
"""PostToolUse hook: mechanical upkeep of the Obsidian vault.

A vault file is edited -> its frontmatter gets `updated: <today>`.
A track is edited -> the "What we're tracking" table in Index.md is rebuilt from every
track's frontmatter (status + note), so the overview never drifts from the tracks.

Vault location: $VAULT, default ~/Vault. Self-test: python3 vault-sync.py --selftest
"""
import json, os, re, sys, datetime, pathlib

VAULT = pathlib.Path(os.environ.get("VAULT", pathlib.Path.home() / "Vault")).expanduser().resolve()
# status synonyms, because people (and models) write status in different words
MARK = {"active": "🔴", "open": "🔴", "blocked": "🔴",
        "watch": "🟡", "waiting": "🟡", "paused": "🟡",
        "closed": "✅", "done": "✅"}
RANK = {"🔴": 0, "🟡": 1, "✅": 2}
TODAY = datetime.date.today().isoformat()


def frontmatter(text):
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}
    return dict(re.findall(r"^(\w+): *(.*?)\s*$", m.group(1), re.M))


def stamp(path):
    t = path.read_text()
    if not re.match(r"---\n", t):
        return
    new = re.sub(r"^updated: .*$", f"updated: {TODAY}", t, count=1, flags=re.M)
    if new != t:
        path.write_text(new)


def rebuild_index():
    rows = []
    for p in sorted((VAULT / "Tracks").glob("*.md")):
        fm = frontmatter(p.read_text())
        st = fm.get("status", "active")
        mark = MARK.get(st, "🔴")
        rows.append((RANK[mark],
                     fm.get("updated", ""), p.stem, st, fm.get("note", "")))
    rows.sort(key=lambda r: (r[0], -int(r[1].replace("-", "") or 0)))  # urgent first, then newest
    table = ["| Track | Status |", "|---|---|"] + [
        f"| [[{stem}]] | {MARK.get(st, '🔴')} {note} |" for _, _, stem, st, note in rows]

    idx = VAULT / "Index.md"
    t = idx.read_text()
    new = re.sub(r"(## What we're tracking\n)(.*?)(\n## )", "\\1" + "\n".join(table) + "\n\\3",
                 t, count=1, flags=re.S)
    if new != t:
        idx.write_text(new)


def main():
    try:
        f = json.load(sys.stdin).get("tool_input", {}).get("file_path", "")
    except Exception:
        return
    if not f.endswith(".md"):
        return
    p = pathlib.Path(f).resolve()
    try:
        p.relative_to(VAULT)
    except ValueError:
        return
    if not p.exists():
        return
    stamp(p)
    if p.parent.name == "Tracks":
        rebuild_index()


def selftest():
    import tempfile
    global VAULT
    d = pathlib.Path(tempfile.mkdtemp())
    VAULT = d
    (d / "Tracks").mkdir()
    (d / "Tracks/A.md").write_text("---\ntype: track\nstatus: closed\nupdated: 2020-01-01\nnote: old\n---\ntext\n")
    (d / "Tracks/B.md").write_text("---\ntype: track\nstatus: active\nupdated: 2026-08-01\nnote: urgent\n---\ntext\n")
    (d / "Index.md").write_text("# I\n\n## What we're tracking\njunk\n\n## Next\ntail\n")
    stamp(d / "Tracks/B.md")
    assert f"updated: {TODAY}" in (d / "Tracks/B.md").read_text(), "stamp missing"
    rebuild_index()
    idx = (d / "Index.md").read_text()
    assert idx.index("[[B]]") < idx.index("[[A]]"), "active must sort above closed"
    assert "🔴 urgent" in idx and "✅ old" in idx, "note/mark lost"
    assert idx.endswith("## Next\ntail\n") and "junk" not in idx, "wrong part of Index replaced"
    print("vault-sync selftest ok")


if __name__ == "__main__":
    selftest() if "--selftest" in sys.argv else main()
