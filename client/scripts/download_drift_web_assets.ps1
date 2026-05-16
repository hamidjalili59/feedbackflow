$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path "web" | Out-Null
Invoke-WebRequest -Uri "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3_flutter_libs-0.5.42/sqlite3.wasm" -OutFile "web/sqlite3.wasm"
Invoke-WebRequest -Uri "https://github.com/simolus3/drift/releases/download/drift-2.31.0/drift_worker.js" -OutFile "web/drift_worker.js"
Write-Host "Downloaded Drift web assets into web/."
