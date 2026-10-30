# Workflow

## Release
1. Bump `version:` in pubspec.yaml (x.y.z+build; build always +1).
2. `tool/build_release.sh` → `release/my-fin-tracker-<v>-arm64.apk` and `release/my-fin-dev-<v>-debug.apk`
   (release/ is git-ignored). Signing: `android/key.properties` (git-ignored) → `myfin-release.jks`.
3. Commit (no AI attribution), `git tag v<version>`.

## Installing on the phone (adb)
```bash
adb devices                                  # phone must show "device"
tool/dev_db_count.sh before                  # MUST print table counts first
adb install -r release/my-fin-dev-<v>-debug.apk
adb install -r release/my-fin-tracker-<v>-arm64.apk
adb shell monkey -p com.myfin.my_fin_tracker.dev -c android.intent.category.LAUNCHER 1
tool/dev_db_count.sh after && diff /tmp/myfin-db/before.txt /tmp/myfin-db/after.txt
```
- Only the dev app's DB can be read (debuggable, `run-as`). The release app can't be read.
- The phone drops off USB / locks often: check `adb devices` and
  `adb shell dumpsys window | grep isKeyguardShowing` before UI steps; don't loop forever.
- Screen off → screenshots are black; render instead (below).

## Seeing a screen without the phone
Render with real fonts in a throwaway test (keep it out of `test/` afterwards): load IBMPlexSans,
HindSiliguri and MaterialIcons (`~/dev/flutter/bin/cache/artifacts/material_fonts/`) with
`FontLoader`, pump the screen at 1080×2340, capture a `RepaintBoundary` with `toImage`, write PNG.

## Data safety checklist
- Never `rm` app data, never write the phone DB directly (a safety check blocks it anyway).
- Moving dev data to production = in-app Backup (dev) → Backup (prod, safety copy) → Restore (prod).
