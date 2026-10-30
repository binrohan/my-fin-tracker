#!/bin/bash
# Builds the release (arm64) and debug APKs and copies them into release/ with
# the version from pubspec.yaml in the name.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter=~/dev/flutter/bin/flutter
version=$(grep '^version:' pubspec.yaml | sed 's/version: //; s/+.*//')
$flutter build apk --release --split-per-abi
$flutter build apk --debug
mkdir -p release
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "release/my-fin-tracker-$version-arm64.apk"
cp build/app/outputs/flutter-apk/app-debug.apk "release/my-fin-dev-$version-debug.apk"
ls -1 release/*"$version"*
