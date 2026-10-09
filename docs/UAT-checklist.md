# My Fin Tracker: UAT checklist

Test on your phone in **My Fin Tracker** (the real app, not "My Fin (dev)").
Tick each line when it works. If something is wrong, note it under **Issues** at the end:
what you did, what you expected, what happened, and a screenshot if you can.

Tip: do sections 1–3 on day one, then use the app normally for a few weeks and do the rest as each situation comes up.

---

## 1. Start

- [ ] More → **Delete all data** works (the app may have example data from testing).
- [ ] More → **Starting balances**: enter your real Bank, Cash and bKash amounts, split into Spending and Monthly Savings. Save.
- [ ] Home shows the total you entered under **Where it is**, and the same total under **What it's for**.
- [ ] Home shows **✓ Balanced**.
- [ ] More → **Accounts & pots**: rename or add accounts (another bank, Nagad) and add your real goals with target and date.
- [ ] More → **Categories**: add, rename or archive categories so they match how you spend. Set the due day on fixed bills.
- [ ] More → **Budgets**: enter your monthly budget per category. The total at the bottom is what you expect.
- [ ] More → **Salary plan**: enter what you set aside each month (savings, goals, DPS).

## 2. Every day

- [ ] **+** → type an amount → tap a category → **Save**. It takes three taps.
- [ ] Left to spend on Home goes down by exactly that amount.
- [ ] The category you use most moves to the front of the chips after a few entries.
- [ ] **Paid from** remembers the last account you used.
- [ ] Add an expense with a **note**, and one on an **earlier date**.
- [ ] Add **income**: after Salary, the snackbar offers **Set aside ৳…**. Tapping it moves the money as your plan says.
- [ ] **Move**: Bank → Cash withdrawal. The total doesn't change; Bank goes down and Cash goes up.
- [ ] Spend → **See all** → tap an entry → **Edit** the amount → every total updates.
- [ ] **Delete** an entry → it's gone everywhere.
- [ ] Long-press the app icon → **Add expense** opens quick add.
- [ ] Add the **widget** to your home screen (long-press the home screen → Widgets → My Fin Tracker). It shows Left to spend; **+** opens quick add.

## 3. Backup (do this before trusting it)

- [ ] More → Backup & restore → **Save backup to phone** → choose Downloads. The `.mft` file is there.
- [ ] **Share backup** to Telegram, Drive or email (to yourself).
- [ ] **Automatic backup** shows "Last: …" after you reopen the app.
- [ ] **Restore test:** make a backup → add a test expense → **Restore from file** → the test expense is gone and everything else is as before.

## 4. Spending and bills

- [ ] Spend tab: each category shows actual against budget. Sub-categories (Fixed) open and close.
- [ ] Fixed bills show **paid** or **due on the …**.
- [ ] **Pay N remaining fixed bills** pays them in one step.
- [ ] Going over a budget turns that category red.
- [ ] **Last 6 months** chart appears from the second month on.

## 5. Savings, goals and loans

- [ ] Save tab → tap Monthly Savings → **Deposit** and **Withdraw** work and show in History.
- [ ] A goal shows % done, the monthly amount needed, and **On track** or **Behind**.
- [ ] **Borrow** from savings: the charge (5% by default) is added; Home shows the borrowed amount.
- [ ] **Pay back** part, then the rest. The loan shows as paid and savings get the charge.
- [ ] **New loan → Lend** to a person (new name). Save tab shows "lent out"; net worth is unchanged.
- [ ] **Money received back** from that person.
- [ ] **New loan → Borrow** from a person, then **Pay back**.
- [ ] Goal **Buy it**: records the purchase, the goal shows **Achieved**, and the item appears in **Buying**.

## 6. Cash drawer

- [ ] Home → **Cash drawer** shows cash split by sector.
- [ ] **Count cash** note by note: when it matches, it says so; when it doesn't, the difference is recorded.
- [ ] **Move between sectors** changes the split, not the total.

## 7. Investments, buying, trackers

- [ ] More → Investments → **Add investment** (your DPS or FDR with its current value). Net worth goes up by that value.
- [ ] **Pay instalment** moves money from the bank and the instalment count goes up.
- [ ] **Update value** shows the growth.
- [ ] Quick add → **Major purchase** chip → the item appears in More → **Buying** with its amount.
- [ ] Edit a purchase: add the shop and warranty date.
- [ ] More → Trackers → new **Countdown** (budget and end date). Tag an expense to it in quick add; "left" goes down.
- [ ] New **Project**: tag expenses; "spent so far" adds up.

## 8. Month end

- [ ] On the 1st, Home shows **"<last month> is over"**.
- [ ] **Close**: enter the bank statement balance; if it differs, the difference is recorded.
- [ ] Choose **carry forward** (or move to savings) → the new month starts with that leftover.
- [ ] **View report** opens last month's PDF.
- [ ] More → **Match balance** with your bank app at any time.

## 9. Reports

- [ ] More → Reports & export → a month → the PDF figures match the app.
- [ ] **Share**, **Print** and **Save to phone** work.
- [ ] The **annual report** shows the year so far.
- [ ] **Export for Excel**: open the CSV in Excel. Dates, amounts and Bangla text look right.

## 10. Reminders

- [ ] Home **Needs attention** lists a bill due in the next 3 days.
- [ ] It shows **No backup yet** / **Last backup N days ago** after 7 days without a backup.
- [ ] Tapping a reminder opens the right screen.

## 11. Appearance and security

- [ ] More → Appearance: **System / Light / Dark** switch straight away.
- [ ] **Ocean blue** and **Plum** change the colours everywhere; **Ledger green** brings it back.
- [ ] **Pitch black** in dark mode: the background is fully black.
- [ ] More → **App lock** on → close the app for 1+ minute → reopen → it asks for your fingerprint or PIN.
- [ ] With the app lock on, the widget shows **Locked** instead of the amount.
- [ ] About shows the version.

## 12. Moving to a new phone (optional, any time)

- [ ] Install the app on the other phone → Backup & restore → **Restore from file** → all data is there.

---

## Issues

| # | Section | What I did | Expected | What happened |
|---|---------|-----------|----------|---------------|
| 1 |         |           |          |               |
