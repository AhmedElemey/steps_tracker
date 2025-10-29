#!/usr/bin/env python3
from __future__ import annotations

import os
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


LINE_COMMENT_EXTS = {
    ".dart",
    ".kt",
    ".java",
    ".swift",
    ".gradle.kts",
    ".gradle",
    ".yaml",
    ".yml",
    ".sh",
    ".properties",
}

XML_LIKE_EXTS = {".xml", ".plist", ".html"}


RE_LINE_COMMENT = re.compile(r"^\s*(//|#|!|;).*$")
RE_XML_SINGLE_LINE_COMMENT = re.compile(r"^\s*<!--.*-->\s*$")


def is_text_file(path: Path) -> bool:
    try:
        with path.open("rb") as f:
            chunk = f.read(4096)
        # Heuristically consider binary if NUL byte present
        return b"\x00" not in chunk
    except Exception:
        return False


def should_skip_dir(path: Path) -> bool:
    parts = set(path.parts)
    skip_names = {
        "build",
        ".dart_tool",
        "Pods",
        "ephemeral",
        "ios",  # only skip ephemeral via check below
        "macos",  # only skip ephemeral via check below
        ".git",
        "node_modules",
    }
    if any(name in parts for name in skip_names):
        # allow traversing ios/macos but skip their Flutter/ephemeral
        if "Flutter" in parts and "ephemeral" in parts:
            return True
        # broadly skip build/.dart_tool/Pods/node_modules
        if "build" in parts or ".dart_tool" in parts or "Pods" in parts or "node_modules" in parts:
            return True
    return False


def process_file(path: Path) -> bool:
    ext = path.suffix.lower()
    changed = False

    # Some files have multi-part extensions like .gradle.kts
    if not ext and path.name.endswith(".gradle.kts"):
        ext = ".gradle.kts"

    try:
        text = path.read_text(encoding="utf-8")
    except Exception:
        return False

    lines = text.splitlines(keepends=True)

    if ext in LINE_COMMENT_EXTS:
        filtered = [ln for ln in lines if not RE_LINE_COMMENT.match(ln)]
        if filtered != lines:
            path.write_text("".join(filtered), encoding="utf-8")
            changed = True

    if ext in XML_LIKE_EXTS:
        # Only remove single-line comment-only nodes; do not attempt multi-line blocks
        filtered = []
        removed_any = False
        for ln in lines:
            if RE_XML_SINGLE_LINE_COMMENT.match(ln):
                removed_any = True
            else:
                filtered.append(ln)
        if removed_any:
            path.write_text("".join(filtered), encoding="utf-8")
            changed = True

    return changed


def main() -> int:
    root = ROOT
    if len(sys.argv) > 1:
        root = Path(sys.argv[1]).resolve()

    changed_count = 0
    file_count = 0

    for dirpath, dirnames, filenames in os.walk(root):
        current_dir = Path(dirpath)
        # Prune unwanted directories in-place
        pruned = []
        for d in list(dirnames):
            dpath = current_dir / d
            if should_skip_dir(dpath):
                dirnames.remove(d)
                pruned.append(d)
        # Process files
        for name in filenames:
            path = current_dir / name
            # Only process likely text files and known extensions
            if not is_text_file(path):
                continue
            if (path.suffix.lower() in LINE_COMMENT_EXTS) or (path.suffix.lower() in XML_LIKE_EXTS) or name.endswith(".gradle.kts"):
                file_count += 1
                if process_file(path):
                    changed_count += 1

    print(f"Processed {file_count} files; modified {changed_count} files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


