#!/usr/bin/env python3
import re
from pathlib import Path

DOC_ROOT = Path("/Users/sero/Desktop/FoliBusAPI/Sources")


def check_file(path: Path) -> list[str]:
    issues = []
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    # Check balanced code fences
    fence_counts = {"```": 0, "~~~": 0}
    for i, line in enumerate(lines, 1):
        stripped = line.lstrip()
        if stripped.startswith("```"):
            fence_counts["```"] += 1
        elif stripped.startswith("~~~"):
            fence_counts["~~~"] += 1
        # Heading syntax
        if line.strip().startswith("#") and not re.match(r"^#{1,6} ", line.strip()) and not re.match(r"^#{1,6}$", line.strip()):
            issues.append(f"{path}:{i}: suspicious heading '{line.strip()}'")

    if fence_counts["```"] % 2 != 0:
        issues.append(f"{path}: unbalanced ``` fences ({fence_counts['```']})")
    if fence_counts["~~~"] % 2 != 0:
        issues.append(f"{path}: unbalanced ~~~ fences ({fence_counts['~~~']})")

    # Check DocC symbol references: ``identifier`` with no spaces inside
    for match in re.finditer(r"``[^`]*``", text):
        content = match.group(0)[2:-2]
        if content.startswith(" ") or content.endswith(" "):
            issues.append(f"{path}:{text[:match.start()].count(chr(10))+1}: DocC reference has leading/trailing space: `{content}`")
        if " ``" in match.group(0) or "`` " in match.group(0):
            continue  # false positives from nested backticks

    # Check DocC article references: <doc:Name>
    for match in re.finditer(r"<doc:([A-Za-z0-9_]+)>", text):
        pass

    # Check for bare <doc: with invalid chars
    for match in re.finditer(r"<doc:[^>]+>", text):
        name = match.group(0)[5:-1]
        if not re.match(r"^[A-Za-z0-9_]+$", name):
            issues.append(f"{path}: invalid doc reference name `{name}`")

    return issues


def main():
    files = sorted(DOC_ROOT.rglob("*.md"))
    all_issues = []
    for f in files:
        if f.name.endswith(".md"):
            all_issues.extend(check_file(f))

    if all_issues:
        print("Issues found:")
        for issue in all_issues:
            print(f"  {issue}")
        raise SystemExit(1)
    else:
        print(f"Validated {len(files)} markdown files. No issues found.")


if __name__ == "__main__":
    main()
