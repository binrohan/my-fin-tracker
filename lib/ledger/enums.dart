/// Where money physically is.
enum AccountType {
  bank,
  cash,
  wallet,
  investment,

  /// Someone you lent to (balance above zero: they owe you) or borrowed
  /// from (balance below zero: you owe them).
  person;

  /// Money you can spend today. Investments and people are excluded.
  bool get isLiquid => this == bank || this == cash || this == wallet;
}

/// What money is for.
enum FundKind {
  spending,
  savings,
  goal,
  investment,

  /// Income received this month for next month (salary on the 26th), held
  /// apart until the 1st, when it is released into Spending.
  nextMonth,

  /// Money nothing is planned for yet, not tied to any month: what is left
  /// of an income after its split and its spending part.
  unplanned,
}

enum CategoryKind { expense, income }

/// The user action behind a group of postings.
enum EntryType {
  /// Starting balance, or an existing loan, when you begin using the app.
  opening,
  income,
  expense,

  /// Money changes account and/or fund: set aside to savings, cash
  /// withdrawal, DPS instalment.
  move,

  /// Borrow from your own savings or from a person.
  borrow,

  /// Pay back what you borrowed.
  repay,

  /// Lend to a person.
  lend,

  /// A person pays you back.
  collect,

  /// Charge added to a loan with a person.
  charge,

  /// Correction after matching a real balance, or an investment value update.
  adjust,

  /// Income held for this month released into Spending on the 1st.
  release,
}

enum LoanKind {
  /// Borrowed from Monthly Savings or a goal into Spending.
  ownSavings,

  /// You lent money to a person.
  lent,

  /// You borrowed money from a person.
  borrowed,
}

enum InvestmentKind { dps, fdr, savingsCertificate, shares, other }

enum TrackerKind {
  /// Long-term spending with no limit: how much it cost so far.
  project,

  /// A budget with an end date: how much is left.
  countdown,
}

/// Where an income goes when it arrives (after its split, if any).
enum IncomeTo {
  /// Spending money now.
  spending,

  /// Parked for next month; released into Spending on the 1st.
  nextMonth,

  /// The Unplanned pot.
  unplanned,

  /// A savings pot or goal.
  pot,
}
