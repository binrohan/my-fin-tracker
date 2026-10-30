# Status (update when it changes)

- Current version: **1.5.0** (schema 7). Salary splits on arrival; Unplanned pot; refunds.
- Production data (backup 2026-10-30): salary recorded as ৳87,646 (plan says ৳94,912 from Nov) —
  owner to confirm the real amount and edit the entry if needed; bonus ৳7,363 held for Nov had
  switched the salary split off; 1.5.0's catch-up fixes the split on first start (verified on a copy).
- The owner started using the app for real in October 2026 and stopped the Excel sheet.
  Raise from November: salary ~৳1,00,000 arrives 26 Oct, held for November (plan saved "From November").

## Waiting for the owner's go
- "Use Unplanned" in the Over budget step / Move budget / New slot (offered, not asked for yet).
- Move dev data into production (approved "replace everything"; do it via in-app backup/restore
  with the phone unlocked and connected).

## Known limits
- SMS parser written without real City Bank/bKash samples; tune when messages are reported.
- Tax defaults: Finance Act 2026 as reported (৳4,00,000 general threshold, 10–30% slabs); rebate
  rate uncertain (15% vs 10%); all editable in the app.
