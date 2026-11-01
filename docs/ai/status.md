# Status (update when it changes)

- Current version: **1.5.3** (schema 7). 1.5.0 salary splits on arrival, Unplanned pot, refunds;
  1.5.2 report counts close-time saves as used; 1.5.3 a repayment counts as spent from a chosen
  category (owner: "loan repay is a month expense", not a budget cut); tap a bill on Home to pay.
- Production data: salary recorded as ৳87,646 but ৳94,912 arrived (owner confirmed 2026-10-31:
  bank short by ৳7,266). Fix in the app: edit the salary entry's amount (no second split; Held
  for November then becomes ৳52,000).
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
