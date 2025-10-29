#!/usr/bin/env python3
import os
import re
from typing import Tuple, List


PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


EXCLUDE_DIRS = {
    "build",
    ".git",
    ".dart_tool",
    "ios/Pods",
    "macos/Pods",
    "ios/Flutter/ephemeral",
    "macos/Flutter/ephemeral",
    "android/.gradle",
    "android/build",
}


INCLUDED_EXTENSIONS = {
    ".dart",
    ".kt",
    ".kts",
    ".java",
    ".swift",
    ".m",
    ".mm",
    ".js",
    ".ts",
    ".tsx",
    ".jsx",
    ".gradle",
    ".xml",
    ".plist",
    ".sh",
    ".yaml",
    ".yml",
}


CLIKE_EXTS = {".dart", ".kt", ".kts", ".java", ".swift", ".m", ".mm", ".js", ".ts", ".tsx", ".jsx", ".gradle"}
XML_EXTS = {".xml", ".plist"}
HASH_EXTS = {".sh", ".yaml", ".yml"}


def is_path_excluded(path: str) -> bool:
    rel = os.path.relpath(path, PROJECT_ROOT)
    # Normalize separators to '/'
    rel_n = rel.replace(os.sep, "/")
    for ex in EXCLUDE_DIRS:
        if rel_n == ex or rel_n.startswith(ex + "/"):
            return True
    return False


def remove_full_line_comments(lines: List[str], ext: str) -> Tuple[List[str], int]:
    removed = 0
    result: List[str] = []

    if ext in CLIKE_EXTS:
        in_block = False
        for line in lines:
            stripped = line.lstrip()

            if in_block:
                # Check for block comment end
                if re.search(r"\*/\s*$", stripped) or "*/" in stripped:
                    in_block = False
                # Entire line is within block comment → drop it
                removed += 1
                continue

            # Full-line single-line comment (// ...)
            if re.match(r"^\s*//", line):
                removed += 1
                continue

            # Full-line block comment start
            if re.match(r"^\s*/\*", line):
                # If it also ends on same line and contains nothing else meaningful, drop this line only
                if re.match(r"^\s*/\*.*?\*/\s*$", line):
                    removed += 1
                    continue
                # Otherwise enter block and drop this line
                in_block = True
                removed += 1
                continue

            result.append(line)

        return result, removed

    if ext in XML_EXTS:
        in_block = False
        for line in lines:
            stripped = line.strip()

            if in_block:
                if "-->" in stripped:
                    in_block = False
                removed += 1
                continue

            # Full-line XML comment
            if stripped.startswith("<!--"):
                if stripped.endswith("-->"):
                    removed += 1
                    continue
                in_block = True
                removed += 1
                continue

            result.append(line)
        return result, removed

    if ext in HASH_EXTS:
        for line in lines:
            stripped = line.lstrip()
            # Preserve shebangs in shell scripts
            if stripped.startswith("#!"):
                result.append(line)
                continue
            if re.match(r"^\s*#", line):
                removed += 1
                continue
            result.append(line)
        return result, removed

    # Default passthrough for other files (should not happen due to filter)
    return lines, 0


def process_file(path: str) -> Tuple[int, int]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            original_lines = f.readlines()
    except (UnicodeDecodeError, OSError):
        return 0, 0

    ext = os.path.splitext(path)[1].lower()
    new_lines, removed = remove_full_line_comments(original_lines, ext)
    if removed > 0:
        try:
            with open(path, "w", encoding="utf-8") as f:
                f.writelines(new_lines)
        except OSError:
            return 0, 0
    return (1 if removed > 0 else 0), removed


def main() -> None:
    files_changed = 0
    lines_removed = 0
    for root, dirs, files in os.walk(PROJECT_ROOT):
        # Skip excluded dirs
        # We modify dirs in-place to prevent descending into them
        dirs[:] = [d for d in dirs if not is_path_excluded(os.path.join(root, d))]

        for name in files:
            ext = os.path.splitext(name)[1].lower()
            if ext not in INCLUDED_EXTENSIONS:
                continue
            full_path = os.path.join(root, name)
            if is_path_excluded(full_path):
                continue
            changed, removed = process_file(full_path)
            files_changed += changed
            lines_removed += removed

    print(f"Files changed: {files_changed}")
    print(f"Comment-only lines removed: {lines_removed}")


if __name__ == "__main__":
    main()


