import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

void main() {
  late AppDatabase db;
  late LedgerRepository repo;
  late int bank, spending, savings, friend;
  final day = DateTime(2026, 10, 1);

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    repo = LedgerRepository(db);
    final l = await Ledger.load(db);
    bank = l.accounts.values.firstWhere((a) => a.type == AccountType.bank).id;
    spending = l.spendingFund.id;
    savings = l.funds.values.firstWhere((f) => f.kind == FundKind.savings).id;
    friend = await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: 'Friend', type: AccountType.person));
    await repo.openingBalance(day, (account: bank, fund: savings), taka(50000));
    await repo.openingBalance(day, (account: bank, fund: spending), taka(10000));
  });

  tearDown(() => db.close());

  test('own-savings loan: charge comes back to the source fund', () async {
    final loan = await repo.borrowFromFund(
      day,
      taka(3000),
      sourceFund: savings,
      intoFund: spending,
      account: bank,
      chargeRateBp: 500,
    );
    var l = await Ledger.load(db);
    expect(l.fundBalance(savings), taka(47000));
    expect(l.fundBalance(spending), taka(13000));
    expect(l.loanStatus(l.loans.single).due, taka(3150));

    await repo.repayOwnLoan(loan, day, taka(3150), from: (account: bank, fund: spending));
    l = await Ledger.load(db);
    expect(l.fundBalance(savings), taka(50150), reason: 'savings gain the 150 charge');
    expect(l.fundBalance(spending), taka(9850));
    expect(l.openLoans(), isEmpty);
    expect(l.netWorth(), taka(60000), reason: 'internal loans never change net worth');
  });

  test('lending to a person with a charge', () async {
    final loan = await repo.lendToPerson(
      day,
      taka(10000),
      person: friend,
      from: (account: bank, fund: savings),
      chargeRateBp: 200,
    );
    var l = await Ledger.load(db);
    expect(l.fundBalance(savings), taka(40000), reason: 'not in your hands');
    expect(l.fundBalance(savings, liquidOnly: false), taka(50200));
    expect(l.accountBalance(friend), taka(10200));
    expect(l.netWorth(), taka(60200));

    await repo.collectFromPerson(loan, day, taka(4000), toAccount: bank);
    l = await Ledger.load(db);
    expect(l.loanStatus(l.loans.single).remaining, taka(6200));
    expect(l.fundBalance(savings), taka(44000));
    expect(l.isBalanced, isTrue);
  });

  test('borrowing from a person', () async {
    final loan = await repo.borrowFromPerson(
      day,
      taka(15000),
      person: friend,
      to: (account: bank, fund: spending),
    );
    var l = await Ledger.load(db);
    expect(l.fundBalance(spending), taka(25000));
    expect(l.accountBalance(friend), taka(-15000));
    expect(l.netWorth(), taka(60000));

    await repo.repayPerson(loan, day, taka(5000), fromAccount: bank);
    l = await Ledger.load(db);
    expect(l.loanStatus(l.loans.single).remaining, taka(10000));
    expect(l.accountBalance(friend), taka(-10000));
    expect(l.fundBalance(spending), taka(20000));
  });

  test('deleting an entry removes its postings', () async {
    final id = await repo.move(
      day,
      taka(1000),
      from: (account: bank, fund: spending),
      to: (account: bank, fund: savings),
    );
    await repo.deleteEntry(id);
    final l = await Ledger.load(db);
    expect(l.fundBalance(spending), taka(10000));
    expect(l.lines.where((p) => p.entryId == id), isEmpty);
  });
}
