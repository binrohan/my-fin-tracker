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
enum FundKind { spending, savings, goal, investment }

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
}

enum LoanKind {
  /// Borrowed from Monthly Savings or a goal into Spending.
  ownSavings,

  /// You lent money to a person.
  lent,

  /// You borrowed money from a person.
  borrowed,
}
