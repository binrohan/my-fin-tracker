# Status (update when it changes)

- Current version: **1.9.1** (schema 9). 1.9.1: archived/split categories stay in Quick add,
  buy-from-goal and loan repay-from-budget until the month ends (owner chose this 2026-11-17,
  replacing 1.7.1's "hidden from quick add at once"). 1.9.0: Bills to pay → Pay into a pot (counts as
  paid, money kept in the pot in any account, e.g. bank money put aside as cash); moves tied to a
  budget are no longer editable in Quick add (an edit turned the owner's Cycle save into a plain
  move, so the bill came back); Move budget / slots / Save to pot list the month's categories from
  its snapshot (Abbu missing after the December plan changed it). 1.8.0: each month runs on a snapshot of the plan,
  budgets and categories taken at its first app open; changes start next month. 1.7.1: archiving a category counts from next month
  (an unpaid bill archived mid-month stays in Bills to pay). 1.7.0: weekly encrypted backup to Google
  Drive. 1.6.1: Tax screen = current year, Projected vs Recorded
  (entries only); last year as a card until 30 Nov. 1.6.0: Owner's model now: money is in sections (This month),
  Floating (not tied to a month), parked (Held for next month) or pots. Salary: pots at once, the
  plan's expense part parked to the 1st, extra to Floating. Month-end leftover: Carried forward
  unless moved to a pot in the close sheet. November's existing carry stays Carried forward.
- Production data: salary recorded as ৳87,646 but ৳94,912 arrived (owner confirmed 2026-10-31:
  bank short by ৳7,266). Fix in the app: edit the salary entry's amount (no second split; Held
  for November then becomes ৳52,000).
- The owner started using the app for real in October 2026 and stopped the Excel sheet.
  Raise from November: salary ~৳1,00,000 arrives 26 Oct, held for November (plan saved "From November").

- Owner's data after 1.9.0: the Cycle move edited to cash (Nov 2026) is a plain move now; the
  owner should delete it and redo it with Pay into a pot (UAT section 29). Not checked against
  the phone's data: it was not connected.

## Waiting for the owner's go
- Asked 2026-11-09, discussed, not started: an AI model in the app (on-device first suggested);
  "next-gen" ideas (forecast to next salary, bill detection, what-if, price tracker, goal
  autopilot, Bangla/voice, family sharing). Nothing chosen yet.
- Google Drive needs the owner's Google Cloud setup (project, Drive API, consent screen published
  "In production", Android OAuth clients):
  - com.myfin.my_fin_tracker — release SHA-1 83:FA:19:2F:D8:D1:C9:F7:FB:C8:C6:E1:7F:51:60:76:24:26:C9:5A
  - com.myfin.my_fin_tracker.dev — debug SHA-1 1E:D8:C4:FC:4C:AA:A3:82:B2:60:05:F1:8E:49:AC:31:2A:C5:3A:49
  Until then Connect fails with a configuration error; nothing else is affected.
- "Use Floating" in the Over budget step / Move budget / New slot (offered, not asked for yet).
- Move dev data into production (approved "replace everything"; do it via in-app backup/restore
  with the phone unlocked and connected).

## Known limits
- SMS parser written without real City Bank/bKash samples; tune when messages are reported.
- Tax defaults: Finance Act 2026 as reported (৳4,00,000 general threshold, 10–30% slabs); rebate
  rate uncertain (15% vs 10%); all editable in the app.
