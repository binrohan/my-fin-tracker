# My Fin Tracker — notes for AI assistants

Personal finance app, **Android only** (Galaxy S24), Flutter. Offline, data on the phone.
Owner: Rohan BK. Currency ৳ BDT, lakh grouping (1,23,456). Months start on the 1st.

## Hard rules
- **Never** put an AI name, `Co-Authored-By` or "Generated with" lines in commits or PRs.
- Git identity for this repo only: `Rohan BK <binrohan.cs@gmail.com>`; leave the global one alone.
- **Real data lives on the phone** in BOTH apps (`com.myfin.my_fin_tracker` = "My Fin Tracker",
  `com.myfin.my_fin_tracker.dev` = "My Fin (dev)"). Never uninstall, load example data, reset,
  or write their databases. Update only with `adb install -r`.
- Before installing: run `tool/dev_db_count.sh before` and check it printed rows; after: `after` + diff.
- Don't push, publish or change the phone without being asked. Ask before anything destructive.

## Commands (Flutter lives at `~/dev/flutter`)
```bash
~/dev/flutter/bin/flutter analyze
~/dev/flutter/bin/flutter test                       # ~275 tests, ~20 s
~/dev/flutter/bin/dart format -l 100 lib test        # project width is 100, not 80
~/dev/flutter/bin/dart run build_runner build        # after changing lib/data/database.dart
tool/build_release.sh                                 # release (arm64) + debug APKs into release/
```
Build uses JDK 21 (set via `flutter config --jdk-dir`); don't change the user's JAVA_HOME.

## Where things are
- `lib/ledger/` pure logic, no Flutter: `ledger.dart` (balances, budgets, plans), `free_to_spend.dart`,
  `reminders.dart`, `insights.dart`, `afford.dart`, `tax.dart`, `zakat.dart`, `sms.dart`, `allocation.dart`.
- `lib/data/` Drift DB (`database.dart`, schema **7**), `ledger_repository.dart` (all writes),
  `backup.dart` (.mft zip), `receipts.dart`, `sms_inbox.dart`, `metal_prices.dart`.
- `lib/features/<screen>/` one folder per screen; `lib/app/` theme, router, providers, widgets/lock.
- `android/app/src/main/kotlin/.../` MainActivity (SMS channel) and 3 home-screen widgets.
- Docs: `docs/user-manual.html` (users), `docs/UAT-checklist.md` (sections per version), `design/`.

More detail, read when relevant:
- `docs/ai/architecture.md` — money model, plans, budgets, settings keys, schema history.
- `docs/ai/conventions.md` — code style, testing patterns and known test pitfalls.
- `docs/ai/workflow.md` — release, phone install, row counts, rendering screenshots.
- `docs/ai/status.md` — current version, open questions, ideas waiting for a go.

## Every change
1. Code + tests (unit in `test/ledger`, screens in `test/ui` at S24 size 1080×2340 @ 1080/384).
2. `analyze` clean, all tests pass.
3. Schema change? snapshot the old schema to `test/fixtures/schema_vN.sql` first + upgrade test.
4. Update `docs/user-manual.html`, a "New in x.y.z" section in `docs/UAT-checklist.md`, bump
   `version:` in pubspec (x.y.z+build), commit, `git tag vX.Y.Z`, build, install if the phone is on.
5. **Keep the AI notes current in the same commit** when relevant: `docs/ai/status.md` (version,
   open questions), `architecture.md` (model/schema/keys), `conventions.md` (new test pitfalls),
   `workflow.md` (process), and this file (rules, commands).
6. Reply in plain words: what changed for the user, what was verified, anything not done.
