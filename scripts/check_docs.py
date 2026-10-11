#!/usr/bin/env python3
"""Structural checks for this design repo.

- Relative Markdown links (and #anchors) resolve.
- Templates contain required fields.
- No personal absolute paths in published files.

Only checks structure; it does not validate any design claim.
"""
import json
import re
import subprocess
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LINK_RE = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
PERSONAL_PATH_RE = re.compile(r"(/Users/[A-Za-z0-9._-]+|/home/[A-Za-z0-9._-]+|[A-Za-z]:\\\\Users\\\\)")

REQUIRED = {
    "templates/ticket.template.md": [
        r"^Owner: ", r"^Status: draft$", r"^Spec: ", r"^Branch: ", r"^Since: ",
        r"^Issue: ", r"^MR: ", r"^## What to build$", r"^## Acceptance criteria$",
        r"^## Blocked by$",
    ],
    "templates/adr.template.md": [
        r"^Status: proposed$", r"^Date: ", r"^Supersedes: ", r"^Superseded by: ",
        r"proposed", r"accepted", r"superseded",
    ],
    "templates/journal.template.md": [
        r"^Member: ", r"^Agent: ", r"^Task: ", r"^Version: ", r"^## Verification$",
        r"^## Not verified$", r"^## Next$",
    ],
    "templates/issue-tracker.template.md": [
        r"\| draft \|", r"\| ready-for-agent \|", r"\| in-progress \|", r"\| blocked \|",
        r"\| implemented \|", r"\| dropped \|", r"rand6", r"git for-each-ref",
    ],
    "templates/team.template.md": [r"^## 成员名册$"],
    "templates/AGENTS.template.md": [r"^## Priority and trust$"],
}


def tracked_files():
    out = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True)
    return [ROOT / p for p in out.stdout.splitlines() if (ROOT / p).is_file()]


def strip_code(text):
    """Remove fenced code blocks, HTML comments and inline code, keeping line count."""
    text = re.sub(r"<!--.*?-->", lambda m: "\n" * m.group(0).count("\n"), text, flags=re.S)
    lines, out, fence = text.split("\n"), [], None
    for line in lines:
        m = re.match(r"^\s*(```+|~~~+)", line)
        if m:
            marker = m.group(1)[0] * 3
            if fence is None:
                fence = marker
            elif marker == fence:
                fence = None
            out.append("")
            continue
        out.append("" if fence else re.sub(r"`[^`]*`", "", line))
    return "\n".join(out)


def slugify(title):
    title = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", title)  # link text only
    title = title.replace("`", "").strip().lower()
    chars = []
    for ch in title:
        cat = unicodedata.category(ch)
        if ch in "-_" or ch == " " or cat[0] in ("L", "N") or cat == "Mn":
            chars.append(ch)
    return "".join(chars).replace(" ", "-")


def anchors(path, cache={}):
    if path not in cache:
        seen, result = {}, set()
        for line in strip_code(path.read_text(encoding="utf-8")).split("\n"):
            m = HEADING_RE.match(line)
            if not m:
                continue
            slug = slugify(m.group(2))
            n = seen.get(slug, 0)
            seen[slug] = n + 1
            result.add(slug if n == 0 else f"{slug}-{n}")
        cache[path] = result
    return cache[path]


def check_links(md, errors):
    text = strip_code(md.read_text(encoding="utf-8"))
    for lineno, line in enumerate(text.split("\n"), 1):
        for target in LINK_RE.findall(line):
            if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.I):
                continue  # http:, https:, mailto: ...
            path_part, _, frag = target.partition("#")
            dest = md if not path_part else (md.parent / path_part).resolve()
            where = f"{md.relative_to(ROOT)}:{lineno}"
            if not dest.exists():
                errors.append(f"{where}: broken link -> {target}")
                continue
            if frag and dest.suffix == ".md" and frag not in anchors(dest):
                errors.append(f"{where}: missing anchor -> {target}")


def main():
    errors = []
    files = tracked_files()
    for f in files:
        if f.suffix == ".md":
            check_links(f, errors)
        if f.suffix in (".md", ".json", ".yml", ".yaml", ".py") and f.name != "check_docs.py":
            for lineno, line in enumerate(f.read_text(encoding="utf-8").split("\n"), 1):
                if PERSONAL_PATH_RE.search(line):
                    errors.append(f"{f.relative_to(ROOT)}:{lineno}: personal absolute path")
        if f.suffix == ".json":
            try:
                json.loads(f.read_text(encoding="utf-8"))
            except ValueError as e:
                errors.append(f"{f.relative_to(ROOT)}: invalid JSON: {e}")
    for rel, patterns in REQUIRED.items():
        p = ROOT / rel
        if not p.exists():
            errors.append(f"{rel}: missing template")
            continue
        text = p.read_text(encoding="utf-8")
        for pat in patterns:
            if not re.search(pat, text, re.M):
                errors.append(f"{rel}: missing required pattern {pat!r}")
    readme = (ROOT / "templates/README.md").read_text(encoding="utf-8")
    for t in sorted((ROOT / "templates").glob("*.template.md")):
        if f"]({t.name})" not in readme:
            errors.append(f"templates/README.md: template {t.name} not listed")
    for e in errors:
        print(e)
    md_count = sum(1 for f in files if f.suffix == ".md")
    print(f"checked {md_count} Markdown files: {len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
