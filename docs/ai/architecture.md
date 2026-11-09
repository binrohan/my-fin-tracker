# Architecture

## Money model (lib/ledger/ledger.dart)
- Every entry is a set of **postings** on (account, fund) pairs; amounts are integer **poisha**.
  Balances are always computed from postings, never stored. `Ledger.load(db)` is a snapshot;
  `ledgerProvider` re-emits on every table change.
- **Accounts** = where money is: bank, cash, wallet (liquid), investment, person (loans).
- **Funds (pots)** = what it's for: spending (exactly one), savings, goal, investment, nextMonth.
  The first savings fund (Monthly Savings) is "savings"; other savings funds + goals are
  "saved for things" (`MoneyOutline` in features/home/money_details_screen.dart).
- Entry types: opening, income, expense, move, borrow, repay, lend, collect, charge, adjust, release.
- `summary(Period)` → `PeriodSummary` (leftToSpend = Spending fund balance, budget, budgetLeft,
  unplanned = leftToSpend − budgetLeft, carriedForward, released, heldForNext…).
- `FreeToSpend.of(ledger, today)`: leftToSpend − unpaid fixed bills − slot money (Home headline,
  widgets).

## Budgets
- Table `budgets` (year, month, category): the latest row at or before a month applies.
- A section with its own budget keeps it; otherwise it is the sum of its subsections.
- Month-only changes: `budget_moves` (category → category), slots (categories with
  slotYear/slotMonth; `dueDay` = likely spend day), and **saves to a pot** (move entries with
  `entries.budget_save = true`, they lower that month's budget via `budgetDeltas`).
- Loan repayments out of Spending can carry `entries.category_id`: `repaidFromBudget` counts
  them as spent in that category (`categoryLines` actual), not a budget change. Not in
  `summary.expenses` (they are repay entries); the report's Actual total adds them.
- `budgetRoom(category, period)` = budget left to check an expense against (Quick add's
  "Over the X budget" step offers Move budget / Record anyway).
- Month close is manual (`closeMonth`): unused budget → linked pots (`categories.savings_fund_id`),
  slot leftovers back, leftover split.
  Those close moves (move entries with a category, `budget_save` not true) don't change the
  budget; `savedAtCloseIn` / `savedAtClose(line)` count them as used (report "Saved" column,
  Spend tab).

- **Misc** (setting `misc_category`): `miscBudget(p)` = plan's `expenseTarget` − other sections, not
  stored; none before `misc_from` (YYYY-MM, set when upgrading). Always the last line.
- Pots: `usePot` = expense with no category (no budget effect, not editable in quick add, left out
  of the report's Actual). `moveToSection` = move with `budget_save` and a category, pot → this
  month; `isFundedFromPot` tells it apart from a save to a pot, `fundedFromPots` raises the budget.

## Words in the UI
- `FundKind.spending` is shown as **This month** and `FundKind.unplanned` as **Floating**; code and
  enums keep the old names. Neither "Spending" nor picking this fund is offered: Quick add asks for
  an account only (`pickAccount`), `pickPot` hides it unless it is already chosen.
- Expense categories are edited only in Monthly plan → Expenses, income types in → Income
  (`showCategoryEditor`, lib/features/setup/category_editor.dart).

## Monthly plan (lib/ledger/allocation.dart)
- `AllocationPlan` JSON in settings. Dated: base key `allocation_plan`, changes from a month in
  `allocation_plan@YYYY-MM`. Always read with `ledger.planFor(period)` (or `latestPlan`).
- The plan is a **blueprint** used when income arrives (`latestPlan`). `receiveIncome`:
  pots filled at once (moves "Salary plan"), spending part → Spending or the nextMonth fund
  (parked, `IncomeTo.nextMonth`), the rest → the **Floating** fund (`FundKind.unplanned`, not
  monthly). Release on the 1st only moves parked money; it splits only when
  split_on_release_<month> == 'true' (old data). 'done' = split handled.
  `splitHeldSalary` (run on app start) splits a salary parked whole by versions ≤ 1.4.3, for this
  month or last month if not released yet. Editing an income never splits again.
  Plan screen saves to `allocation_plan@<next month>`; its budgets apply from next month.
- Refund = an expense entry with a **negative** amount (`repo.refund`), same category/tracker.

## Settings keys (table `settings`)
allocation_plan(@YYYY-MM), tax_rules, tax_inputs_<year>, income_tax_types, zakat_inputs,
borrow_charge_bp, month_leftover, app_lock, insights_off, home_collapsed, sms_on, sms_since,
sms_handled, sms_senders, last_backup_at, last_auto_backup_at, auto_backup_off,
split_on_release_<YYYY-MM>, theme_mode, theme_palette, theme_pure_black.

## Google Drive backup (lib/data/drive_backup.dart, lib/app/google_drive.dart)
- Weekly, after the local auto backup (`integrations._driveBackup`), when `drive_backup_on` and
  `drive_backup_last` is 7+ days old. Errors go to `drive_backup_error` (shown on the card).
- File = `MFTE1` | salt 16 | nonce 12 | mac 16 | AES-256-GCM(.mft). Key = PBKDF2-SHA256,
  120k rounds, from the password; kept in app support dir `drive_key.json`, never in the DB
  (so never inside a backup). The password is not stored.
- Auth: `google_sign_in` 7 authorization only (no `authenticate`, so no web client id needed),
  scope `drive.appdata`; REST over dart:io `HttpClient`. Files live in `appDataFolder`.
- Google Cloud needs Android OAuth clients for both package names with their SHA-1s.

## Schema history (lib/data/database.dart; fixtures in test/fixtures)
2 investments/purchases/trackers · 3 categories.savings_fund_id · 4 slots + budget_moves ·
5 entries.receipt · 6 entries.budget_save · 7 tracker_amounts · 8 data only: fund names, Misc (`setupFloatingAndMisc`, also run after a restore).
Backups (`backup.dart`) list every table; older backups restore with missing tables empty.

## Android side
- MainActivity: MethodChannel `myfin/sms` (READ_SMS, read-only inbox).
- Widgets: QuickAddWidget (left to spend), FreeToSpendWidget, MonthGlanceWidget (4×2); data written
  by `lib/app/integrations.dart` via home_widget; URIs `myfin://quickadd[?mode=income]`, `myfin://home`.
- Permissions: INTERNET only for "Get today's price" (Zakat; currency-api, no personal data).
- Icon: adaptive (`drawable/ic_launcher_foreground.xml`, ৳ from HindSiliguri); debug uses orange
  background (`src/debug/res`).
