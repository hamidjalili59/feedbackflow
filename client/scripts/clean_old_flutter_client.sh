#!/usr/bin/env bash
set -euo pipefail
# Run this from the project root before extracting this package over an old FeedbackFlow client.
# It removes stale Bloc-era source folders/files that Dart Analyzer can still pick up.
rm -rf .dart_tool build lib
rm -f pubspec.lock
echo 'Old lib, build, .dart_tool, and pubspec.lock removed. Extract the new ZIP now.'
