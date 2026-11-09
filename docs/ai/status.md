# Status (update when it changes)

- Current version: **1.6.1** (schema 8). 1.6.1: Tax screen = current year, Projected vs Recorded
  (entries only); last year as a card until 30 Nov. 1.6.0: Owner's model now: money is in sections (This month),
  Floating (not tied to a month), parked (Held for next month) or pots. Salary: pots at once, the
  plan's expense part parked to the 1st, extra to Floating. Month-end leftover: Carried forward
  unless moved to a pot in the close sheet. November's existing carry stays Carried forward.
- Production data: salary recorded as ৳87,646 but ৳94,912 arrived (owner confirmed 2026-10-31:
  bank short by ৳7,266). Fix in the app: edit the salary entry's amount (no second split; Held
  for November then becomes ৳52,000).
- The owner started using the app for real in October 2026 and stopped the Excel sheet.
  Raise from November: salary ~৳1,00,000 arrives 26 Oct, held for November (plan saved "From November").

## Waiting for the owner's go
- Asked 2026-11-09, discussed, not started: periodic backup to Google Drive; an AI model in the
  app; "next-gen" ideas (see the reply in that session; nothing chosen yet).
- "Use Floating" in the Over budget step / Move budget / New slot (offered, not asked for yet).
- Move dev data into production (approved "replace everything"; do it via in-app backup/restore
  with the phone unlocked and connected).

## Known limits
- SMS parser written without real City Bank/bKash samples; tune when messages are reported.
- Tax defaults: Finance Act 2026 as reported (৳4,00,000 general threshold, 10–30% slabs); rebate
  rate uncertain (15% vs 10%); all editable in the app.
