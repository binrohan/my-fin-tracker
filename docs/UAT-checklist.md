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

## 13. New in 1.0.7

**Compare with last month**
- [ ] Expenses tab: categories that changed a lot show **↑ 25% vs Sep** (orange) or **↓** (green) under their bar.
- [ ] The **Compared with September** card says which days it compares (e.g. 1–14 Oct against 1–14 Sep) and lists what you spend more and less on.
- [ ] The monthly PDF has a **Compared with …** table.
- [ ] More → Rules → **Compare with last month** off hides all of it.

**Receipt photos**
- [ ] Quick add, expense: the camera icon in the note field → **Take a photo** → save. The entry shows a small receipt icon in All entries.
- [ ] Open the entry: the photo shows; tap it to zoom; **Replace** and **Remove** work.
- [ ] Back up, then look at the backup size: it includes the photos. (Restore on another phone shows them.)

**Bank messages (SMS)**
- [ ] More → Rules → **Suggest entries from SMS** → allow SMS access.
- [ ] After a bKash payment or a City Bank debit, Home → Needs attention shows **1 bank message to add**.
- [ ] **Add** opens Quick add with the amount, date, account and shop filled in. After saving it disappears from the list.
- [ ] **Dismiss** removes a message for good.
- [ ] A cash out / ATM withdrawal is offered as a move to Cash.
- [ ] **Senders**: check bKash and City Bank point at the right accounts. If a message is missed or read wrongly, copy it into Issues below (hide account numbers).

**Tools (More → Tools)**
- [ ] **Can I afford it?**: type a price; the answer changes from **Yes** to **tight**, **from savings**, **Not now** as the price grows. **Save up for it as a goal** creates the goal.
- [ ] **Zakat**: bank, investments and loans are filled in from the app; type over one, the ↺ button brings the app's figure back. Enter silver price a gram → the nisab and the zakat appear.
- [ ] **Income tax**: salary comes from your entries + plan; the steps add up. The ⚙ button edits slabs and rates; Save keeps them.

## 14. New in 1.0.8

- [ ] Zakat → **Get today's price** fills both prices a gram and shows the date. With no internet it shows a message instead.
- [ ] Zakat → **Next zakat date**: pick a date. **On <date>, in N days** shows the expected net and zakat.
- [ ] Pick a date that has already passed: the same date next year is used.
- [ ] Type a different **Wealth grows each month by**: the expected zakat changes. ↺ brings back the app's figure.
- [ ] Income tax: **Full year** and **Up to today** both show; switching changes the steps.

## 15. New in 1.0.9

- [ ] Spend → **New slot**: set **Likely to spend on** to a day 2 days from now → create. The slot card shows the date, and the category list shows **slot · <day> <month>**.
- [ ] Home → Needs attention shows **<slot> in 2 days** with the amount set aside. Tapping it opens Spend.
- [ ] Spend all of the slot's money: the reminder goes away.
- [ ] An older slot without a date: **Set date** adds one; **Change date** moves it.

## 16. New in 1.1.0

**Save to a pot during the month**
- [ ] Link Rice Bag to the Rice Bag pot (More → Categories → Unused budget goes to).
- [ ] Spend → tap **Rice Bag** (or **Save to pot**): the pot and the unspent amount are filled in. Save.
- [ ] Rice Bag shows **saved ৳1,000**; the pot grows by ৳1,000; Left to spend and Budgeted both drop by ৳1,000, and nothing becomes **Short**.
- [ ] If Rice Bag is a fixed bill, it's no longer "due" on Home or in Pay remaining bills.
- [ ] **Undo** (Slots & budget moves card) puts it all back.

**Home**
- [ ] Tap **This month**, **Where it is**, **What it's for** and **Needs attention** headings: each folds and shows a total or count. Close and reopen the app: they stay folded.
- [ ] More → Appearance → Home page → **After bills**: the main card shows **Free to spend** = Left to spend − Bills still to pay, with the sum. **Bills to pay** lists unpaid bills; **Pay all** works.
- [ ] Switch back to **Standard**.

