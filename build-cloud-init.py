#!/usr/bin/env python3
"""
Build cloud-init.yaml from cloud-init.yaml.tpl by inlining standalone shell scripts.

Usage:
    python3 build-cloud-init.py

Markers in the template:
    {{ include: filename.sh }}

Each marker must appear as the sole content of a YAML block scalar line (after
the `|` introducer). The marker's leading whitespace sets the indentation that
will be applied to every line of the included file.
"""

import re
import sys
from pathlib import Path

TEMPLATE = Path("cloud-init.yaml.tpl")
OUTPUT = Path("cloud-init.yaml")
SCRIPT_DIR = Path(".")

INCLUDE_RE = re.compile(r'^(\s*)\{\{\s*include:\s*(\S+)\s*\}\}\s*$')

GENERATED_HEADER = """\
#cloud-config
# GENERATED FILE — do not edit directly.
# Edit cloud-init.yaml.tpl and the standalone .sh files, then run:
#   python3 build-cloud-init.py
#
"""


def include_file(filename: str, indent: str) -> str:
    path = SCRIPT_DIR / filename
    if not path.exists():
        print(f"ERROR: included file not found: {path}", file=sys.stderr)
        sys.exit(1)
    lines = path.read_text().splitlines()
    # Drop trailing blank lines to keep YAML tidy
    while lines and not lines[-1].strip():
        lines.pop()
    return "\n".join(indent + line if line.strip() else "" for line in lines)


def build(template_path: Path, output_path: Path) -> None:
    template = template_path.read_text()
    output_lines = []

    lines_in = template.splitlines()
    # The template's first line is "#cloud-config"; it's already in the header.
    if lines_in and lines_in[0].strip() == "#cloud-config":
        lines_in = lines_in[1:]

    for line in lines_in:
        m = INCLUDE_RE.match(line)
        if m:
            indent, filename = m.group(1), m.group(2)
            output_lines.append(include_file(filename, indent))
        else:
            output_lines.append(line)

    content = GENERATED_HEADER + "\n".join(output_lines) + "\n"
    output_path.write_text(content)
    print(f"Written: {output_path}")


if __name__ == "__main__":
    if not TEMPLATE.exists():
        print(f"ERROR: template not found: {TEMPLATE}", file=sys.stderr)
        sys.exit(1)
    build(TEMPLATE, OUTPUT)
