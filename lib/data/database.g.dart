// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<AccountType>($AccountsTable.$convertertype);
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, type, sortOrder, archived];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $AccountsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $convertertype =
      const EnumNameConverter<AccountType>(AccountType.values);
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String name;
  final AccountType type;
  final int sortOrder;
  final bool archived;
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.sortOrder,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($AccountsTable.$convertertype.toSql(type));
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $AccountsTable.$convertertype.fromJson(serializer.fromJson<String>(json['type'])),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>($AccountsTable.$convertertype.toJson(type)),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Account copyWith({int? id, String? name, AccountType? type, int? sortOrder, bool? archived}) =>
      Account(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        sortOrder: sortOrder ?? this.sortOrder,
        archived: archived ?? this.archived,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, sortOrder, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> name;
  final Value<AccountType> type;
  final Value<int> sortOrder;
  final Value<bool> archived;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required AccountType type,
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  }) : name = Value(name),
       type = Value(type);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<AccountType>? type,
    Value<int>? sortOrder,
    Value<bool>? archived,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>($AccountsTable.$convertertype.toSql(type.value));
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }
}

class $FundsTable extends Funds with TableInfo<$FundsTable, Fund> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FundKind, String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<FundKind>($FundsTable.$converterkind);
  static const VerificationMeta _targetAmountMeta = const VerificationMeta('targetAmount');
  @override
  late final GeneratedColumn<int> targetAmount = GeneratedColumn<int>(
    'target_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _achievedAtMeta = const VerificationMeta('achievedAt');
  @override
  late final GeneratedColumn<DateTime> achievedAt = GeneratedColumn<DateTime>(
    'achieved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    targetAmount,
    targetDate,
    achievedAt,
    sortOrder,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'funds';
  @override
  VerificationContext validateIntegrity(Insertable<Fund> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(data['target_amount']!, _targetAmountMeta),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('achieved_at')) {
      context.handle(
        _achievedAtMeta,
        achievedAt.isAcceptableOrUnknown(data['achieved_at']!, _achievedAtMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Fund map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Fund(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: $FundsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      ),
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_amount'],
      ),
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      ),
      achievedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}achieved_at'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $FundsTable createAlias(String alias) {
    return $FundsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FundKind, String, String> $converterkind =
      const EnumNameConverter<FundKind>(FundKind.values);
}

class Fund extends DataClass implements Insertable<Fund> {
  final int id;
  final String name;
  final FundKind kind;
  final int? targetAmount;
  final DateTime? targetDate;
  final DateTime? achievedAt;
  final int sortOrder;
  final bool archived;
  const Fund({
    required this.id,
    required this.name,
    required this.kind,
    this.targetAmount,
    this.targetDate,
    this.achievedAt,
    required this.sortOrder,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>($FundsTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || targetAmount != null) {
      map['target_amount'] = Variable<int>(targetAmount);
    }
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    if (!nullToAbsent || achievedAt != null) {
      map['achieved_at'] = Variable<DateTime>(achievedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  FundsCompanion toCompanion(bool nullToAbsent) {
    return FundsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      targetAmount: targetAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAmount),
      targetDate: targetDate == null && nullToAbsent ? const Value.absent() : Value(targetDate),
      achievedAt: achievedAt == null && nullToAbsent ? const Value.absent() : Value(achievedAt),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
    );
  }

  factory Fund.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Fund(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $FundsTable.$converterkind.fromJson(serializer.fromJson<String>(json['kind'])),
      targetAmount: serializer.fromJson<int?>(json['targetAmount']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      achievedAt: serializer.fromJson<DateTime?>(json['achievedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>($FundsTable.$converterkind.toJson(kind)),
      'targetAmount': serializer.toJson<int?>(targetAmount),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'achievedAt': serializer.toJson<DateTime?>(achievedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Fund copyWith({
    int? id,
    String? name,
    FundKind? kind,
    Value<int?> targetAmount = const Value.absent(),
    Value<DateTime?> targetDate = const Value.absent(),
    Value<DateTime?> achievedAt = const Value.absent(),
    int? sortOrder,
    bool? archived,
  }) => Fund(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    targetAmount: targetAmount.present ? targetAmount.value : this.targetAmount,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    achievedAt: achievedAt.present ? achievedAt.value : this.achievedAt,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
  );
  Fund copyWithCompanion(FundsCompanion data) {
    return Fund(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      targetAmount: data.targetAmount.present ? data.targetAmount.value : this.targetAmount,
      targetDate: data.targetDate.present ? data.targetDate.value : this.targetDate,
      achievedAt: data.achievedAt.present ? data.achievedAt.value : this.achievedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Fund(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetDate: $targetDate, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, kind, targetAmount, targetDate, achievedAt, sortOrder, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fund &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.targetAmount == this.targetAmount &&
          other.targetDate == this.targetDate &&
          other.achievedAt == this.achievedAt &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived);
}

class FundsCompanion extends UpdateCompanion<Fund> {
  final Value<int> id;
  final Value<String> name;
  final Value<FundKind> kind;
  final Value<int?> targetAmount;
  final Value<DateTime?> targetDate;
  final Value<DateTime?> achievedAt;
  final Value<int> sortOrder;
  final Value<bool> archived;
  const FundsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  });
  FundsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required FundKind kind,
    this.targetAmount = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind);
  static Insertable<Fund> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? targetAmount,
    Expression<DateTime>? targetDate,
    Expression<DateTime>? achievedAt,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (targetDate != null) 'target_date': targetDate,
      if (achievedAt != null) 'achieved_at': achievedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
    });
  }

  FundsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<FundKind>? kind,
    Value<int?>? targetAmount,
    Value<DateTime?>? targetDate,
    Value<DateTime?>? achievedAt,
    Value<int>? sortOrder,
    Value<bool>? archived,
  }) {
    return FundsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      achievedAt: achievedAt ?? this.achievedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>($FundsTable.$converterkind.toSql(kind.value));
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<int>(targetAmount.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (achievedAt.present) {
      map['achieved_at'] = Variable<DateTime>(achievedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FundsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetDate: $targetDate, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryKind, String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<CategoryKind>($CategoriesTable.$converterkind);
  static const VerificationMeta _isFixedMeta = const VerificationMeta('isFixed');
  @override
  late final GeneratedColumn<bool> isFixed = GeneratedColumn<bool>(
    'is_fixed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_fixed" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savingsFundIdMeta = const VerificationMeta('savingsFundId');
  @override
  late final GeneratedColumn<int> savingsFundId = GeneratedColumn<int>(
    'savings_fund_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES funds (id)'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    name,
    kind,
    isFixed,
    dueDay,
    savingsFundId,
    sortOrder,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_fixed')) {
      context.handle(_isFixedMeta, isFixed.isAcceptableOrUnknown(data['is_fixed']!, _isFixedMeta));
    }
    if (data.containsKey('due_day')) {
      context.handle(_dueDayMeta, dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta));
    }
    if (data.containsKey('savings_fund_id')) {
      context.handle(
        _savingsFundIdMeta,
        savingsFundId.isAcceptableOrUnknown(data['savings_fund_id']!, _savingsFundIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: $CategoriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      ),
      isFixed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_fixed'],
      )!,
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      ),
      savingsFundId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}savings_fund_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryKind, String, String> $converterkind =
      const EnumNameConverter<CategoryKind>(CategoryKind.values);
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final int? parentId;
  final String name;
  final CategoryKind kind;
  final bool isFixed;

  /// Day of the month a fixed bill is due.
  final int? dueDay;

  /// Savings pot or goal that receives this category's unused budget when
  /// a month is closed.
  final int? savingsFundId;
  final int sortOrder;
  final bool archived;
  const CategoryRow({
    required this.id,
    this.parentId,
    required this.name,
    required this.kind,
    required this.isFixed,
    this.dueDay,
    this.savingsFundId,
    required this.sortOrder,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>($CategoriesTable.$converterkind.toSql(kind));
    }
    map['is_fixed'] = Variable<bool>(isFixed);
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    if (!nullToAbsent || savingsFundId != null) {
      map['savings_fund_id'] = Variable<int>(savingsFundId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent ? const Value.absent() : Value(parentId),
      name: Value(name),
      kind: Value(kind),
      isFixed: Value(isFixed),
      dueDay: dueDay == null && nullToAbsent ? const Value.absent() : Value(dueDay),
      savingsFundId: savingsFundId == null && nullToAbsent
          ? const Value.absent()
          : Value(savingsFundId),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
    );
  }

  factory CategoryRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      kind: $CategoriesTable.$converterkind.fromJson(serializer.fromJson<String>(json['kind'])),
      isFixed: serializer.fromJson<bool>(json['isFixed']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      savingsFundId: serializer.fromJson<int?>(json['savingsFundId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'parentId': serializer.toJson<int?>(parentId),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>($CategoriesTable.$converterkind.toJson(kind)),
      'isFixed': serializer.toJson<bool>(isFixed),
      'dueDay': serializer.toJson<int?>(dueDay),
      'savingsFundId': serializer.toJson<int?>(savingsFundId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  CategoryRow copyWith({
    int? id,
    Value<int?> parentId = const Value.absent(),
    String? name,
    CategoryKind? kind,
    bool? isFixed,
    Value<int?> dueDay = const Value.absent(),
    Value<int?> savingsFundId = const Value.absent(),
    int? sortOrder,
    bool? archived,
  }) => CategoryRow(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    isFixed: isFixed ?? this.isFixed,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    savingsFundId: savingsFundId.present ? savingsFundId.value : this.savingsFundId,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      isFixed: data.isFixed.present ? data.isFixed.value : this.isFixed,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      savingsFundId: data.savingsFundId.present ? data.savingsFundId.value : this.savingsFundId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('isFixed: $isFixed, ')
          ..write('dueDay: $dueDay, ')
          ..write('savingsFundId: $savingsFundId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, parentId, name, kind, isFixed, dueDay, savingsFundId, sortOrder, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.isFixed == this.isFixed &&
          other.dueDay == this.dueDay &&
          other.savingsFundId == this.savingsFundId &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<int?> parentId;
  final Value<String> name;
  final Value<CategoryKind> kind;
  final Value<bool> isFixed;
  final Value<int?> dueDay;
  final Value<int?> savingsFundId;
  final Value<int> sortOrder;
  final Value<bool> archived;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.isFixed = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.savingsFundId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    required String name,
    required CategoryKind kind,
    this.isFixed = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.savingsFundId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<int>? parentId,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<bool>? isFixed,
    Expression<int>? dueDay,
    Expression<int>? savingsFundId,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (isFixed != null) 'is_fixed': isFixed,
      if (dueDay != null) 'due_day': dueDay,
      if (savingsFundId != null) 'savings_fund_id': savingsFundId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<int?>? parentId,
    Value<String>? name,
    Value<CategoryKind>? kind,
    Value<bool>? isFixed,
    Value<int?>? dueDay,
    Value<int?>? savingsFundId,
    Value<int>? sortOrder,
    Value<bool>? archived,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      isFixed: isFixed ?? this.isFixed,
      dueDay: dueDay ?? this.dueDay,
      savingsFundId: savingsFundId ?? this.savingsFundId,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>($CategoriesTable.$converterkind.toSql(kind.value));
    }
    if (isFixed.present) {
      map['is_fixed'] = Variable<bool>(isFixed.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (savingsFundId.present) {
      map['savings_fund_id'] = Variable<int>(savingsFundId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('isFixed: $isFixed, ')
          ..write('dueDay: $dueDay, ')
          ..write('savingsFundId: $savingsFundId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }
}

class $LoansTable extends Loans with TableInfo<$LoansTable, Loan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LoanKind, String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<LoanKind>($LoansTable.$converterkind);
  static const VerificationMeta _personAccountIdMeta = const VerificationMeta('personAccountId');
  @override
  late final GeneratedColumn<int> personAccountId = GeneratedColumn<int>(
    'person_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'),
  );
  static const VerificationMeta _fundIdMeta = const VerificationMeta('fundId');
  @override
  late final GeneratedColumn<int> fundId = GeneratedColumn<int>(
    'fund_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES funds (id)'),
  );
  static const VerificationMeta _principalMeta = const VerificationMeta('principal');
  @override
  late final GeneratedColumn<int> principal = GeneratedColumn<int>(
    'principal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chargeRateBpMeta = const VerificationMeta('chargeRateBp');
  @override
  late final GeneratedColumn<int> chargeRateBp = GeneratedColumn<int>(
    'charge_rate_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _chargeMeta = const VerificationMeta('charge');
  @override
  late final GeneratedColumn<int> charge = GeneratedColumn<int>(
    'charge',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _openingRepaidMeta = const VerificationMeta('openingRepaid');
  @override
  late final GeneratedColumn<int> openingRepaid = GeneratedColumn<int>(
    'opening_repaid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    personAccountId,
    fundId,
    principal,
    chargeRateBp,
    charge,
    openingRepaid,
    date,
    dueDate,
    note,
    closedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loans';
  @override
  VerificationContext validateIntegrity(Insertable<Loan> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_account_id')) {
      context.handle(
        _personAccountIdMeta,
        personAccountId.isAcceptableOrUnknown(data['person_account_id']!, _personAccountIdMeta),
      );
    }
    if (data.containsKey('fund_id')) {
      context.handle(_fundIdMeta, fundId.isAcceptableOrUnknown(data['fund_id']!, _fundIdMeta));
    } else if (isInserting) {
      context.missing(_fundIdMeta);
    }
    if (data.containsKey('principal')) {
      context.handle(
        _principalMeta,
        principal.isAcceptableOrUnknown(data['principal']!, _principalMeta),
      );
    } else if (isInserting) {
      context.missing(_principalMeta);
    }
    if (data.containsKey('charge_rate_bp')) {
      context.handle(
        _chargeRateBpMeta,
        chargeRateBp.isAcceptableOrUnknown(data['charge_rate_bp']!, _chargeRateBpMeta),
      );
    }
    if (data.containsKey('charge')) {
      context.handle(_chargeMeta, charge.isAcceptableOrUnknown(data['charge']!, _chargeMeta));
    }
    if (data.containsKey('opening_repaid')) {
      context.handle(
        _openingRepaidMeta,
        openingRepaid.isAcceptableOrUnknown(data['opening_repaid']!, _openingRepaidMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta, dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Loan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Loan(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kind: $LoansTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      ),
      personAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_account_id'],
      ),
      fundId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fund_id'],
      )!,
      principal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}principal'],
      )!,
      chargeRateBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}charge_rate_bp'],
      )!,
      charge: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}charge'],
      )!,
      openingRepaid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_repaid'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
    );
  }

  @override
  $LoansTable createAlias(String alias) {
    return $LoansTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LoanKind, String, String> $converterkind =
      const EnumNameConverter<LoanKind>(LoanKind.values);
}

class Loan extends DataClass implements Insertable<Loan> {
  final int id;
  final LoanKind kind;

  /// The person for [LoanKind.lent] and [LoanKind.borrowed].
  final int? personAccountId;

  /// Own savings: the fund borrowed from. People: the fund the money left
  /// from or went into, and returns to.
  final int fundId;
  final int principal;

  /// Charge rate in basis points: 500 = 5%.
  final int chargeRateBp;
  final int charge;

  /// Already repaid before the loan was entered in the app.
  final int openingRepaid;
  final DateTime date;
  final DateTime? dueDate;
  final String note;
  final DateTime? closedAt;
  const Loan({
    required this.id,
    required this.kind,
    this.personAccountId,
    required this.fundId,
    required this.principal,
    required this.chargeRateBp,
    required this.charge,
    required this.openingRepaid,
    required this.date,
    this.dueDate,
    required this.note,
    this.closedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<String>($LoansTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || personAccountId != null) {
      map['person_account_id'] = Variable<int>(personAccountId);
    }
    map['fund_id'] = Variable<int>(fundId);
    map['principal'] = Variable<int>(principal);
    map['charge_rate_bp'] = Variable<int>(chargeRateBp);
    map['charge'] = Variable<int>(charge);
    map['opening_repaid'] = Variable<int>(openingRepaid);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    return map;
  }

  LoansCompanion toCompanion(bool nullToAbsent) {
    return LoansCompanion(
      id: Value(id),
      kind: Value(kind),
      personAccountId: personAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(personAccountId),
      fundId: Value(fundId),
      principal: Value(principal),
      chargeRateBp: Value(chargeRateBp),
      charge: Value(charge),
      openingRepaid: Value(openingRepaid),
      date: Value(date),
      dueDate: dueDate == null && nullToAbsent ? const Value.absent() : Value(dueDate),
      note: Value(note),
      closedAt: closedAt == null && nullToAbsent ? const Value.absent() : Value(closedAt),
    );
  }

  factory Loan.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Loan(
      id: serializer.fromJson<int>(json['id']),
      kind: $LoansTable.$converterkind.fromJson(serializer.fromJson<String>(json['kind'])),
      personAccountId: serializer.fromJson<int?>(json['personAccountId']),
      fundId: serializer.fromJson<int>(json['fundId']),
      principal: serializer.fromJson<int>(json['principal']),
      chargeRateBp: serializer.fromJson<int>(json['chargeRateBp']),
      charge: serializer.fromJson<int>(json['charge']),
      openingRepaid: serializer.fromJson<int>(json['openingRepaid']),
      date: serializer.fromJson<DateTime>(json['date']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      note: serializer.fromJson<String>(json['note']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>($LoansTable.$converterkind.toJson(kind)),
      'personAccountId': serializer.toJson<int?>(personAccountId),
      'fundId': serializer.toJson<int>(fundId),
      'principal': serializer.toJson<int>(principal),
      'chargeRateBp': serializer.toJson<int>(chargeRateBp),
      'charge': serializer.toJson<int>(charge),
      'openingRepaid': serializer.toJson<int>(openingRepaid),
      'date': serializer.toJson<DateTime>(date),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'note': serializer.toJson<String>(note),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
    };
  }

  Loan copyWith({
    int? id,
    LoanKind? kind,
    Value<int?> personAccountId = const Value.absent(),
    int? fundId,
    int? principal,
    int? chargeRateBp,
    int? charge,
    int? openingRepaid,
    DateTime? date,
    Value<DateTime?> dueDate = const Value.absent(),
    String? note,
    Value<DateTime?> closedAt = const Value.absent(),
  }) => Loan(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    personAccountId: personAccountId.present ? personAccountId.value : this.personAccountId,
    fundId: fundId ?? this.fundId,
    principal: principal ?? this.principal,
    chargeRateBp: chargeRateBp ?? this.chargeRateBp,
    charge: charge ?? this.charge,
    openingRepaid: openingRepaid ?? this.openingRepaid,
    date: date ?? this.date,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    note: note ?? this.note,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
  );
  Loan copyWithCompanion(LoansCompanion data) {
    return Loan(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      personAccountId: data.personAccountId.present
          ? data.personAccountId.value
          : this.personAccountId,
      fundId: data.fundId.present ? data.fundId.value : this.fundId,
      principal: data.principal.present ? data.principal.value : this.principal,
      chargeRateBp: data.chargeRateBp.present ? data.chargeRateBp.value : this.chargeRateBp,
      charge: data.charge.present ? data.charge.value : this.charge,
      openingRepaid: data.openingRepaid.present ? data.openingRepaid.value : this.openingRepaid,
      date: data.date.present ? data.date.value : this.date,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      note: data.note.present ? data.note.value : this.note,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Loan(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('personAccountId: $personAccountId, ')
          ..write('fundId: $fundId, ')
          ..write('principal: $principal, ')
          ..write('chargeRateBp: $chargeRateBp, ')
          ..write('charge: $charge, ')
          ..write('openingRepaid: $openingRepaid, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    personAccountId,
    fundId,
    principal,
    chargeRateBp,
    charge,
    openingRepaid,
    date,
    dueDate,
    note,
    closedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Loan &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.personAccountId == this.personAccountId &&
          other.fundId == this.fundId &&
          other.principal == this.principal &&
          other.chargeRateBp == this.chargeRateBp &&
          other.charge == this.charge &&
          other.openingRepaid == this.openingRepaid &&
          other.date == this.date &&
          other.dueDate == this.dueDate &&
          other.note == this.note &&
          other.closedAt == this.closedAt);
}

class LoansCompanion extends UpdateCompanion<Loan> {
  final Value<int> id;
  final Value<LoanKind> kind;
  final Value<int?> personAccountId;
  final Value<int> fundId;
  final Value<int> principal;
  final Value<int> chargeRateBp;
  final Value<int> charge;
  final Value<int> openingRepaid;
  final Value<DateTime> date;
  final Value<DateTime?> dueDate;
  final Value<String> note;
  final Value<DateTime?> closedAt;
  const LoansCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.personAccountId = const Value.absent(),
    this.fundId = const Value.absent(),
    this.principal = const Value.absent(),
    this.chargeRateBp = const Value.absent(),
    this.charge = const Value.absent(),
    this.openingRepaid = const Value.absent(),
    this.date = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.closedAt = const Value.absent(),
  });
  LoansCompanion.insert({
    this.id = const Value.absent(),
    required LoanKind kind,
    this.personAccountId = const Value.absent(),
    required int fundId,
    required int principal,
    this.chargeRateBp = const Value.absent(),
    this.charge = const Value.absent(),
    this.openingRepaid = const Value.absent(),
    required DateTime date,
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.closedAt = const Value.absent(),
  }) : kind = Value(kind),
       fundId = Value(fundId),
       principal = Value(principal),
       date = Value(date);
  static Insertable<Loan> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? personAccountId,
    Expression<int>? fundId,
    Expression<int>? principal,
    Expression<int>? chargeRateBp,
    Expression<int>? charge,
    Expression<int>? openingRepaid,
    Expression<DateTime>? date,
    Expression<DateTime>? dueDate,
    Expression<String>? note,
    Expression<DateTime>? closedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (personAccountId != null) 'person_account_id': personAccountId,
      if (fundId != null) 'fund_id': fundId,
      if (principal != null) 'principal': principal,
      if (chargeRateBp != null) 'charge_rate_bp': chargeRateBp,
      if (charge != null) 'charge': charge,
      if (openingRepaid != null) 'opening_repaid': openingRepaid,
      if (date != null) 'date': date,
      if (dueDate != null) 'due_date': dueDate,
      if (note != null) 'note': note,
      if (closedAt != null) 'closed_at': closedAt,
    });
  }

  LoansCompanion copyWith({
    Value<int>? id,
    Value<LoanKind>? kind,
    Value<int?>? personAccountId,
    Value<int>? fundId,
    Value<int>? principal,
    Value<int>? chargeRateBp,
    Value<int>? charge,
    Value<int>? openingRepaid,
    Value<DateTime>? date,
    Value<DateTime?>? dueDate,
    Value<String>? note,
    Value<DateTime?>? closedAt,
  }) {
    return LoansCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      personAccountId: personAccountId ?? this.personAccountId,
      fundId: fundId ?? this.fundId,
      principal: principal ?? this.principal,
      chargeRateBp: chargeRateBp ?? this.chargeRateBp,
      charge: charge ?? this.charge,
      openingRepaid: openingRepaid ?? this.openingRepaid,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>($LoansTable.$converterkind.toSql(kind.value));
    }
    if (personAccountId.present) {
      map['person_account_id'] = Variable<int>(personAccountId.value);
    }
    if (fundId.present) {
      map['fund_id'] = Variable<int>(fundId.value);
    }
    if (principal.present) {
      map['principal'] = Variable<int>(principal.value);
    }
    if (chargeRateBp.present) {
      map['charge_rate_bp'] = Variable<int>(chargeRateBp.value);
    }
    if (charge.present) {
      map['charge'] = Variable<int>(charge.value);
    }
    if (openingRepaid.present) {
      map['opening_repaid'] = Variable<int>(openingRepaid.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoansCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('personAccountId: $personAccountId, ')
          ..write('fundId: $fundId, ')
          ..write('principal: $principal, ')
          ..write('chargeRateBp: $chargeRateBp, ')
          ..write('charge: $charge, ')
          ..write('openingRepaid: $openingRepaid, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EntryType, String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<EntryType>($EntriesTable.$convertertype);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'),
  );
  static const VerificationMeta _loanIdMeta = const VerificationMeta('loanId');
  @override
  late final GeneratedColumn<int> loanId = GeneratedColumn<int>(
    'loan_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES loans (id)'),
  );
  static const VerificationMeta _trackerIdMeta = const VerificationMeta('trackerId');
  @override
  late final GeneratedColumn<int> trackerId = GeneratedColumn<int>(
    'tracker_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    type,
    amount,
    categoryId,
    loanId,
    trackerId,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(Insertable<Entry> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('loan_id')) {
      context.handle(_loanIdMeta, loanId.isAcceptableOrUnknown(data['loan_id']!, _loanIdMeta));
    }
    if (data.containsKey('tracker_id')) {
      context.handle(
        _trackerIdMeta,
        trackerId.isAcceptableOrUnknown(data['tracker_id']!, _trackerIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      type: $EntriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      loanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loan_id'],
      ),
      trackerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tracker_id'],
      ),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EntryType, String, String> $convertertype =
      const EnumNameConverter<EntryType>(EntryType.values);
}

class Entry extends DataClass implements Insertable<Entry> {
  final int id;
  final DateTime date;
  final EntryType type;

  /// The amount as the user entered it, always positive.
  final int amount;
  final int? categoryId;
  final int? loanId;

  /// Project or countdown tag (trackers arrive in Phase 4).
  final int? trackerId;
  final String note;
  final DateTime createdAt;
  const Entry({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    this.categoryId,
    this.loanId,
    this.trackerId,
    required this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    {
      map['type'] = Variable<String>($EntriesTable.$convertertype.toSql(type));
    }
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || loanId != null) {
      map['loan_id'] = Variable<int>(loanId);
    }
    if (!nullToAbsent || trackerId != null) {
      map['tracker_id'] = Variable<int>(trackerId);
    }
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      date: Value(date),
      type: Value(type),
      amount: Value(amount),
      categoryId: categoryId == null && nullToAbsent ? const Value.absent() : Value(categoryId),
      loanId: loanId == null && nullToAbsent ? const Value.absent() : Value(loanId),
      trackerId: trackerId == null && nullToAbsent ? const Value.absent() : Value(trackerId),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Entry.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      type: $EntriesTable.$convertertype.fromJson(serializer.fromJson<String>(json['type'])),
      amount: serializer.fromJson<int>(json['amount']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      loanId: serializer.fromJson<int?>(json['loanId']),
      trackerId: serializer.fromJson<int?>(json['trackerId']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'type': serializer.toJson<String>($EntriesTable.$convertertype.toJson(type)),
      'amount': serializer.toJson<int>(amount),
      'categoryId': serializer.toJson<int?>(categoryId),
      'loanId': serializer.toJson<int?>(loanId),
      'trackerId': serializer.toJson<int?>(trackerId),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Entry copyWith({
    int? id,
    DateTime? date,
    EntryType? type,
    int? amount,
    Value<int?> categoryId = const Value.absent(),
    Value<int?> loanId = const Value.absent(),
    Value<int?> trackerId = const Value.absent(),
    String? note,
    DateTime? createdAt,
  }) => Entry(
    id: id ?? this.id,
    date: date ?? this.date,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    loanId: loanId.present ? loanId.value : this.loanId,
    trackerId: trackerId.present ? trackerId.value : this.trackerId,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      loanId: data.loanId.present ? data.loanId.value : this.loanId,
      trackerId: data.trackerId.present ? data.trackerId.value : this.trackerId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('loanId: $loanId, ')
          ..write('trackerId: $trackerId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, type, amount, categoryId, loanId, trackerId, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.date == this.date &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.categoryId == this.categoryId &&
          other.loanId == this.loanId &&
          other.trackerId == this.trackerId &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<EntryType> type;
  final Value<int> amount;
  final Value<int?> categoryId;
  final Value<int?> loanId;
  final Value<int?> trackerId;
  final Value<String> note;
  final Value<DateTime> createdAt;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.loanId = const Value.absent(),
    this.trackerId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required EntryType type,
    required int amount,
    this.categoryId = const Value.absent(),
    this.loanId = const Value.absent(),
    this.trackerId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : date = Value(date),
       type = Value(type),
       amount = Value(amount);
  static Insertable<Entry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<int>? categoryId,
    Expression<int>? loanId,
    Expression<int>? trackerId,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (loanId != null) 'loan_id': loanId,
      if (trackerId != null) 'tracker_id': trackerId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<EntryType>? type,
    Value<int>? amount,
    Value<int?>? categoryId,
    Value<int?>? loanId,
    Value<int?>? trackerId,
    Value<String>? note,
    Value<DateTime>? createdAt,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      loanId: loanId ?? this.loanId,
      trackerId: trackerId ?? this.trackerId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>($EntriesTable.$convertertype.toSql(type.value));
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (loanId.present) {
      map['loan_id'] = Variable<int>(loanId.value);
    }
    if (trackerId.present) {
      map['tracker_id'] = Variable<int>(trackerId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('loanId: $loanId, ')
          ..write('trackerId: $trackerId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PostingsTable extends Postings with TableInfo<$PostingsTable, Posting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'),
  );
  static const VerificationMeta _fundIdMeta = const VerificationMeta('fundId');
  @override
  late final GeneratedColumn<int> fundId = GeneratedColumn<int>(
    'fund_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES funds (id)'),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, entryId, accountId, fundId, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'postings';
  @override
  VerificationContext validateIntegrity(Insertable<Posting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta, entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('fund_id')) {
      context.handle(_fundIdMeta, fundId.isAcceptableOrUnknown(data['fund_id']!, _fundIdMeta));
    } else if (isInserting) {
      context.missing(_fundIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Posting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Posting(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      fundId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fund_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $PostingsTable createAlias(String alias) {
    return $PostingsTable(attachedDatabase, alias);
  }
}

class Posting extends DataClass implements Insertable<Posting> {
  final int id;
  final int entryId;
  final int accountId;
  final int fundId;
  final int amount;
  const Posting({
    required this.id,
    required this.entryId,
    required this.accountId,
    required this.fundId,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<int>(entryId);
    map['account_id'] = Variable<int>(accountId);
    map['fund_id'] = Variable<int>(fundId);
    map['amount'] = Variable<int>(amount);
    return map;
  }

  PostingsCompanion toCompanion(bool nullToAbsent) {
    return PostingsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      accountId: Value(accountId),
      fundId: Value(fundId),
      amount: Value(amount),
    );
  }

  factory Posting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Posting(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      accountId: serializer.fromJson<int>(json['accountId']),
      fundId: serializer.fromJson<int>(json['fundId']),
      amount: serializer.fromJson<int>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<int>(entryId),
      'accountId': serializer.toJson<int>(accountId),
      'fundId': serializer.toJson<int>(fundId),
      'amount': serializer.toJson<int>(amount),
    };
  }

  Posting copyWith({int? id, int? entryId, int? accountId, int? fundId, int? amount}) => Posting(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    accountId: accountId ?? this.accountId,
    fundId: fundId ?? this.fundId,
    amount: amount ?? this.amount,
  );
  Posting copyWithCompanion(PostingsCompanion data) {
    return Posting(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      fundId: data.fundId.present ? data.fundId.value : this.fundId,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Posting(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('accountId: $accountId, ')
          ..write('fundId: $fundId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, accountId, fundId, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Posting &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.accountId == this.accountId &&
          other.fundId == this.fundId &&
          other.amount == this.amount);
}

class PostingsCompanion extends UpdateCompanion<Posting> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<int> accountId;
  final Value<int> fundId;
  final Value<int> amount;
  const PostingsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.fundId = const Value.absent(),
    this.amount = const Value.absent(),
  });
  PostingsCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required int accountId,
    required int fundId,
    required int amount,
  }) : entryId = Value(entryId),
       accountId = Value(accountId),
       fundId = Value(fundId),
       amount = Value(amount);
  static Insertable<Posting> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<int>? accountId,
    Expression<int>? fundId,
    Expression<int>? amount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (accountId != null) 'account_id': accountId,
      if (fundId != null) 'fund_id': fundId,
      if (amount != null) 'amount': amount,
    });
  }

  PostingsCompanion copyWith({
    Value<int>? id,
    Value<int>? entryId,
    Value<int>? accountId,
    Value<int>? fundId,
    Value<int>? amount,
  }) {
    return PostingsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      accountId: accountId ?? this.accountId,
      fundId: fundId ?? this.fundId,
      amount: amount ?? this.amount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (fundId.present) {
      map['fund_id'] = Variable<int>(fundId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostingsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('accountId: $accountId, ')
          ..write('fundId: $fundId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, year, month, categoryId, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<Budget> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('year')) {
      context.handle(_yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(_monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {year, month, categoryId},
  ];
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      year: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      month: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}month'])!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final int id;
  final int year;
  final int month;
  final int categoryId;
  final int amount;
  const Budget({
    required this.id,
    required this.year,
    required this.month,
    required this.categoryId,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['category_id'] = Variable<int>(categoryId);
    map['amount'] = Variable<int>(amount);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      year: Value(year),
      month: Value(month),
      categoryId: Value(categoryId),
      amount: Value(amount),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<int>(json['id']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      amount: serializer.fromJson<int>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'categoryId': serializer.toJson<int>(categoryId),
      'amount': serializer.toJson<int>(amount),
    };
  }

  Budget copyWith({int? id, int? year, int? month, int? categoryId, int? amount}) => Budget(
    id: id ?? this.id,
    year: year ?? this.year,
    month: month ?? this.month,
    categoryId: categoryId ?? this.categoryId,
    amount: amount ?? this.amount,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, year, month, categoryId, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.year == this.year &&
          other.month == this.month &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<int> id;
  final Value<int> year;
  final Value<int> month;
  final Value<int> categoryId;
  final Value<int> amount;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.id = const Value.absent(),
    required int year,
    required int month,
    required int categoryId,
    required int amount,
  }) : year = Value(year),
       month = Value(month),
       categoryId = Value(categoryId),
       amount = Value(amount);
  static Insertable<Budget> custom({
    Expression<int>? id,
    Expression<int>? year,
    Expression<int>? month,
    Expression<int>? categoryId,
    Expression<int>? amount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
    });
  }

  BudgetsCompanion copyWith({
    Value<int>? id,
    Value<int>? year,
    Value<int>? month,
    Value<int>? categoryId,
    Value<int>? amount,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }
}

class $MonthClosesTable extends MonthCloses with TableInfo<$MonthClosesTable, MonthClose> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthClosesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedBankMeta = const VerificationMeta('confirmedBank');
  @override
  late final GeneratedColumn<int> confirmedBank = GeneratedColumn<int>(
    'confirmed_bank',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [year, month, closedAt, confirmedBank];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'month_closes';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthClose> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('year')) {
      context.handle(_yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(_monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_closedAtMeta);
    }
    if (data.containsKey('confirmed_bank')) {
      context.handle(
        _confirmedBankMeta,
        confirmedBank.isAcceptableOrUnknown(data['confirmed_bank']!, _confirmedBankMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {year, month};
  @override
  MonthClose map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthClose(
      year: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      month: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}month'])!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      )!,
      confirmedBank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confirmed_bank'],
      ),
    );
  }

  @override
  $MonthClosesTable createAlias(String alias) {
    return $MonthClosesTable(attachedDatabase, alias);
  }
}

class MonthClose extends DataClass implements Insertable<MonthClose> {
  final int year;
  final int month;
  final DateTime closedAt;
  final int? confirmedBank;
  const MonthClose({
    required this.year,
    required this.month,
    required this.closedAt,
    this.confirmedBank,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['closed_at'] = Variable<DateTime>(closedAt);
    if (!nullToAbsent || confirmedBank != null) {
      map['confirmed_bank'] = Variable<int>(confirmedBank);
    }
    return map;
  }

  MonthClosesCompanion toCompanion(bool nullToAbsent) {
    return MonthClosesCompanion(
      year: Value(year),
      month: Value(month),
      closedAt: Value(closedAt),
      confirmedBank: confirmedBank == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedBank),
    );
  }

  factory MonthClose.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthClose(
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      closedAt: serializer.fromJson<DateTime>(json['closedAt']),
      confirmedBank: serializer.fromJson<int?>(json['confirmedBank']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'closedAt': serializer.toJson<DateTime>(closedAt),
      'confirmedBank': serializer.toJson<int?>(confirmedBank),
    };
  }

  MonthClose copyWith({
    int? year,
    int? month,
    DateTime? closedAt,
    Value<int?> confirmedBank = const Value.absent(),
  }) => MonthClose(
    year: year ?? this.year,
    month: month ?? this.month,
    closedAt: closedAt ?? this.closedAt,
    confirmedBank: confirmedBank.present ? confirmedBank.value : this.confirmedBank,
  );
  MonthClose copyWithCompanion(MonthClosesCompanion data) {
    return MonthClose(
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      confirmedBank: data.confirmedBank.present ? data.confirmedBank.value : this.confirmedBank,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthClose(')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('closedAt: $closedAt, ')
          ..write('confirmedBank: $confirmedBank')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(year, month, closedAt, confirmedBank);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthClose &&
          other.year == this.year &&
          other.month == this.month &&
          other.closedAt == this.closedAt &&
          other.confirmedBank == this.confirmedBank);
}

class MonthClosesCompanion extends UpdateCompanion<MonthClose> {
  final Value<int> year;
  final Value<int> month;
  final Value<DateTime> closedAt;
  final Value<int?> confirmedBank;
  final Value<int> rowid;
  const MonthClosesCompanion({
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.confirmedBank = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthClosesCompanion.insert({
    required int year,
    required int month,
    required DateTime closedAt,
    this.confirmedBank = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : year = Value(year),
       month = Value(month),
       closedAt = Value(closedAt);
  static Insertable<MonthClose> custom({
    Expression<int>? year,
    Expression<int>? month,
    Expression<DateTime>? closedAt,
    Expression<int>? confirmedBank,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (closedAt != null) 'closed_at': closedAt,
      if (confirmedBank != null) 'confirmed_bank': confirmedBank,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthClosesCompanion copyWith({
    Value<int>? year,
    Value<int>? month,
    Value<DateTime>? closedAt,
    Value<int?>? confirmedBank,
    Value<int>? rowid,
  }) {
    return MonthClosesCompanion(
      year: year ?? this.year,
      month: month ?? this.month,
      closedAt: closedAt ?? this.closedAt,
      confirmedBank: confirmedBank ?? this.confirmedBank,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (confirmedBank.present) {
      map['confirmed_bank'] = Variable<int>(confirmedBank.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthClosesCompanion(')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('closedAt: $closedAt, ')
          ..write('confirmedBank: $confirmedBank, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvestmentDetailsTable extends InvestmentDetails
    with TableInfo<$InvestmentDetailsTable, InvestmentDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestmentDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<InvestmentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<InvestmentKind>($InvestmentDetailsTable.$converterkind);
  static const VerificationMeta _startDateMeta = const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maturityDateMeta = const VerificationMeta('maturityDate');
  @override
  late final GeneratedColumn<DateTime> maturityDate = GeneratedColumn<DateTime>(
    'maturity_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rateBpMeta = const VerificationMeta('rateBp');
  @override
  late final GeneratedColumn<int> rateBp = GeneratedColumn<int>(
    'rate_bp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instalmentMeta = const VerificationMeta('instalment');
  @override
  late final GeneratedColumn<int> instalment = GeneratedColumn<int>(
    'instalment',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalInstalmentsMeta = const VerificationMeta('totalInstalments');
  @override
  late final GeneratedColumn<int> totalInstalments = GeneratedColumn<int>(
    'total_instalments',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openingInstalmentsMeta = const VerificationMeta(
    'openingInstalments',
  );
  @override
  late final GeneratedColumn<int> openingInstalments = GeneratedColumn<int>(
    'opening_instalments',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    kind,
    startDate,
    maturityDate,
    rateBp,
    instalment,
    totalInstalments,
    openingInstalments,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investment_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvestmentDetail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('maturity_date')) {
      context.handle(
        _maturityDateMeta,
        maturityDate.isAcceptableOrUnknown(data['maturity_date']!, _maturityDateMeta),
      );
    }
    if (data.containsKey('rate_bp')) {
      context.handle(_rateBpMeta, rateBp.isAcceptableOrUnknown(data['rate_bp']!, _rateBpMeta));
    }
    if (data.containsKey('instalment')) {
      context.handle(
        _instalmentMeta,
        instalment.isAcceptableOrUnknown(data['instalment']!, _instalmentMeta),
      );
    }
    if (data.containsKey('total_instalments')) {
      context.handle(
        _totalInstalmentsMeta,
        totalInstalments.isAcceptableOrUnknown(data['total_instalments']!, _totalInstalmentsMeta),
      );
    }
    if (data.containsKey('opening_instalments')) {
      context.handle(
        _openingInstalmentsMeta,
        openingInstalments.isAcceptableOrUnknown(
          data['opening_instalments']!,
          _openingInstalmentsMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  InvestmentDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvestmentDetail(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      kind: $InvestmentDetailsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      maturityDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}maturity_date'],
      ),
      rateBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_bp'],
      ),
      instalment: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instalment'],
      ),
      totalInstalments: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_instalments'],
      ),
      openingInstalments: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_instalments'],
      )!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $InvestmentDetailsTable createAlias(String alias) {
    return $InvestmentDetailsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<InvestmentKind, String, String> $converterkind =
      const EnumNameConverter<InvestmentKind>(InvestmentKind.values);
}

class InvestmentDetail extends DataClass implements Insertable<InvestmentDetail> {
  final int accountId;
  final InvestmentKind kind;
  final DateTime? startDate;
  final DateTime? maturityDate;

  /// Yearly rate in basis points: 1150 = 11.5%.
  final int? rateBp;

  /// Monthly instalment for a DPS.
  final int? instalment;
  final int? totalInstalments;

  /// Instalments paid before the account was entered in the app.
  final int openingInstalments;
  final String note;
  const InvestmentDetail({
    required this.accountId,
    required this.kind,
    this.startDate,
    this.maturityDate,
    this.rateBp,
    this.instalment,
    this.totalInstalments,
    required this.openingInstalments,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<int>(accountId);
    {
      map['kind'] = Variable<String>($InvestmentDetailsTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || maturityDate != null) {
      map['maturity_date'] = Variable<DateTime>(maturityDate);
    }
    if (!nullToAbsent || rateBp != null) {
      map['rate_bp'] = Variable<int>(rateBp);
    }
    if (!nullToAbsent || instalment != null) {
      map['instalment'] = Variable<int>(instalment);
    }
    if (!nullToAbsent || totalInstalments != null) {
      map['total_instalments'] = Variable<int>(totalInstalments);
    }
    map['opening_instalments'] = Variable<int>(openingInstalments);
    map['note'] = Variable<String>(note);
    return map;
  }

  InvestmentDetailsCompanion toCompanion(bool nullToAbsent) {
    return InvestmentDetailsCompanion(
      accountId: Value(accountId),
      kind: Value(kind),
      startDate: startDate == null && nullToAbsent ? const Value.absent() : Value(startDate),
      maturityDate: maturityDate == null && nullToAbsent
          ? const Value.absent()
          : Value(maturityDate),
      rateBp: rateBp == null && nullToAbsent ? const Value.absent() : Value(rateBp),
      instalment: instalment == null && nullToAbsent ? const Value.absent() : Value(instalment),
      totalInstalments: totalInstalments == null && nullToAbsent
          ? const Value.absent()
          : Value(totalInstalments),
      openingInstalments: Value(openingInstalments),
      note: Value(note),
    );
  }

  factory InvestmentDetail.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvestmentDetail(
      accountId: serializer.fromJson<int>(json['accountId']),
      kind: $InvestmentDetailsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      maturityDate: serializer.fromJson<DateTime?>(json['maturityDate']),
      rateBp: serializer.fromJson<int?>(json['rateBp']),
      instalment: serializer.fromJson<int?>(json['instalment']),
      totalInstalments: serializer.fromJson<int?>(json['totalInstalments']),
      openingInstalments: serializer.fromJson<int>(json['openingInstalments']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<int>(accountId),
      'kind': serializer.toJson<String>($InvestmentDetailsTable.$converterkind.toJson(kind)),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'maturityDate': serializer.toJson<DateTime?>(maturityDate),
      'rateBp': serializer.toJson<int?>(rateBp),
      'instalment': serializer.toJson<int?>(instalment),
      'totalInstalments': serializer.toJson<int?>(totalInstalments),
      'openingInstalments': serializer.toJson<int>(openingInstalments),
      'note': serializer.toJson<String>(note),
    };
  }

  InvestmentDetail copyWith({
    int? accountId,
    InvestmentKind? kind,
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> maturityDate = const Value.absent(),
    Value<int?> rateBp = const Value.absent(),
    Value<int?> instalment = const Value.absent(),
    Value<int?> totalInstalments = const Value.absent(),
    int? openingInstalments,
    String? note,
  }) => InvestmentDetail(
    accountId: accountId ?? this.accountId,
    kind: kind ?? this.kind,
    startDate: startDate.present ? startDate.value : this.startDate,
    maturityDate: maturityDate.present ? maturityDate.value : this.maturityDate,
    rateBp: rateBp.present ? rateBp.value : this.rateBp,
    instalment: instalment.present ? instalment.value : this.instalment,
    totalInstalments: totalInstalments.present ? totalInstalments.value : this.totalInstalments,
    openingInstalments: openingInstalments ?? this.openingInstalments,
    note: note ?? this.note,
  );
  InvestmentDetail copyWithCompanion(InvestmentDetailsCompanion data) {
    return InvestmentDetail(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      kind: data.kind.present ? data.kind.value : this.kind,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      maturityDate: data.maturityDate.present ? data.maturityDate.value : this.maturityDate,
      rateBp: data.rateBp.present ? data.rateBp.value : this.rateBp,
      instalment: data.instalment.present ? data.instalment.value : this.instalment,
      totalInstalments: data.totalInstalments.present
          ? data.totalInstalments.value
          : this.totalInstalments,
      openingInstalments: data.openingInstalments.present
          ? data.openingInstalments.value
          : this.openingInstalments,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentDetail(')
          ..write('accountId: $accountId, ')
          ..write('kind: $kind, ')
          ..write('startDate: $startDate, ')
          ..write('maturityDate: $maturityDate, ')
          ..write('rateBp: $rateBp, ')
          ..write('instalment: $instalment, ')
          ..write('totalInstalments: $totalInstalments, ')
          ..write('openingInstalments: $openingInstalments, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    kind,
    startDate,
    maturityDate,
    rateBp,
    instalment,
    totalInstalments,
    openingInstalments,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvestmentDetail &&
          other.accountId == this.accountId &&
          other.kind == this.kind &&
          other.startDate == this.startDate &&
          other.maturityDate == this.maturityDate &&
          other.rateBp == this.rateBp &&
          other.instalment == this.instalment &&
          other.totalInstalments == this.totalInstalments &&
          other.openingInstalments == this.openingInstalments &&
          other.note == this.note);
}

class InvestmentDetailsCompanion extends UpdateCompanion<InvestmentDetail> {
  final Value<int> accountId;
  final Value<InvestmentKind> kind;
  final Value<DateTime?> startDate;
  final Value<DateTime?> maturityDate;
  final Value<int?> rateBp;
  final Value<int?> instalment;
  final Value<int?> totalInstalments;
  final Value<int> openingInstalments;
  final Value<String> note;
  const InvestmentDetailsCompanion({
    this.accountId = const Value.absent(),
    this.kind = const Value.absent(),
    this.startDate = const Value.absent(),
    this.maturityDate = const Value.absent(),
    this.rateBp = const Value.absent(),
    this.instalment = const Value.absent(),
    this.totalInstalments = const Value.absent(),
    this.openingInstalments = const Value.absent(),
    this.note = const Value.absent(),
  });
  InvestmentDetailsCompanion.insert({
    this.accountId = const Value.absent(),
    required InvestmentKind kind,
    this.startDate = const Value.absent(),
    this.maturityDate = const Value.absent(),
    this.rateBp = const Value.absent(),
    this.instalment = const Value.absent(),
    this.totalInstalments = const Value.absent(),
    this.openingInstalments = const Value.absent(),
    this.note = const Value.absent(),
  }) : kind = Value(kind);
  static Insertable<InvestmentDetail> custom({
    Expression<int>? accountId,
    Expression<String>? kind,
    Expression<DateTime>? startDate,
    Expression<DateTime>? maturityDate,
    Expression<int>? rateBp,
    Expression<int>? instalment,
    Expression<int>? totalInstalments,
    Expression<int>? openingInstalments,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (kind != null) 'kind': kind,
      if (startDate != null) 'start_date': startDate,
      if (maturityDate != null) 'maturity_date': maturityDate,
      if (rateBp != null) 'rate_bp': rateBp,
      if (instalment != null) 'instalment': instalment,
      if (totalInstalments != null) 'total_instalments': totalInstalments,
      if (openingInstalments != null) 'opening_instalments': openingInstalments,
      if (note != null) 'note': note,
    });
  }

  InvestmentDetailsCompanion copyWith({
    Value<int>? accountId,
    Value<InvestmentKind>? kind,
    Value<DateTime?>? startDate,
    Value<DateTime?>? maturityDate,
    Value<int?>? rateBp,
    Value<int?>? instalment,
    Value<int?>? totalInstalments,
    Value<int>? openingInstalments,
    Value<String>? note,
  }) {
    return InvestmentDetailsCompanion(
      accountId: accountId ?? this.accountId,
      kind: kind ?? this.kind,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      rateBp: rateBp ?? this.rateBp,
      instalment: instalment ?? this.instalment,
      totalInstalments: totalInstalments ?? this.totalInstalments,
      openingInstalments: openingInstalments ?? this.openingInstalments,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>($InvestmentDetailsTable.$converterkind.toSql(kind.value));
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (maturityDate.present) {
      map['maturity_date'] = Variable<DateTime>(maturityDate.value);
    }
    if (rateBp.present) {
      map['rate_bp'] = Variable<int>(rateBp.value);
    }
    if (instalment.present) {
      map['instalment'] = Variable<int>(instalment.value);
    }
    if (totalInstalments.present) {
      map['total_instalments'] = Variable<int>(totalInstalments.value);
    }
    if (openingInstalments.present) {
      map['opening_instalments'] = Variable<int>(openingInstalments.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentDetailsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('kind: $kind, ')
          ..write('startDate: $startDate, ')
          ..write('maturityDate: $maturityDate, ')
          ..write('rateBp: $rateBp, ')
          ..write('instalment: $instalment, ')
          ..write('totalInstalments: $totalInstalments, ')
          ..write('openingInstalments: $openingInstalments, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $PurchasesTable extends Purchases with TableInfo<$PurchasesTable, Purchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _itemMeta = const VerificationMeta('item');
  @override
  late final GeneratedColumn<String> item = GeneratedColumn<String>(
    'item',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopMeta = const VerificationMeta('shop');
  @override
  late final GeneratedColumn<String> shop = GeneratedColumn<String>(
    'shop',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _warrantyUntilMeta = const VerificationMeta('warrantyUntil');
  @override
  late final GeneratedColumn<DateTime> warrantyUntil = GeneratedColumn<DateTime>(
    'warranty_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    item,
    date,
    amount,
    shop,
    warrantyUntil,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchases';
  @override
  VerificationContext validateIntegrity(Insertable<Purchase> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta, entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    }
    if (data.containsKey('item')) {
      context.handle(_itemMeta, item.isAcceptableOrUnknown(data['item']!, _itemMeta));
    } else if (isInserting) {
      context.missing(_itemMeta);
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('shop')) {
      context.handle(_shopMeta, shop.isAcceptableOrUnknown(data['shop']!, _shopMeta));
    }
    if (data.containsKey('warranty_until')) {
      context.handle(
        _warrantyUntilMeta,
        warrantyUntil.isAcceptableOrUnknown(data['warranty_until']!, _warrantyUntilMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Purchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Purchase(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      ),
      item: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}item'])!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      shop: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}shop'])!,
      warrantyUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}warranty_until'],
      ),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $PurchasesTable createAlias(String alias) {
    return $PurchasesTable(attachedDatabase, alias);
  }
}

class Purchase extends DataClass implements Insertable<Purchase> {
  final int id;

  /// The expense that paid for it. Deleting the expense deletes the record.
  final int? entryId;
  final String item;
  final DateTime date;
  final int amount;
  final String shop;
  final DateTime? warrantyUntil;
  final String note;
  const Purchase({
    required this.id,
    this.entryId,
    required this.item,
    required this.date,
    required this.amount,
    required this.shop,
    this.warrantyUntil,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || entryId != null) {
      map['entry_id'] = Variable<int>(entryId);
    }
    map['item'] = Variable<String>(item);
    map['date'] = Variable<DateTime>(date);
    map['amount'] = Variable<int>(amount);
    map['shop'] = Variable<String>(shop);
    if (!nullToAbsent || warrantyUntil != null) {
      map['warranty_until'] = Variable<DateTime>(warrantyUntil);
    }
    map['note'] = Variable<String>(note);
    return map;
  }

  PurchasesCompanion toCompanion(bool nullToAbsent) {
    return PurchasesCompanion(
      id: Value(id),
      entryId: entryId == null && nullToAbsent ? const Value.absent() : Value(entryId),
      item: Value(item),
      date: Value(date),
      amount: Value(amount),
      shop: Value(shop),
      warrantyUntil: warrantyUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyUntil),
      note: Value(note),
    );
  }

  factory Purchase.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Purchase(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<int?>(json['entryId']),
      item: serializer.fromJson<String>(json['item']),
      date: serializer.fromJson<DateTime>(json['date']),
      amount: serializer.fromJson<int>(json['amount']),
      shop: serializer.fromJson<String>(json['shop']),
      warrantyUntil: serializer.fromJson<DateTime?>(json['warrantyUntil']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<int?>(entryId),
      'item': serializer.toJson<String>(item),
      'date': serializer.toJson<DateTime>(date),
      'amount': serializer.toJson<int>(amount),
      'shop': serializer.toJson<String>(shop),
      'warrantyUntil': serializer.toJson<DateTime?>(warrantyUntil),
      'note': serializer.toJson<String>(note),
    };
  }

  Purchase copyWith({
    int? id,
    Value<int?> entryId = const Value.absent(),
    String? item,
    DateTime? date,
    int? amount,
    String? shop,
    Value<DateTime?> warrantyUntil = const Value.absent(),
    String? note,
  }) => Purchase(
    id: id ?? this.id,
    entryId: entryId.present ? entryId.value : this.entryId,
    item: item ?? this.item,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    shop: shop ?? this.shop,
    warrantyUntil: warrantyUntil.present ? warrantyUntil.value : this.warrantyUntil,
    note: note ?? this.note,
  );
  Purchase copyWithCompanion(PurchasesCompanion data) {
    return Purchase(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      item: data.item.present ? data.item.value : this.item,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      shop: data.shop.present ? data.shop.value : this.shop,
      warrantyUntil: data.warrantyUntil.present ? data.warrantyUntil.value : this.warrantyUntil,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Purchase(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('item: $item, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('shop: $shop, ')
          ..write('warrantyUntil: $warrantyUntil, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, item, date, amount, shop, warrantyUntil, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Purchase &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.item == this.item &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.shop == this.shop &&
          other.warrantyUntil == this.warrantyUntil &&
          other.note == this.note);
}

class PurchasesCompanion extends UpdateCompanion<Purchase> {
  final Value<int> id;
  final Value<int?> entryId;
  final Value<String> item;
  final Value<DateTime> date;
  final Value<int> amount;
  final Value<String> shop;
  final Value<DateTime?> warrantyUntil;
  final Value<String> note;
  const PurchasesCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.item = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.shop = const Value.absent(),
    this.warrantyUntil = const Value.absent(),
    this.note = const Value.absent(),
  });
  PurchasesCompanion.insert({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    required String item,
    required DateTime date,
    required int amount,
    this.shop = const Value.absent(),
    this.warrantyUntil = const Value.absent(),
    this.note = const Value.absent(),
  }) : item = Value(item),
       date = Value(date),
       amount = Value(amount);
  static Insertable<Purchase> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<String>? item,
    Expression<DateTime>? date,
    Expression<int>? amount,
    Expression<String>? shop,
    Expression<DateTime>? warrantyUntil,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (item != null) 'item': item,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (shop != null) 'shop': shop,
      if (warrantyUntil != null) 'warranty_until': warrantyUntil,
      if (note != null) 'note': note,
    });
  }

  PurchasesCompanion copyWith({
    Value<int>? id,
    Value<int?>? entryId,
    Value<String>? item,
    Value<DateTime>? date,
    Value<int>? amount,
    Value<String>? shop,
    Value<DateTime?>? warrantyUntil,
    Value<String>? note,
  }) {
    return PurchasesCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      item: item ?? this.item,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      shop: shop ?? this.shop,
      warrantyUntil: warrantyUntil ?? this.warrantyUntil,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (item.present) {
      map['item'] = Variable<String>(item.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (shop.present) {
      map['shop'] = Variable<String>(shop.value);
    }
    if (warrantyUntil.present) {
      map['warranty_until'] = Variable<DateTime>(warrantyUntil.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchasesCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('item: $item, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('shop: $shop, ')
          ..write('warrantyUntil: $warrantyUntil, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $TrackersTable extends Trackers with TableInfo<$TrackersTable, Tracker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TrackerKind, String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<TrackerKind>($TrackersTable.$converterkind);
  static const VerificationMeta _budgetMeta = const VerificationMeta('budget');
  @override
  late final GeneratedColumn<int> budget = GeneratedColumn<int>(
    'budget',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openingSpentMeta = const VerificationMeta('openingSpent');
  @override
  late final GeneratedColumn<int> openingSpent = GeneratedColumn<int>(
    'opening_spent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    budget,
    openingSpent,
    startDate,
    endDate,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trackers';
  @override
  VerificationContext validateIntegrity(Insertable<Tracker> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('budget')) {
      context.handle(_budgetMeta, budget.isAcceptableOrUnknown(data['budget']!, _budgetMeta));
    }
    if (data.containsKey('opening_spent')) {
      context.handle(
        _openingSpentMeta,
        openingSpent.isAcceptableOrUnknown(data['opening_spent']!, _openingSpentMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta, endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tracker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tracker(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: $TrackersTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      ),
      budget: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}budget']),
      openingSpent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_spent'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $TrackersTable createAlias(String alias) {
    return $TrackersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TrackerKind, String, String> $converterkind =
      const EnumNameConverter<TrackerKind>(TrackerKind.values);
}

class Tracker extends DataClass implements Insertable<Tracker> {
  final int id;
  final String name;
  final TrackerKind kind;
  final int? budget;

  /// Spent before the tracker was entered in the app.
  final int openingSpent;
  final DateTime startDate;
  final DateTime? endDate;
  final bool archived;
  const Tracker({
    required this.id,
    required this.name,
    required this.kind,
    this.budget,
    required this.openingSpent,
    required this.startDate,
    this.endDate,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>($TrackersTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || budget != null) {
      map['budget'] = Variable<int>(budget);
    }
    map['opening_spent'] = Variable<int>(openingSpent);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  TrackersCompanion toCompanion(bool nullToAbsent) {
    return TrackersCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      budget: budget == null && nullToAbsent ? const Value.absent() : Value(budget),
      openingSpent: Value(openingSpent),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent ? const Value.absent() : Value(endDate),
      archived: Value(archived),
    );
  }

  factory Tracker.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tracker(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $TrackersTable.$converterkind.fromJson(serializer.fromJson<String>(json['kind'])),
      budget: serializer.fromJson<int?>(json['budget']),
      openingSpent: serializer.fromJson<int>(json['openingSpent']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>($TrackersTable.$converterkind.toJson(kind)),
      'budget': serializer.toJson<int?>(budget),
      'openingSpent': serializer.toJson<int>(openingSpent),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Tracker copyWith({
    int? id,
    String? name,
    TrackerKind? kind,
    Value<int?> budget = const Value.absent(),
    int? openingSpent,
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    bool? archived,
  }) => Tracker(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    budget: budget.present ? budget.value : this.budget,
    openingSpent: openingSpent ?? this.openingSpent,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    archived: archived ?? this.archived,
  );
  Tracker copyWithCompanion(TrackersCompanion data) {
    return Tracker(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      budget: data.budget.present ? data.budget.value : this.budget,
      openingSpent: data.openingSpent.present ? data.openingSpent.value : this.openingSpent,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tracker(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('budget: $budget, ')
          ..write('openingSpent: $openingSpent, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, kind, budget, openingSpent, startDate, endDate, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tracker &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.budget == this.budget &&
          other.openingSpent == this.openingSpent &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.archived == this.archived);
}

class TrackersCompanion extends UpdateCompanion<Tracker> {
  final Value<int> id;
  final Value<String> name;
  final Value<TrackerKind> kind;
  final Value<int?> budget;
  final Value<int> openingSpent;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<bool> archived;
  const TrackersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.budget = const Value.absent(),
    this.openingSpent = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.archived = const Value.absent(),
  });
  TrackersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required TrackerKind kind,
    this.budget = const Value.absent(),
    this.openingSpent = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.archived = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind),
       startDate = Value(startDate);
  static Insertable<Tracker> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? budget,
    Expression<int>? openingSpent,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<bool>? archived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (budget != null) 'budget': budget,
      if (openingSpent != null) 'opening_spent': openingSpent,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (archived != null) 'archived': archived,
    });
  }

  TrackersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<TrackerKind>? kind,
    Value<int?>? budget,
    Value<int>? openingSpent,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<bool>? archived,
  }) {
    return TrackersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      budget: budget ?? this.budget,
      openingSpent: openingSpent ?? this.openingSpent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      archived: archived ?? this.archived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>($TrackersTable.$converterkind.toSql(kind.value));
    }
    if (budget.present) {
      map['budget'] = Variable<int>(budget.value);
    }
    if (openingSpent.present) {
      map['opening_spent'] = Variable<int>(openingSpent.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('budget: $budget, ')
          ..write('openingSpent: $openingSpent, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $FundsTable funds = $FundsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $LoansTable loans = $LoansTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $PostingsTable postings = $PostingsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $MonthClosesTable monthCloses = $MonthClosesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $InvestmentDetailsTable investmentDetails = $InvestmentDetailsTable(this);
  late final $PurchasesTable purchases = $PurchasesTable(this);
  late final $TrackersTable trackers = $TrackersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    funds,
    categories,
    loans,
    entries,
    postings,
    budgets,
    monthCloses,
    settings,
    investmentDetails,
    purchases,
    trackers,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('entries', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('postings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('accounts', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('investment_details', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('entries', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('purchases', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required String name,
  required AccountType type,
  Value<int> sortOrder,
  Value<bool> archived,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<AccountType> type,
  Value<int> sortOrder,
  Value<bool> archived,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LoansTable, List<Loan>> _loansRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.loans, aliasName: 'accounts__id__loans__person_account_id');

  $$LoansTableProcessedTableManager get loansRefs {
    final manager = $$LoansTableTableManager(
      $_db,
      $_db.loans,
    ).filter((f) => f.personAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_loansRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PostingsTable, List<Posting>> _postingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.postings, aliasName: 'accounts__id__postings__account_id');

  $$PostingsTableProcessedTableManager get postingsRefs {
    final manager = $$PostingsTableTableManager(
      $_db,
      $_db.postings,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_postingsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InvestmentDetailsTable, List<InvestmentDetail>>
  _investmentDetailsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.investmentDetails,
    aliasName: 'accounts__id__investment_details__account_id',
  );

  $$InvestmentDetailsTableProcessedTableManager get investmentDetailsRefs {
    final manager = $$InvestmentDetailsTableTableManager(
      $_db,
      $_db.investmentDetails,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_investmentDetailsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AccountType, AccountType, String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  Expression<bool> loansRefs(Expression<bool> Function($$LoansTableFilterComposer f) f) {
    final $$LoansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.personAccountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LoansTableFilterComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> postingsRefs(Expression<bool> Function($$PostingsTableFilterComposer f) f) {
    final $$PostingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.postings,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PostingsTableFilterComposer(
            $db: $db,
            $table: $db.postings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> investmentDetailsRefs(
    Expression<bool> Function($$InvestmentDetailsTableFilterComposer f) f,
  ) {
    final $$InvestmentDetailsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.investmentDetails,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$InvestmentDetailsTableFilterComposer(
            $db: $db,
            $table: $db.investmentDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  Expression<T> loansRefs<T extends Object>(
    Expression<T> Function($$LoansTableAnnotationComposer a) f,
  ) {
    final $$LoansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.personAccountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LoansTableAnnotationComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> postingsRefs<T extends Object>(
    Expression<T> Function($$PostingsTableAnnotationComposer a) f,
  ) {
    final $$PostingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.postings,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PostingsTableAnnotationComposer(
            $db: $db,
            $table: $db.postings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> investmentDetailsRefs<T extends Object>(
    Expression<T> Function($$InvestmentDetailsTableAnnotationComposer a) f,
  ) {
    final $$InvestmentDetailsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.investmentDetails,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$InvestmentDetailsTableAnnotationComposer(
            $db: $db,
            $table: $db.investmentDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool loansRefs, bool postingsRefs, bool investmentDetailsRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AccountType> type = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                type: type,
                sortOrder: sortOrder,
                archived: archived,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required AccountType type,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                type: type,
                sortOrder: sortOrder,
                archived: archived,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, Account>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({loansRefs = false, postingsRefs = false, investmentDetailsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (loansRefs) db.loans,
                    if (postingsRefs) db.postings,
                    if (investmentDetailsRefs) db.investmentDetails,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (loansRefs)
                        await $_getPrefetchedData<Account, $AccountsTable, Loan>(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences._loansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(db, table, p0).loansRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.personAccountId == item.id),
                          typedResults: items,
                        ),
                      if (postingsRefs)
                        await $_getPrefetchedData<Account, $AccountsTable, Posting>(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences._postingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(db, table, p0).postingsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.accountId == item.id),
                          typedResults: items,
                        ),
                      if (investmentDetailsRefs)
                        await $_getPrefetchedData<Account, $AccountsTable, InvestmentDetail>(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences._investmentDetailsRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(db, table, p0).investmentDetailsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.accountId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool loansRefs, bool postingsRefs, bool investmentDetailsRefs})
    >;
typedef $$FundsTableCreateCompanionBuilder = FundsCompanion Function({
  Value<int> id,
  required String name,
  required FundKind kind,
  Value<int?> targetAmount,
  Value<DateTime?> targetDate,
  Value<DateTime?> achievedAt,
  Value<int> sortOrder,
  Value<bool> archived,
});
typedef $$FundsTableUpdateCompanionBuilder = FundsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<FundKind> kind,
  Value<int?> targetAmount,
  Value<DateTime?> targetDate,
  Value<DateTime?> achievedAt,
  Value<int> sortOrder,
  Value<bool> archived,
});

final class $$FundsTableReferences extends BaseReferences<_$AppDatabase, $FundsTable, Fund> {
  $$FundsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CategoriesTable, List<CategoryRow>> _categoriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: 'funds__id__categories__savings_fund_id',
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.savingsFundId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LoansTable, List<Loan>> _loansRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.loans, aliasName: 'funds__id__loans__fund_id');

  $$LoansTableProcessedTableManager get loansRefs {
    final manager = $$LoansTableTableManager(
      $_db,
      $_db.loans,
    ).filter((f) => f.fundId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_loansRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PostingsTable, List<Posting>> _postingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.postings, aliasName: 'funds__id__postings__fund_id');

  $$PostingsTableProcessedTableManager get postingsRefs {
    final manager = $$PostingsTableTableManager(
      $_db,
      $_db.postings,
    ).filter((f) => f.fundId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_postingsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FundsTableFilterComposer extends Composer<_$AppDatabase, $FundsTable> {
  $$FundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<FundKind, FundKind, String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get targetAmount =>
      $composableBuilder(column: $table.targetAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get targetDate =>
      $composableBuilder(column: $table.targetDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get achievedAt =>
      $composableBuilder(column: $table.achievedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  Expression<bool> categoriesRefs(Expression<bool> Function($$CategoriesTableFilterComposer f) f) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.savingsFundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loansRefs(Expression<bool> Function($$LoansTableFilterComposer f) f) {
    final $$LoansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.fundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LoansTableFilterComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> postingsRefs(Expression<bool> Function($$PostingsTableFilterComposer f) f) {
    final $$PostingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.postings,
      getReferencedColumn: (t) => t.fundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PostingsTableFilterComposer(
            $db: $db,
            $table: $db.postings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FundsTableOrderingComposer extends Composer<_$AppDatabase, $FundsTable> {
  $$FundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetAmount =>
      $composableBuilder(column: $table.targetAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get targetDate =>
      $composableBuilder(column: $table.targetDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get achievedAt =>
      $composableBuilder(column: $table.achievedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));
}

class $$FundsTableAnnotationComposer extends Composer<_$AppDatabase, $FundsTable> {
  $$FundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FundKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get targetAmount =>
      $composableBuilder(column: $table.targetAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate =>
      $composableBuilder(column: $table.targetDate, builder: (column) => column);

  GeneratedColumn<DateTime> get achievedAt =>
      $composableBuilder(column: $table.achievedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.savingsFundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loansRefs<T extends Object>(
    Expression<T> Function($$LoansTableAnnotationComposer a) f,
  ) {
    final $$LoansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.fundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LoansTableAnnotationComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> postingsRefs<T extends Object>(
    Expression<T> Function($$PostingsTableAnnotationComposer a) f,
  ) {
    final $$PostingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.postings,
      getReferencedColumn: (t) => t.fundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PostingsTableAnnotationComposer(
            $db: $db,
            $table: $db.postings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FundsTable,
          Fund,
          $$FundsTableFilterComposer,
          $$FundsTableOrderingComposer,
          $$FundsTableAnnotationComposer,
          $$FundsTableCreateCompanionBuilder,
          $$FundsTableUpdateCompanionBuilder,
          (Fund, $$FundsTableReferences),
          Fund,
          PrefetchHooks Function({bool categoriesRefs, bool loansRefs, bool postingsRefs})
        > {
  $$FundsTableTableManager(_$AppDatabase db, $FundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$FundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$FundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$FundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<FundKind> kind = const Value.absent(),
                Value<int?> targetAmount = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<DateTime?> achievedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
              }) => FundsCompanion(
                id: id,
                name: name,
                kind: kind,
                targetAmount: targetAmount,
                targetDate: targetDate,
                achievedAt: achievedAt,
                sortOrder: sortOrder,
                archived: archived,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required FundKind kind,
                Value<int?> targetAmount = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<DateTime?> achievedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
              }) => FundsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                targetAmount: targetAmount,
                targetDate: targetDate,
                achievedAt: achievedAt,
                sortOrder: sortOrder,
                archived: archived,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$FundsTable, Fund>(table), $$FundsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoriesRefs = false, loansRefs = false, postingsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (categoriesRefs) db.categories,
                    if (loansRefs) db.loans,
                    if (postingsRefs) db.postings,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (categoriesRefs)
                        await $_getPrefetchedData<Fund, $FundsTable, CategoryRow>(
                          currentTable: table,
                          referencedTable: $$FundsTableReferences._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FundsTableReferences(db, table, p0).categoriesRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.savingsFundId == item.id),
                          typedResults: items,
                        ),
                      if (loansRefs)
                        await $_getPrefetchedData<Fund, $FundsTable, Loan>(
                          currentTable: table,
                          referencedTable: $$FundsTableReferences._loansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FundsTableReferences(db, table, p0).loansRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.fundId == item.id),
                          typedResults: items,
                        ),
                      if (postingsRefs)
                        await $_getPrefetchedData<Fund, $FundsTable, Posting>(
                          currentTable: table,
                          referencedTable: $$FundsTableReferences._postingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FundsTableReferences(db, table, p0).postingsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.fundId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FundsTable,
      Fund,
      $$FundsTableFilterComposer,
      $$FundsTableOrderingComposer,
      $$FundsTableAnnotationComposer,
      $$FundsTableCreateCompanionBuilder,
      $$FundsTableUpdateCompanionBuilder,
      (Fund, $$FundsTableReferences),
      Fund,
      PrefetchHooks Function({bool categoriesRefs, bool loansRefs, bool postingsRefs})
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<int?> parentId,
  required String name,
  required CategoryKind kind,
  Value<bool> isFixed,
  Value<int?> dueDay,
  Value<int?> savingsFundId,
  Value<int> sortOrder,
  Value<bool> archived,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<int?> parentId,
  Value<String> name,
  Value<CategoryKind> kind,
  Value<bool> isFixed,
  Value<int?> dueDay,
  Value<int?> savingsFundId,
  Value<int> sortOrder,
  Value<bool> archived,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _parentIdTable(_$AppDatabase db) =>
      db.categories.createAlias('categories__parent_id__categories__id');

  $$CategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FundsTable _savingsFundIdTable(_$AppDatabase db) =>
      db.funds.createAlias('categories__savings_fund_id__funds__id');

  $$FundsTableProcessedTableManager? get savingsFundId {
    final $_column = $_itemColumn<int>('savings_fund_id');
    if ($_column == null) return null;
    final manager = $$FundsTableTableManager(
      $_db,
      $_db.funds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_savingsFundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.entries, aliasName: 'categories__id__entries__category_id');

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.budgets, aliasName: 'categories__id__budgets__category_id');

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CategoryKind, CategoryKind, String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isFixed =>
      $composableBuilder(column: $table.isFixed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FundsTableFilterComposer get savingsFundId {
    final $$FundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savingsFundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$FundsTableFilterComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> entriesRefs(Expression<bool> Function($$EntriesTableFilterComposer f) f) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(Expression<bool> Function($$BudgetsTableFilterComposer f) f) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFixed =>
      $composableBuilder(column: $table.isFixed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FundsTableOrderingComposer get savingsFundId {
    final $$FundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savingsFundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$FundsTableOrderingComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get isFixed =>
      $composableBuilder(column: $table.isFixed, builder: (column) => column);

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FundsTableAnnotationComposer get savingsFundId {
    final $$FundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savingsFundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$FundsTableAnnotationComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({
            bool parentId,
            bool savingsFundId,
            bool entriesRefs,
            bool budgetsRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<CategoryKind> kind = const Value.absent(),
                Value<bool> isFixed = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<int?> savingsFundId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                parentId: parentId,
                name: name,
                kind: kind,
                isFixed: isFixed,
                dueDay: dueDay,
                savingsFundId: savingsFundId,
                sortOrder: sortOrder,
                archived: archived,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                required String name,
                required CategoryKind kind,
                Value<bool> isFixed = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<int?> savingsFundId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                parentId: parentId,
                name: name,
                kind: kind,
                isFixed: isFixed,
                dueDay: dueDay,
                savingsFundId: savingsFundId,
                sortOrder: sortOrder,
                archived: archived,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parentId = false,
                savingsFundId = false,
                entriesRefs = false,
                budgetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entriesRefs) db.entries,
                    if (budgetsRefs) db.budgets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentId,
                            referencedTable: $$CategoriesTableReferences._parentIdTable(db),
                            referencedColumn: $$CategoriesTableReferences._parentIdTable(db).id,
                          ) as T;
                        }
                        if (savingsFundId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.savingsFundId,
                            referencedTable: $$CategoriesTableReferences._savingsFundIdTable(db),
                            referencedColumn: $$CategoriesTableReferences
                                ._savingsFundIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entriesRefs)
                        await $_getPrefetchedData<CategoryRow, $CategoriesTable, Entry>(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences._entriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(db, table, p0).entriesRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.categoryId == item.id),
                          typedResults: items,
                        ),
                      if (budgetsRefs)
                        await $_getPrefetchedData<CategoryRow, $CategoriesTable, Budget>(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences._budgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(db, table, p0).budgetsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.categoryId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({
        bool parentId,
        bool savingsFundId,
        bool entriesRefs,
        bool budgetsRefs,
      })
    >;
typedef $$LoansTableCreateCompanionBuilder = LoansCompanion Function({
  Value<int> id,
  required LoanKind kind,
  Value<int?> personAccountId,
  required int fundId,
  required int principal,
  Value<int> chargeRateBp,
  Value<int> charge,
  Value<int> openingRepaid,
  required DateTime date,
  Value<DateTime?> dueDate,
  Value<String> note,
  Value<DateTime?> closedAt,
});
typedef $$LoansTableUpdateCompanionBuilder = LoansCompanion Function({
  Value<int> id,
  Value<LoanKind> kind,
  Value<int?> personAccountId,
  Value<int> fundId,
  Value<int> principal,
  Value<int> chargeRateBp,
  Value<int> charge,
  Value<int> openingRepaid,
  Value<DateTime> date,
  Value<DateTime?> dueDate,
  Value<String> note,
  Value<DateTime?> closedAt,
});

final class $$LoansTableReferences extends BaseReferences<_$AppDatabase, $LoansTable, Loan> {
  $$LoansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _personAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('loans__person_account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get personAccountId {
    final $_column = $_itemColumn<int>('person_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FundsTable _fundIdTable(_$AppDatabase db) =>
      db.funds.createAlias('loans__fund_id__funds__id');

  $$FundsTableProcessedTableManager get fundId {
    final $_column = $_itemColumn<int>('fund_id')!;

    final manager = $$FundsTableTableManager(
      $_db,
      $_db.funds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.entries, aliasName: 'loans__id__entries__loan_id');

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.loanId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LoansTableFilterComposer extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<LoanKind, LoanKind, String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get principal =>
      $composableBuilder(column: $table.principal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chargeRateBp =>
      $composableBuilder(column: $table.chargeRateBp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get charge =>
      $composableBuilder(column: $table.charge, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openingRepaid =>
      $composableBuilder(column: $table.openingRepaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get personAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FundsTableFilterComposer get fundId {
    final $$FundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$FundsTableFilterComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> entriesRefs(Expression<bool> Function($$EntriesTableFilterComposer f) f) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.loanId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LoansTableOrderingComposer extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get principal =>
      $composableBuilder(column: $table.principal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chargeRateBp =>
      $composableBuilder(column: $table.chargeRateBp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get charge =>
      $composableBuilder(column: $table.charge, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openingRepaid => $composableBuilder(
    column: $table.openingRepaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get personAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FundsTableOrderingComposer get fundId {
    final $$FundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$FundsTableOrderingComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoansTableAnnotationComposer extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LoanKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get principal =>
      $composableBuilder(column: $table.principal, builder: (column) => column);

  GeneratedColumn<int> get chargeRateBp =>
      $composableBuilder(column: $table.chargeRateBp, builder: (column) => column);

  GeneratedColumn<int> get charge =>
      $composableBuilder(column: $table.charge, builder: (column) => column);

  GeneratedColumn<int> get openingRepaid =>
      $composableBuilder(column: $table.openingRepaid, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get personAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FundsTableAnnotationComposer get fundId {
    final $$FundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$FundsTableAnnotationComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.loanId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LoansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoansTable,
          Loan,
          $$LoansTableFilterComposer,
          $$LoansTableOrderingComposer,
          $$LoansTableAnnotationComposer,
          $$LoansTableCreateCompanionBuilder,
          $$LoansTableUpdateCompanionBuilder,
          (Loan, $$LoansTableReferences),
          Loan,
          PrefetchHooks Function({bool personAccountId, bool fundId, bool entriesRefs})
        > {
  $$LoansTableTableManager(_$AppDatabase db, $LoansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LoansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LoansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LoansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<LoanKind> kind = const Value.absent(),
                Value<int?> personAccountId = const Value.absent(),
                Value<int> fundId = const Value.absent(),
                Value<int> principal = const Value.absent(),
                Value<int> chargeRateBp = const Value.absent(),
                Value<int> charge = const Value.absent(),
                Value<int> openingRepaid = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
              }) => LoansCompanion(
                id: id,
                kind: kind,
                personAccountId: personAccountId,
                fundId: fundId,
                principal: principal,
                chargeRateBp: chargeRateBp,
                charge: charge,
                openingRepaid: openingRepaid,
                date: date,
                dueDate: dueDate,
                note: note,
                closedAt: closedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required LoanKind kind,
                Value<int?> personAccountId = const Value.absent(),
                required int fundId,
                required int principal,
                Value<int> chargeRateBp = const Value.absent(),
                Value<int> charge = const Value.absent(),
                Value<int> openingRepaid = const Value.absent(),
                required DateTime date,
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
              }) => LoansCompanion.insert(
                id: id,
                kind: kind,
                personAccountId: personAccountId,
                fundId: fundId,
                principal: principal,
                chargeRateBp: chargeRateBp,
                charge: charge,
                openingRepaid: openingRepaid,
                date: date,
                dueDate: dueDate,
                note: note,
                closedAt: closedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$LoansTable, Loan>(table), $$LoansTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({personAccountId = false, fundId = false, entriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entriesRefs) db.entries],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personAccountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.personAccountId,
                        referencedTable: $$LoansTableReferences._personAccountIdTable(db),
                        referencedColumn: $$LoansTableReferences._personAccountIdTable(db).id,
                      ) as T;
                    }
                    if (fundId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.fundId,
                        referencedTable: $$LoansTableReferences._fundIdTable(db),
                        referencedColumn: $$LoansTableReferences._fundIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entriesRefs)
                    await $_getPrefetchedData<Loan, $LoansTable, Entry>(
                      currentTable: table,
                      referencedTable: $$LoansTableReferences._entriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LoansTableReferences(db, table, p0).entriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.loanId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LoansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoansTable,
      Loan,
      $$LoansTableFilterComposer,
      $$LoansTableOrderingComposer,
      $$LoansTableAnnotationComposer,
      $$LoansTableCreateCompanionBuilder,
      $$LoansTableUpdateCompanionBuilder,
      (Loan, $$LoansTableReferences),
      Loan,
      PrefetchHooks Function({bool personAccountId, bool fundId, bool entriesRefs})
    >;
typedef $$EntriesTableCreateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  required DateTime date,
  required EntryType type,
  required int amount,
  Value<int?> categoryId,
  Value<int?> loanId,
  Value<int?> trackerId,
  Value<String> note,
  Value<DateTime> createdAt,
});
typedef $$EntriesTableUpdateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<EntryType> type,
  Value<int> amount,
  Value<int?> categoryId,
  Value<int?> loanId,
  Value<int?> trackerId,
  Value<String> note,
  Value<DateTime> createdAt,
});

final class $$EntriesTableReferences extends BaseReferences<_$AppDatabase, $EntriesTable, Entry> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('entries__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $LoansTable _loanIdTable(_$AppDatabase db) =>
      db.loans.createAlias('entries__loan_id__loans__id');

  $$LoansTableProcessedTableManager? get loanId {
    final $_column = $_itemColumn<int>('loan_id');
    if ($_column == null) return null;
    final manager = $$LoansTableTableManager(
      $_db,
      $_db.loans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_loanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PostingsTable, List<Posting>> _postingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.postings, aliasName: 'entries__id__postings__entry_id');

  $$PostingsTableProcessedTableManager get postingsRefs {
    final manager = $$PostingsTableTableManager(
      $_db,
      $_db.postings,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_postingsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PurchasesTable, List<Purchase>> _purchasesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.purchases, aliasName: 'entries__id__purchases__entry_id');

  $$PurchasesTableProcessedTableManager get purchasesRefs {
    final manager = $$PurchasesTableTableManager(
      $_db,
      $_db.purchases,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchasesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EntriesTableFilterComposer extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<EntryType, EntryType, String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trackerId =>
      $composableBuilder(column: $table.trackerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoansTableFilterComposer get loanId {
    final $$LoansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loanId,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LoansTableFilterComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> postingsRefs(Expression<bool> Function($$PostingsTableFilterComposer f) f) {
    final $$PostingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.postings,
      getReferencedColumn: (t) => t.entryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PostingsTableFilterComposer(
            $db: $db,
            $table: $db.postings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> purchasesRefs(Expression<bool> Function($$PurchasesTableFilterComposer f) f) {
    final $$PurchasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.entryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PurchasesTableFilterComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableOrderingComposer extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trackerId =>
      $composableBuilder(column: $table.trackerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoansTableOrderingComposer get loanId {
    final $$LoansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loanId,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LoansTableOrderingComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableAnnotationComposer extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntryType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get trackerId =>
      $composableBuilder(column: $table.trackerId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoansTableAnnotationComposer get loanId {
    final $$LoansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loanId,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LoansTableAnnotationComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> postingsRefs<T extends Object>(
    Expression<T> Function($$PostingsTableAnnotationComposer a) f,
  ) {
    final $$PostingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.postings,
      getReferencedColumn: (t) => t.entryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PostingsTableAnnotationComposer(
            $db: $db,
            $table: $db.postings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> purchasesRefs<T extends Object>(
    Expression<T> Function($$PurchasesTableAnnotationComposer a) f,
  ) {
    final $$PurchasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.entryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PurchasesTableAnnotationComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, $$EntriesTableReferences),
          Entry,
          PrefetchHooks Function({
            bool categoryId,
            bool loanId,
            bool postingsRefs,
            bool purchasesRefs,
          })
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<EntryType> type = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> loanId = const Value.absent(),
                Value<int?> trackerId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                date: date,
                type: type,
                amount: amount,
                categoryId: categoryId,
                loanId: loanId,
                trackerId: trackerId,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required EntryType type,
                required int amount,
                Value<int?> categoryId = const Value.absent(),
                Value<int?> loanId = const Value.absent(),
                Value<int?> trackerId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                date: date,
                type: type,
                amount: amount,
                categoryId: categoryId,
                loanId: loanId,
                trackerId: trackerId,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntriesTable, Entry>(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoryId = false, loanId = false, postingsRefs = false, purchasesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (postingsRefs) db.postings,
                    if (purchasesRefs) db.purchases,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$EntriesTableReferences._categoryIdTable(db),
                            referencedColumn: $$EntriesTableReferences._categoryIdTable(db).id,
                          ) as T;
                        }
                        if (loanId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.loanId,
                            referencedTable: $$EntriesTableReferences._loanIdTable(db),
                            referencedColumn: $$EntriesTableReferences._loanIdTable(db).id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (postingsRefs)
                        await $_getPrefetchedData<Entry, $EntriesTable, Posting>(
                          currentTable: table,
                          referencedTable: $$EntriesTableReferences._postingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntriesTableReferences(db, table, p0).postingsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.entryId == item.id),
                          typedResults: items,
                        ),
                      if (purchasesRefs)
                        await $_getPrefetchedData<Entry, $EntriesTable, Purchase>(
                          currentTable: table,
                          referencedTable: $$EntriesTableReferences._purchasesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntriesTableReferences(db, table, p0).purchasesRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.entryId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, $$EntriesTableReferences),
      Entry,
      PrefetchHooks Function({bool categoryId, bool loanId, bool postingsRefs, bool purchasesRefs})
    >;
typedef $$PostingsTableCreateCompanionBuilder = PostingsCompanion Function({
  Value<int> id,
  required int entryId,
  required int accountId,
  required int fundId,
  required int amount,
});
typedef $$PostingsTableUpdateCompanionBuilder = PostingsCompanion Function({
  Value<int> id,
  Value<int> entryId,
  Value<int> accountId,
  Value<int> fundId,
  Value<int> amount,
});

final class $$PostingsTableReferences
    extends BaseReferences<_$AppDatabase, $PostingsTable, Posting> {
  $$PostingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntriesTable _entryIdTable(_$AppDatabase db) =>
      db.entries.createAlias('postings__entry_id__entries__id');

  $$EntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('postings__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FundsTable _fundIdTable(_$AppDatabase db) =>
      db.funds.createAlias('postings__fund_id__funds__id');

  $$FundsTableProcessedTableManager get fundId {
    final $_column = $_itemColumn<int>('fund_id')!;

    final manager = $$FundsTableTableManager(
      $_db,
      $_db.funds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PostingsTableFilterComposer extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  $$EntriesTableFilterComposer get entryId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FundsTableFilterComposer get fundId {
    final $$FundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$FundsTableFilterComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostingsTableOrderingComposer extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  $$EntriesTableOrderingComposer get entryId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FundsTableOrderingComposer get fundId {
    final $$FundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$FundsTableOrderingComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostingsTableAnnotationComposer extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  $$EntriesTableAnnotationComposer get entryId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FundsTableAnnotationComposer get fundId {
    final $$FundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$FundsTableAnnotationComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PostingsTable,
          Posting,
          $$PostingsTableFilterComposer,
          $$PostingsTableOrderingComposer,
          $$PostingsTableAnnotationComposer,
          $$PostingsTableCreateCompanionBuilder,
          $$PostingsTableUpdateCompanionBuilder,
          (Posting, $$PostingsTableReferences),
          Posting,
          PrefetchHooks Function({bool entryId, bool accountId, bool fundId})
        > {
  $$PostingsTableTableManager(_$AppDatabase db, $PostingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PostingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PostingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PostingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> entryId = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<int> fundId = const Value.absent(),
                Value<int> amount = const Value.absent(),
              }) => PostingsCompanion(
                id: id,
                entryId: entryId,
                accountId: accountId,
                fundId: fundId,
                amount: amount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int entryId,
                required int accountId,
                required int fundId,
                required int amount,
              }) => PostingsCompanion.insert(
                id: id,
                entryId: entryId,
                accountId: accountId,
                fundId: fundId,
                amount: amount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PostingsTable, Posting>(table),
                  $$PostingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false, accountId = false, fundId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$PostingsTableReferences._entryIdTable(db),
                        referencedColumn: $$PostingsTableReferences._entryIdTable(db).id,
                      ) as T;
                    }
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$PostingsTableReferences._accountIdTable(db),
                        referencedColumn: $$PostingsTableReferences._accountIdTable(db).id,
                      ) as T;
                    }
                    if (fundId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.fundId,
                        referencedTable: $$PostingsTableReferences._fundIdTable(db),
                        referencedColumn: $$PostingsTableReferences._fundIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PostingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PostingsTable,
      Posting,
      $$PostingsTableFilterComposer,
      $$PostingsTableOrderingComposer,
      $$PostingsTableAnnotationComposer,
      $$PostingsTableCreateCompanionBuilder,
      $$PostingsTableUpdateCompanionBuilder,
      (Posting, $$PostingsTableReferences),
      Posting,
      PrefetchHooks Function({bool entryId, bool accountId, bool fundId})
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  required int year,
  required int month,
  required int categoryId,
  required int amount,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<int> year,
  Value<int> month,
  Value<int> categoryId,
  Value<int> amount,
});

final class $$BudgetsTableReferences extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('budgets__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BudgetsTableFilterComposer extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableOrderingComposer extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, $$BudgetsTableReferences),
          Budget,
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> amount = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                year: year,
                month: month,
                categoryId: categoryId,
                amount: amount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int year,
                required int month,
                required int categoryId,
                required int amount,
              }) => BudgetsCompanion.insert(
                id: id,
                year: year,
                month: month,
                categoryId: categoryId,
                amount: amount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, Budget>(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$BudgetsTableReferences._categoryIdTable(db),
                        referencedColumn: $$BudgetsTableReferences._categoryIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, $$BudgetsTableReferences),
      Budget,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$MonthClosesTableCreateCompanionBuilder = MonthClosesCompanion Function({
  required int year,
  required int month,
  required DateTime closedAt,
  Value<int?> confirmedBank,
  Value<int> rowid,
});
typedef $$MonthClosesTableUpdateCompanionBuilder = MonthClosesCompanion Function({
  Value<int> year,
  Value<int> month,
  Value<DateTime> closedAt,
  Value<int?> confirmedBank,
  Value<int> rowid,
});

class $$MonthClosesTableFilterComposer extends Composer<_$AppDatabase, $MonthClosesTable> {
  $$MonthClosesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get confirmedBank =>
      $composableBuilder(column: $table.confirmedBank, builder: (column) => ColumnFilters(column));
}

class $$MonthClosesTableOrderingComposer extends Composer<_$AppDatabase, $MonthClosesTable> {
  $$MonthClosesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get confirmedBank => $composableBuilder(
    column: $table.confirmedBank,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonthClosesTableAnnotationComposer extends Composer<_$AppDatabase, $MonthClosesTable> {
  $$MonthClosesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get confirmedBank =>
      $composableBuilder(column: $table.confirmedBank, builder: (column) => column);
}

class $$MonthClosesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthClosesTable,
          MonthClose,
          $$MonthClosesTableFilterComposer,
          $$MonthClosesTableOrderingComposer,
          $$MonthClosesTableAnnotationComposer,
          $$MonthClosesTableCreateCompanionBuilder,
          $$MonthClosesTableUpdateCompanionBuilder,
          (MonthClose, BaseReferences<_$AppDatabase, $MonthClosesTable, MonthClose>),
          MonthClose,
          PrefetchHooks Function()
        > {
  $$MonthClosesTableTableManager(_$AppDatabase db, $MonthClosesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$MonthClosesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$MonthClosesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthClosesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<DateTime> closedAt = const Value.absent(),
                Value<int?> confirmedBank = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthClosesCompanion(
                year: year,
                month: month,
                closedAt: closedAt,
                confirmedBank: confirmedBank,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int year,
                required int month,
                required DateTime closedAt,
                Value<int?> confirmedBank = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthClosesCompanion.insert(
                year: year,
                month: month,
                closedAt: closedAt,
                confirmedBank: confirmedBank,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MonthClosesTable, MonthClose>(table),
                  BaseReferences<_$AppDatabase, $MonthClosesTable, MonthClose>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MonthClosesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthClosesTable,
      MonthClose,
      $$MonthClosesTableFilterComposer,
      $$MonthClosesTableOrderingComposer,
      $$MonthClosesTableAnnotationComposer,
      $$MonthClosesTableCreateCompanionBuilder,
      $$MonthClosesTableUpdateCompanionBuilder,
      (MonthClose, BaseReferences<_$AppDatabase, $MonthClosesTable, MonthClose>),
      MonthClose,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$InvestmentDetailsTableCreateCompanionBuilder = InvestmentDetailsCompanion Function({
  Value<int> accountId,
  required InvestmentKind kind,
  Value<DateTime?> startDate,
  Value<DateTime?> maturityDate,
  Value<int?> rateBp,
  Value<int?> instalment,
  Value<int?> totalInstalments,
  Value<int> openingInstalments,
  Value<String> note,
});
typedef $$InvestmentDetailsTableUpdateCompanionBuilder = InvestmentDetailsCompanion Function({
  Value<int> accountId,
  Value<InvestmentKind> kind,
  Value<DateTime?> startDate,
  Value<DateTime?> maturityDate,
  Value<int?> rateBp,
  Value<int?> instalment,
  Value<int?> totalInstalments,
  Value<int> openingInstalments,
  Value<String> note,
});

final class $$InvestmentDetailsTableReferences
    extends BaseReferences<_$AppDatabase, $InvestmentDetailsTable, InvestmentDetail> {
  $$InvestmentDetailsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('investment_details__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$InvestmentDetailsTableFilterComposer
    extends Composer<_$AppDatabase, $InvestmentDetailsTable> {
  $$InvestmentDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<InvestmentKind, InvestmentKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get maturityDate =>
      $composableBuilder(column: $table.maturityDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rateBp =>
      $composableBuilder(column: $table.rateBp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get instalment =>
      $composableBuilder(column: $table.instalment, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalInstalments => $composableBuilder(
    column: $table.totalInstalments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingInstalments => $composableBuilder(
    column: $table.openingInstalments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvestmentDetailsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvestmentDetailsTable> {
  $$InvestmentDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get maturityDate =>
      $composableBuilder(column: $table.maturityDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rateBp =>
      $composableBuilder(column: $table.rateBp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get instalment =>
      $composableBuilder(column: $table.instalment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalInstalments => $composableBuilder(
    column: $table.totalInstalments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingInstalments => $composableBuilder(
    column: $table.openingInstalments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvestmentDetailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvestmentDetailsTable> {
  $$InvestmentDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<InvestmentKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get maturityDate =>
      $composableBuilder(column: $table.maturityDate, builder: (column) => column);

  GeneratedColumn<int> get rateBp =>
      $composableBuilder(column: $table.rateBp, builder: (column) => column);

  GeneratedColumn<int> get instalment =>
      $composableBuilder(column: $table.instalment, builder: (column) => column);

  GeneratedColumn<int> get totalInstalments =>
      $composableBuilder(column: $table.totalInstalments, builder: (column) => column);

  GeneratedColumn<int> get openingInstalments =>
      $composableBuilder(column: $table.openingInstalments, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvestmentDetailsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvestmentDetailsTable,
          InvestmentDetail,
          $$InvestmentDetailsTableFilterComposer,
          $$InvestmentDetailsTableOrderingComposer,
          $$InvestmentDetailsTableAnnotationComposer,
          $$InvestmentDetailsTableCreateCompanionBuilder,
          $$InvestmentDetailsTableUpdateCompanionBuilder,
          (InvestmentDetail, $$InvestmentDetailsTableReferences),
          InvestmentDetail,
          PrefetchHooks Function({bool accountId})
        > {
  $$InvestmentDetailsTableTableManager(_$AppDatabase db, $InvestmentDetailsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvestmentDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvestmentDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvestmentDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> accountId = const Value.absent(),
                Value<InvestmentKind> kind = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> maturityDate = const Value.absent(),
                Value<int?> rateBp = const Value.absent(),
                Value<int?> instalment = const Value.absent(),
                Value<int?> totalInstalments = const Value.absent(),
                Value<int> openingInstalments = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => InvestmentDetailsCompanion(
                accountId: accountId,
                kind: kind,
                startDate: startDate,
                maturityDate: maturityDate,
                rateBp: rateBp,
                instalment: instalment,
                totalInstalments: totalInstalments,
                openingInstalments: openingInstalments,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> accountId = const Value.absent(),
                required InvestmentKind kind,
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> maturityDate = const Value.absent(),
                Value<int?> rateBp = const Value.absent(),
                Value<int?> instalment = const Value.absent(),
                Value<int?> totalInstalments = const Value.absent(),
                Value<int> openingInstalments = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => InvestmentDetailsCompanion.insert(
                accountId: accountId,
                kind: kind,
                startDate: startDate,
                maturityDate: maturityDate,
                rateBp: rateBp,
                instalment: instalment,
                totalInstalments: totalInstalments,
                openingInstalments: openingInstalments,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InvestmentDetailsTable, InvestmentDetail>(table),
                  $$InvestmentDetailsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$InvestmentDetailsTableReferences._accountIdTable(db),
                        referencedColumn: $$InvestmentDetailsTableReferences._accountIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InvestmentDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvestmentDetailsTable,
      InvestmentDetail,
      $$InvestmentDetailsTableFilterComposer,
      $$InvestmentDetailsTableOrderingComposer,
      $$InvestmentDetailsTableAnnotationComposer,
      $$InvestmentDetailsTableCreateCompanionBuilder,
      $$InvestmentDetailsTableUpdateCompanionBuilder,
      (InvestmentDetail, $$InvestmentDetailsTableReferences),
      InvestmentDetail,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$PurchasesTableCreateCompanionBuilder = PurchasesCompanion Function({
  Value<int> id,
  Value<int?> entryId,
  required String item,
  required DateTime date,
  required int amount,
  Value<String> shop,
  Value<DateTime?> warrantyUntil,
  Value<String> note,
});
typedef $$PurchasesTableUpdateCompanionBuilder = PurchasesCompanion Function({
  Value<int> id,
  Value<int?> entryId,
  Value<String> item,
  Value<DateTime> date,
  Value<int> amount,
  Value<String> shop,
  Value<DateTime?> warrantyUntil,
  Value<String> note,
});

final class $$PurchasesTableReferences
    extends BaseReferences<_$AppDatabase, $PurchasesTable, Purchase> {
  $$PurchasesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntriesTable _entryIdTable(_$AppDatabase db) =>
      db.entries.createAlias('purchases__entry_id__entries__id');

  $$EntriesTableProcessedTableManager? get entryId {
    final $_column = $_itemColumn<int>('entry_id');
    if ($_column == null) return null;
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PurchasesTableFilterComposer extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shop =>
      $composableBuilder(column: $table.shop, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get warrantyUntil =>
      $composableBuilder(column: $table.warrantyUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  $$EntriesTableFilterComposer get entryId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchasesTableOrderingComposer extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shop =>
      $composableBuilder(column: $table.shop, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get warrantyUntil => $composableBuilder(
    column: $table.warrantyUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  $$EntriesTableOrderingComposer get entryId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchasesTableAnnotationComposer extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get shop =>
      $composableBuilder(column: $table.shop, builder: (column) => column);

  GeneratedColumn<DateTime> get warrantyUntil =>
      $composableBuilder(column: $table.warrantyUntil, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$EntriesTableAnnotationComposer get entryId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchasesTable,
          Purchase,
          $$PurchasesTableFilterComposer,
          $$PurchasesTableOrderingComposer,
          $$PurchasesTableAnnotationComposer,
          $$PurchasesTableCreateCompanionBuilder,
          $$PurchasesTableUpdateCompanionBuilder,
          (Purchase, $$PurchasesTableReferences),
          Purchase,
          PrefetchHooks Function({bool entryId})
        > {
  $$PurchasesTableTableManager(_$AppDatabase db, $PurchasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> entryId = const Value.absent(),
                Value<String> item = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> shop = const Value.absent(),
                Value<DateTime?> warrantyUntil = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => PurchasesCompanion(
                id: id,
                entryId: entryId,
                item: item,
                date: date,
                amount: amount,
                shop: shop,
                warrantyUntil: warrantyUntil,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> entryId = const Value.absent(),
                required String item,
                required DateTime date,
                required int amount,
                Value<String> shop = const Value.absent(),
                Value<DateTime?> warrantyUntil = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => PurchasesCompanion.insert(
                id: id,
                entryId: entryId,
                item: item,
                date: date,
                amount: amount,
                shop: shop,
                warrantyUntil: warrantyUntil,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PurchasesTable, Purchase>(table),
                  $$PurchasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$PurchasesTableReferences._entryIdTable(db),
                        referencedColumn: $$PurchasesTableReferences._entryIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PurchasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchasesTable,
      Purchase,
      $$PurchasesTableFilterComposer,
      $$PurchasesTableOrderingComposer,
      $$PurchasesTableAnnotationComposer,
      $$PurchasesTableCreateCompanionBuilder,
      $$PurchasesTableUpdateCompanionBuilder,
      (Purchase, $$PurchasesTableReferences),
      Purchase,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$TrackersTableCreateCompanionBuilder = TrackersCompanion Function({
  Value<int> id,
  required String name,
  required TrackerKind kind,
  Value<int?> budget,
  Value<int> openingSpent,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<bool> archived,
});
typedef $$TrackersTableUpdateCompanionBuilder = TrackersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<TrackerKind> kind,
  Value<int?> budget,
  Value<int> openingSpent,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<bool> archived,
});

class $$TrackersTableFilterComposer extends Composer<_$AppDatabase, $TrackersTable> {
  $$TrackersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TrackerKind, TrackerKind, String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get budget =>
      $composableBuilder(column: $table.budget, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openingSpent =>
      $composableBuilder(column: $table.openingSpent, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));
}

class $$TrackersTableOrderingComposer extends Composer<_$AppDatabase, $TrackersTable> {
  $$TrackersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get budget =>
      $composableBuilder(column: $table.budget, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openingSpent =>
      $composableBuilder(column: $table.openingSpent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));
}

class $$TrackersTableAnnotationComposer extends Composer<_$AppDatabase, $TrackersTable> {
  $$TrackersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrackerKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get budget =>
      $composableBuilder(column: $table.budget, builder: (column) => column);

  GeneratedColumn<int> get openingSpent =>
      $composableBuilder(column: $table.openingSpent, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);
}

class $$TrackersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackersTable,
          Tracker,
          $$TrackersTableFilterComposer,
          $$TrackersTableOrderingComposer,
          $$TrackersTableAnnotationComposer,
          $$TrackersTableCreateCompanionBuilder,
          $$TrackersTableUpdateCompanionBuilder,
          (Tracker, BaseReferences<_$AppDatabase, $TrackersTable, Tracker>),
          Tracker,
          PrefetchHooks Function()
        > {
  $$TrackersTableTableManager(_$AppDatabase db, $TrackersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TrackersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TrackersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<TrackerKind> kind = const Value.absent(),
                Value<int?> budget = const Value.absent(),
                Value<int> openingSpent = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<bool> archived = const Value.absent(),
              }) => TrackersCompanion(
                id: id,
                name: name,
                kind: kind,
                budget: budget,
                openingSpent: openingSpent,
                startDate: startDate,
                endDate: endDate,
                archived: archived,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required TrackerKind kind,
                Value<int?> budget = const Value.absent(),
                Value<int> openingSpent = const Value.absent(),
                required DateTime startDate,
                Value<DateTime?> endDate = const Value.absent(),
                Value<bool> archived = const Value.absent(),
              }) => TrackersCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                budget: budget,
                openingSpent: openingSpent,
                startDate: startDate,
                endDate: endDate,
                archived: archived,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackersTable, Tracker>(table),
                  BaseReferences<_$AppDatabase, $TrackersTable, Tracker>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrackersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackersTable,
      Tracker,
      $$TrackersTableFilterComposer,
      $$TrackersTableOrderingComposer,
      $$TrackersTableAnnotationComposer,
      $$TrackersTableCreateCompanionBuilder,
      $$TrackersTableUpdateCompanionBuilder,
      (Tracker, BaseReferences<_$AppDatabase, $TrackersTable, Tracker>),
      Tracker,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts => $$AccountsTableTableManager(_db, _db.accounts);
  $$FundsTableTableManager get funds => $$FundsTableTableManager(_db, _db.funds);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$LoansTableTableManager get loans => $$LoansTableTableManager(_db, _db.loans);
  $$EntriesTableTableManager get entries => $$EntriesTableTableManager(_db, _db.entries);
  $$PostingsTableTableManager get postings => $$PostingsTableTableManager(_db, _db.postings);
  $$BudgetsTableTableManager get budgets => $$BudgetsTableTableManager(_db, _db.budgets);
  $$MonthClosesTableTableManager get monthCloses =>
      $$MonthClosesTableTableManager(_db, _db.monthCloses);
  $$SettingsTableTableManager get settings => $$SettingsTableTableManager(_db, _db.settings);
  $$InvestmentDetailsTableTableManager get investmentDetails =>
      $$InvestmentDetailsTableTableManager(_db, _db.investmentDetails);
  $$PurchasesTableTableManager get purchases => $$PurchasesTableTableManager(_db, _db.purchases);
  $$TrackersTableTableManager get trackers => $$TrackersTableTableManager(_db, _db.trackers);
}
