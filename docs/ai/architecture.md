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
- `budgetRoom(category, period)` = budget left to check an expense against (Quick add's
  "Over the X budget" step offers Move budget / Record anyway).
- Month close is manual (`closeMonth`): unused budget → linked pots (`categories.savings_fund_id`),
  slot leftovers back, leftover split.

## Monthly plan (lib/ledger/allocation.dart)
- `AllocationPlan` JSON in settings. Dated: base key `allocation_plan`, changes from a month in
  `allocation_plan@YYYY-MM`. Always read with `ledger.planFor(period)` (or `latestPlan`).
- `IncomeSource.forNextMonth`: salary on the 26th is held in the nextMonth fund and released on
  the 1st (`releaseHeldIncome`, runs the split of that month's plan). `expectedIncome` expects
  next month's planned amount for such income.

## Settings keys (table `settings`)
allocation_plan(@YYYY-MM), tax_rules, tax_inputs_<year>, income_tax_types, zakat_inputs,
borrow_charge_bp, month_leftover, app_lock, insights_off, home_collapsed, sms_on, sms_since,
sms_handled, sms_senders, last_backup_at, last_auto_backup_at, auto_backup_off,
split_on_release_<YYYY-MM>, theme_mode, theme_palette, theme_pure_black.

## Schema history (lib/data/database.dart; fixtures in test/fixtures)
2 investments/purchases/trackers · 3 categories.savings_fund_id · 4 slots + budget_moves ·
5 entries.receipt · 6 entries.budget_save · 7 tracker_amounts.
Backups (`backup.dart`) list every table; older backups restore with missing tables empty.

## Android side
- MainActivity: MethodChannel `myfin/sms` (READ_SMS, read-only inbox).
- Widgets: QuickAddWidget (left to spend), FreeToSpendWidget, MonthGlanceWidget (4×2); data written
  by `lib/app/integrations.dart` via home_widget; URIs `myfin://quickadd[?mode=income]`, `myfin://home`.
- Permissions: INTERNET only for "Get today's price" (Zakat; currency-api, no personal data).
- Icon: adaptive (`drawable/ic_launcher_foreground.xml`, ৳ from HindSiliguri); debug uses orange
  background (`src/debug/res`).
