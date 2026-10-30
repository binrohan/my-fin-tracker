# Conventions

## Code
- Match surrounding style; `dart format -l 100`. Short doc comments on public classes/functions,
  written in plain English for the domain ("Left to spend after bills").
- UI words: "pot", "goal", "Left to spend", "Bills to pay", "Monthly plan", "Move budget",
  "Save to pot", "slot". Amounts via `formatTaka`; use `taka(…)` in tests.
- Sheets: `showModalBottomSheet(useRootNavigator: true, isScrollControlled: true, …)` + `SheetBody`.
- Don't use `ref` in `dispose`; capture what you need in `initState`.
- New settings: add a `const xxxSetting = '...'` next to the code that owns it.
- Glyph trap: IBM Plex has no ✓; use icons. Arrows ↑↓→ are fine.

## Tests
- Unit tests build data with `loadSampleData(db)` on `NativeDatabase.memory()`; sample "today" is
  2026-10-08 (October left to spend ৳24,420, bills ৳4,000, Bank ৳1,23,970, total ৳1,32,920).
- Screen tests: `tester.view.physicalSize = Size(1080, 2340)`, `devicePixelRatio = 1080/384`,
  override `ledgerProvider`, `todayProvider`, and `repositoryProvider` when the screen writes.
- Pitfalls seen before:
  - `Label` upper-cases text → find `'NEEDS ATTENTION'`, not `'Needs attention'`.
  - `AmountRow` with `detail` is rich text → `find.textContaining(x, findRichText: true)`.
  - Screens with TextFields have several Scrollables → pass `scrollable: find.byType(Scrollable).first`.
  - Lazy lists: scroll back (`-300`) before tapping things above; `ensureVisible` before `tap`.
  - DB reads/writes inside widget tests need `tester.runAsync`.
  - `drift` exports `isNull/isNotNull` → `import 'package:drift/drift.dart' hide isNull, isNotNull;`
- Upgrade tests: create old schema from `test/fixtures/schema_vN.sql`, set `PRAGMA user_version`,
  open, check data and `old.schemaVersion`.
