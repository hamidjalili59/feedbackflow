# Run this from the project root before extracting this package over an old FeedbackFlow client.
# It removes stale Bloc-era source folders/files that Dart Analyzer can still pick up.
$ErrorActionPreference = 'SilentlyContinue'

Remove-Item -Recurse -Force .dart_tool
Remove-Item -Recurse -Force build
Remove-Item -Recurse -Force lib
Remove-Item -Force pubspec.lock

Write-Host 'Old lib, build, .dart_tool, and pubspec.lock removed. Extract the new ZIP now.'
