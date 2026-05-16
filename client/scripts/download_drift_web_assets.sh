#!/usr/bin/env bash
set -euo pipefail
mkdir -p web
curl -L -o web/sqlite3.wasm https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3_flutter_libs-0.5.42/sqlite3.wasm
curl -L -o web/drift_worker.js https://github.com/simolus3/drift/releases/download/drift-2.31.0/drift_worker.js
echo "Downloaded Drift web assets into web/."