## 17. New in 1.1.1

- [ ] Income tax → Salary note reads like "Recorded ৳… + estimated ৳… for 3 months before your entries + plan ৳… for 8 months to come". July–September (before the app) are included.
- [ ] **Up to today** includes the estimated earlier months.
- [ ] **Which incomes are taxable**: set Bonus to **Not taxable** → it leaves Other taxable income. Set it back.
- [ ] More → Categories → edit an income category: **For income tax** shows the same choice.

## 18. New in 1.2.0

**Raise from next month**
- [ ] More → Monthly plan → change the salary, split and budgets → **Save** → *When should this apply?* → **From November** (already chosen if the salary is "for next month") → Save. The message says October stays as it was.
- [ ] Open the plan again: October's figures, and a yellow **Changes from November** note (Salary ৳85,000 → ৳1,00,000, …). **View / edit** shows November's plan with a bar "October keeps its plan"; **Back to October** returns.
- [ ] Spend tab (October): budgets and Short/Unplanned unchanged.
- [ ] Income tax: July–October at the old salary, November–June at the new one.
- [ ] On 26 Oct the reminder and the Record sheet expect the **new** salary (it is November's money).
- [ ] After 26 Oct salary (For November) → on 1 Nov the release uses the **new split**.
- [ ] **Cancel** on the yellow note brings November back to October's plan.

**Tracker: Add amount**
- [ ] More → Trackers → a tracker → **Add amount** (e.g. ৳3,000, "Paid by Abbu") → it shows under **Outside your accounts** and in the total.
- [ ] Left to spend, balances and the monthly report don't change.
- [ ] Tap it to edit or delete.

## 19. New in 1.3.0: widgets

- [ ] Long-press the home screen → Widgets → My Fin: three widgets are listed: **Left to spend**, **Free to spend**, **Month at a glance**.
- [ ] **Left to spend** works as before.
- [ ] **Free to spend** shows Left to spend minus bills still to pay, with "≈ ৳… a day · after ৳… bills". Same figure as the After bills Home.
- [ ] **Month at a glance** (4×2): month and day, free to spend, the budget bar, "Spent ৳… of ৳…", "Next: … · date · amount".
- [ ] **+ Expense** opens Quick add on Expense; **+ Income** opens it on Income; tapping elsewhere opens the app.
- [ ] Add an expense in the app: all widgets update.
- [ ] App lock on: widgets show **Locked**.

## 20. New in 1.4.0: one Home, and keeping to the budget

- [ ] Home order: **Left to spend this month** → Needs attention → **Bills to pay** → **Recent** → **Where your money is** → **What your money is for**. More → Appearance no longer has a Home page choice.
- [ ] Main card: big **Left to spend after bills**, ≈ a day; tiles **Left to spend** and **Bills to pay**; chips for where the spending money sits (Bank · Cash · bKash).
- [ ] **What your money is for** is short: Spending, Monthly Savings, Saved for things, Carried forward, Unplanned/Short. Tap → every pot, the Bank/Cash table, This month, Net worth.
- [ ] **Budget by category** opens each budget's "left of"; an over category shows **Cover** → Move budget with it filled in.
- [ ] **Recent**: last five entries; tap one for details; **See all** opens All entries.
- [ ] **What your money is for**: short list; tap → every pot, This month, Net worth.
- [ ] Quick add an expense bigger than its category's budget left → **Over the … budget** → **Move ৳…** → pick From → Move → the expense is saved and the category isn't over.
- [ ] Same again → **Record anyway** saves it over budget; **Cancel** goes back to Quick add.

---

## Issues

| # | Section | What I did | Expected | What happened |
|---|---------|-----------|----------|---------------|
| 1 |         |           |          |               |
