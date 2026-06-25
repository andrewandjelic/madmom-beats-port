#!/usr/bin/env sh
# SPDX-License-Identifier: BSD-2-Clause

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

cd "$SCRIPT_DIR"
wasm-pack build --target web "$@"

cp LICENSE pkg/LICENSE
cp NOTICE pkg/NOTICE

python3 - "$SCRIPT_DIR/pkg/package.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    package = json.load(fh)

files = package.setdefault("files", [])
for entry in ("LICENSE", "NOTICE"):
    if entry not in files:
        files.append(entry)

with open(path, "w", encoding="utf-8") as fh:
    json.dump(package, fh, indent=2)
    fh.write("\n")
PY
