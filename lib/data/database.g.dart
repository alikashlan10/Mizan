// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NutrientsTable extends Nutrients
    with TableInfo<$NutrientsTable, Nutrient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutrientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fdcIdMeta = const VerificationMeta('fdcId');
  @override
  late final GeneratedColumn<int> fdcId = GeneratedColumn<int>(
    'fdc_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    unit,
    fdcId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Nutrient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('fdc_id')) {
      context.handle(
        _fdcIdMeta,
        fdcId.isAcceptableOrUnknown(data['fdc_id']!, _fdcIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Nutrient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Nutrient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      fdcId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fdc_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $NutrientsTable createAlias(String alias) {
    return $NutrientsTable(attachedDatabase, alias);
  }
}

class Nutrient extends DataClass implements Insertable<Nutrient> {
  final int id;
  final String code;
  final String name;
  final String unit;

  /// USDA FoodData Central nutrient id, used to map imported datasets.
  final int? fdcId;
  final int sortOrder;
  const Nutrient({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    this.fdcId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || fdcId != null) {
      map['fdc_id'] = Variable<int>(fdcId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  NutrientsCompanion toCompanion(bool nullToAbsent) {
    return NutrientsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      unit: Value(unit),
      fdcId: fdcId == null && nullToAbsent
          ? const Value.absent()
          : Value(fdcId),
      sortOrder: Value(sortOrder),
    );
  }

  factory Nutrient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Nutrient(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      fdcId: serializer.fromJson<int?>(json['fdcId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'fdcId': serializer.toJson<int?>(fdcId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Nutrient copyWith({
    int? id,
    String? code,
    String? name,
    String? unit,
    Value<int?> fdcId = const Value.absent(),
    int? sortOrder,
  }) => Nutrient(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    fdcId: fdcId.present ? fdcId.value : this.fdcId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Nutrient copyWithCompanion(NutrientsCompanion data) {
    return Nutrient(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      fdcId: data.fdcId.present ? data.fdcId.value : this.fdcId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Nutrient(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('fdcId: $fdcId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, unit, fdcId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Nutrient &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.fdcId == this.fdcId &&
          other.sortOrder == this.sortOrder);
}

class NutrientsCompanion extends UpdateCompanion<Nutrient> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> unit;
  final Value<int?> fdcId;
  final Value<int> sortOrder;
  const NutrientsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.fdcId = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  NutrientsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    required String unit,
    this.fdcId = const Value.absent(),
    required int sortOrder,
  }) : code = Value(code),
       name = Value(name),
       unit = Value(unit),
       sortOrder = Value(sortOrder);
  static Insertable<Nutrient> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<int>? fdcId,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (fdcId != null) 'fdc_id': fdcId,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  NutrientsCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? unit,
    Value<int?>? fdcId,
    Value<int>? sortOrder,
  }) {
    return NutrientsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      fdcId: fdcId ?? this.fdcId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (fdcId.present) {
      map['fdc_id'] = Variable<int>(fdcId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutrientsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('fdcId: $fdcId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $FoodsTable extends Foods with TableInfo<$FoodsTable, Food> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, source, sourceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<Food> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Food map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Food(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
    );
  }

  @override
  $FoodsTable createAlias(String alias) {
    return $FoodsTable(attachedDatabase, alias);
  }
}

class Food extends DataClass implements Insertable<Food> {
  final int id;
  final String name;

  /// Dataset the food came from, e.g. `usda_sr` or `custom`.
  final String source;
  final String? sourceId;
  const Food({
    required this.id,
    required this.name,
    required this.source,
    this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    return map;
  }

  FoodsCompanion toCompanion(bool nullToAbsent) {
    return FoodsCompanion(
      id: Value(id),
      name: Value(name),
      source: Value(source),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
    );
  }

  factory Food.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Food(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<String?>(sourceId),
    };
  }

  Food copyWith({
    int? id,
    String? name,
    String? source,
    Value<String?> sourceId = const Value.absent(),
  }) => Food(
    id: id ?? this.id,
    name: name ?? this.name,
    source: source ?? this.source,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
  );
  Food copyWithCompanion(FoodsCompanion data) {
    return Food(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Food(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, source, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Food &&
          other.id == this.id &&
          other.name == this.name &&
          other.source == this.source &&
          other.sourceId == this.sourceId);
}

class FoodsCompanion extends UpdateCompanion<Food> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> source;
  final Value<String?> sourceId;
  const FoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
  });
  FoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String source,
    this.sourceId = const Value.absent(),
  }) : name = Value(name),
       source = Value(source);
  static Insertable<Food> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? source,
    Expression<String>? sourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
    });
  }

  FoodsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? source,
    Value<String?>? sourceId,
  }) {
    return FoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
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
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }
}

class $FoodNutrientsTable extends FoodNutrients
    with TableInfo<$FoodNutrientsTable, FoodNutrient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodNutrientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES foods (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nutrientIdMeta = const VerificationMeta(
    'nutrientId',
  );
  @override
  late final GeneratedColumn<int> nutrientId = GeneratedColumn<int>(
    'nutrient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nutrients (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [foodId, nutrientId, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_nutrients';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodNutrient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('nutrient_id')) {
      context.handle(
        _nutrientIdMeta,
        nutrientId.isAcceptableOrUnknown(data['nutrient_id']!, _nutrientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nutrientIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {foodId, nutrientId};
  @override
  FoodNutrient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodNutrient(
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      )!,
      nutrientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nutrient_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $FoodNutrientsTable createAlias(String alias) {
    return $FoodNutrientsTable(attachedDatabase, alias);
  }
}

class FoodNutrient extends DataClass implements Insertable<FoodNutrient> {
  final int foodId;
  final int nutrientId;
  final double amount;
  const FoodNutrient({
    required this.foodId,
    required this.nutrientId,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['food_id'] = Variable<int>(foodId);
    map['nutrient_id'] = Variable<int>(nutrientId);
    map['amount'] = Variable<double>(amount);
    return map;
  }

  FoodNutrientsCompanion toCompanion(bool nullToAbsent) {
    return FoodNutrientsCompanion(
      foodId: Value(foodId),
      nutrientId: Value(nutrientId),
      amount: Value(amount),
    );
  }

  factory FoodNutrient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodNutrient(
      foodId: serializer.fromJson<int>(json['foodId']),
      nutrientId: serializer.fromJson<int>(json['nutrientId']),
      amount: serializer.fromJson<double>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'foodId': serializer.toJson<int>(foodId),
      'nutrientId': serializer.toJson<int>(nutrientId),
      'amount': serializer.toJson<double>(amount),
    };
  }

  FoodNutrient copyWith({int? foodId, int? nutrientId, double? amount}) =>
      FoodNutrient(
        foodId: foodId ?? this.foodId,
        nutrientId: nutrientId ?? this.nutrientId,
        amount: amount ?? this.amount,
      );
  FoodNutrient copyWithCompanion(FoodNutrientsCompanion data) {
    return FoodNutrient(
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      nutrientId: data.nutrientId.present
          ? data.nutrientId.value
          : this.nutrientId,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodNutrient(')
          ..write('foodId: $foodId, ')
          ..write('nutrientId: $nutrientId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(foodId, nutrientId, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodNutrient &&
          other.foodId == this.foodId &&
          other.nutrientId == this.nutrientId &&
          other.amount == this.amount);
}

class FoodNutrientsCompanion extends UpdateCompanion<FoodNutrient> {
  final Value<int> foodId;
  final Value<int> nutrientId;
  final Value<double> amount;
  final Value<int> rowid;
  const FoodNutrientsCompanion({
    this.foodId = const Value.absent(),
    this.nutrientId = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodNutrientsCompanion.insert({
    required int foodId,
    required int nutrientId,
    required double amount,
    this.rowid = const Value.absent(),
  }) : foodId = Value(foodId),
       nutrientId = Value(nutrientId),
       amount = Value(amount);
  static Insertable<FoodNutrient> custom({
    Expression<int>? foodId,
    Expression<int>? nutrientId,
    Expression<double>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (foodId != null) 'food_id': foodId,
      if (nutrientId != null) 'nutrient_id': nutrientId,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodNutrientsCompanion copyWith({
    Value<int>? foodId,
    Value<int>? nutrientId,
    Value<double>? amount,
    Value<int>? rowid,
  }) {
    return FoodNutrientsCompanion(
      foodId: foodId ?? this.foodId,
      nutrientId: nutrientId ?? this.nutrientId,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (nutrientId.present) {
      map['nutrient_id'] = Variable<int>(nutrientId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodNutrientsCompanion(')
          ..write('foodId: $foodId, ')
          ..write('nutrientId: $nutrientId, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiaryEntriesTable extends DiaryEntries
    with TableInfo<$DiaryEntriesTable, DiaryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Meal, int> meal =
      GeneratedColumn<int>(
        'meal',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Meal>($DiaryEntriesTable.$convertermeal);
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES foods (id)',
    ),
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
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
    day,
    meal,
    foodId,
    grams,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiaryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
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
  DiaryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      meal: $DiaryEntriesTable.$convertermeal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}meal'],
        )!,
      ),
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DiaryEntriesTable createAlias(String alias) {
    return $DiaryEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Meal, int, int> $convertermeal =
      const EnumIndexConverter<Meal>(Meal.values);
}

class DiaryEntry extends DataClass implements Insertable<DiaryEntry> {
  final int id;

  /// Local calendar day as `yyyy-MM-dd`.
  final String day;
  final Meal meal;
  final int foodId;
  final double grams;
  final DateTime createdAt;
  const DiaryEntry({
    required this.id,
    required this.day,
    required this.meal,
    required this.foodId,
    required this.grams,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<String>(day);
    {
      map['meal'] = Variable<int>(
        $DiaryEntriesTable.$convertermeal.toSql(meal),
      );
    }
    map['food_id'] = Variable<int>(foodId);
    map['grams'] = Variable<double>(grams);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DiaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DiaryEntriesCompanion(
      id: Value(id),
      day: Value(day),
      meal: Value(meal),
      foodId: Value(foodId),
      grams: Value(grams),
      createdAt: Value(createdAt),
    );
  }

  factory DiaryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiaryEntry(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      meal: $DiaryEntriesTable.$convertermeal.fromJson(
        serializer.fromJson<int>(json['meal']),
      ),
      foodId: serializer.fromJson<int>(json['foodId']),
      grams: serializer.fromJson<double>(json['grams']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<String>(day),
      'meal': serializer.toJson<int>(
        $DiaryEntriesTable.$convertermeal.toJson(meal),
      ),
      'foodId': serializer.toJson<int>(foodId),
      'grams': serializer.toJson<double>(grams),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DiaryEntry copyWith({
    int? id,
    String? day,
    Meal? meal,
    int? foodId,
    double? grams,
    DateTime? createdAt,
  }) => DiaryEntry(
    id: id ?? this.id,
    day: day ?? this.day,
    meal: meal ?? this.meal,
    foodId: foodId ?? this.foodId,
    grams: grams ?? this.grams,
    createdAt: createdAt ?? this.createdAt,
  );
  DiaryEntry copyWithCompanion(DiaryEntriesCompanion data) {
    return DiaryEntry(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      meal: data.meal.present ? data.meal.value : this.meal,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      grams: data.grams.present ? data.grams.value : this.grams,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntry(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('meal: $meal, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, meal, foodId, grams, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiaryEntry &&
          other.id == this.id &&
          other.day == this.day &&
          other.meal == this.meal &&
          other.foodId == this.foodId &&
          other.grams == this.grams &&
          other.createdAt == this.createdAt);
}

class DiaryEntriesCompanion extends UpdateCompanion<DiaryEntry> {
  final Value<int> id;
  final Value<String> day;
  final Value<Meal> meal;
  final Value<int> foodId;
  final Value<double> grams;
  final Value<DateTime> createdAt;
  const DiaryEntriesCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.meal = const Value.absent(),
    this.foodId = const Value.absent(),
    this.grams = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DiaryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String day,
    required Meal meal,
    required int foodId,
    required double grams,
    this.createdAt = const Value.absent(),
  }) : day = Value(day),
       meal = Value(meal),
       foodId = Value(foodId),
       grams = Value(grams);
  static Insertable<DiaryEntry> custom({
    Expression<int>? id,
    Expression<String>? day,
    Expression<int>? meal,
    Expression<int>? foodId,
    Expression<double>? grams,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (meal != null) 'meal': meal,
      if (foodId != null) 'food_id': foodId,
      if (grams != null) 'grams': grams,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DiaryEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? day,
    Value<Meal>? meal,
    Value<int>? foodId,
    Value<double>? grams,
    Value<DateTime>? createdAt,
  }) {
    return DiaryEntriesCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      meal: meal ?? this.meal,
      foodId: foodId ?? this.foodId,
      grams: grams ?? this.grams,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (meal.present) {
      map['meal'] = Variable<int>(
        $DiaryEntriesTable.$convertermeal.toSql(meal.value),
      );
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('meal: $meal, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NutrientsTable nutrients = $NutrientsTable(this);
  late final $FoodsTable foods = $FoodsTable(this);
  late final $FoodNutrientsTable foodNutrients = $FoodNutrientsTable(this);
  late final $DiaryEntriesTable diaryEntries = $DiaryEntriesTable(this);
  late final Index diaryEntriesDay = Index(
    'diary_entries_day',
    'CREATE INDEX diary_entries_day ON diary_entries (day)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    nutrients,
    foods,
    foodNutrients,
    diaryEntries,
    diaryEntriesDay,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'foods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('food_nutrients', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$NutrientsTableCreateCompanionBuilder = NutrientsCompanion Function({
  Value<int> id,
  required String code,
  required String name,
  required String unit,
  Value<int?> fdcId,
  required int sortOrder,
});
typedef $$NutrientsTableUpdateCompanionBuilder = NutrientsCompanion Function({
  Value<int> id,
  Value<String> code,
  Value<String> name,
  Value<String> unit,
  Value<int?> fdcId,
  Value<int> sortOrder,
});

final class $$NutrientsTableReferences
    extends BaseReferences<_$AppDatabase, $NutrientsTable, Nutrient> {
  $$NutrientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FoodNutrientsTable, List<FoodNutrient>>
  _foodNutrientsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.foodNutrients,
    aliasName: 'nutrients__id__food_nutrients__nutrient_id',
  );

  $$FoodNutrientsTableProcessedTableManager get foodNutrientsRefs {
    final manager = $$FoodNutrientsTableTableManager(
      $_db,
      $_db.foodNutrients,
    ).filter((f) => f.nutrientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_foodNutrientsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NutrientsTableFilterComposer
    extends Composer<_$AppDatabase, $NutrientsTable> {
  $$NutrientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fdcId => $composableBuilder(
    column: $table.fdcId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> foodNutrientsRefs(
    Expression<bool> Function($$FoodNutrientsTableFilterComposer f) f,
  ) {
    final $$FoodNutrientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.foodNutrients,
      getReferencedColumn: (t) => t.nutrientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodNutrientsTableFilterComposer(
            $db: $db,
            $table: $db.foodNutrients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NutrientsTableOrderingComposer
    extends Composer<_$AppDatabase, $NutrientsTable> {
  $$NutrientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fdcId => $composableBuilder(
    column: $table.fdcId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NutrientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NutrientsTable> {
  $$NutrientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get fdcId =>
      $composableBuilder(column: $table.fdcId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> foodNutrientsRefs<T extends Object>(
    Expression<T> Function($$FoodNutrientsTableAnnotationComposer a) f,
  ) {
    final $$FoodNutrientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.foodNutrients,
      getReferencedColumn: (t) => t.nutrientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodNutrientsTableAnnotationComposer(
            $db: $db,
            $table: $db.foodNutrients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NutrientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NutrientsTable,
          Nutrient,
          $$NutrientsTableFilterComposer,
          $$NutrientsTableOrderingComposer,
          $$NutrientsTableAnnotationComposer,
          $$NutrientsTableCreateCompanionBuilder,
          $$NutrientsTableUpdateCompanionBuilder,
          (Nutrient, $$NutrientsTableReferences),
          Nutrient,
          PrefetchHooks Function({bool foodNutrientsRefs})
        > {
  $$NutrientsTableTableManager(_$AppDatabase db, $NutrientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutrientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutrientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutrientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int?> fdcId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => NutrientsCompanion(
                id: id,
                code: code,
                name: name,
                unit: unit,
                fdcId: fdcId,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String name,
                required String unit,
                Value<int?> fdcId = const Value.absent(),
                required int sortOrder,
              }) => NutrientsCompanion.insert(
                id: id,
                code: code,
                name: name,
                unit: unit,
                fdcId: fdcId,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NutrientsTable, Nutrient>(table),
                  $$NutrientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({foodNutrientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (foodNutrientsRefs) db.foodNutrients,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (foodNutrientsRefs)
                    await $_getPrefetchedData<
                      Nutrient,
                      $NutrientsTable,
                      FoodNutrient
                    >(
                      currentTable: table,
                      referencedTable: $$NutrientsTableReferences
                          ._foodNutrientsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$NutrientsTableReferences(
                            db,
                            table,
                            p0,
                          ).foodNutrientsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.nutrientId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NutrientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NutrientsTable,
      Nutrient,
      $$NutrientsTableFilterComposer,
      $$NutrientsTableOrderingComposer,
      $$NutrientsTableAnnotationComposer,
      $$NutrientsTableCreateCompanionBuilder,
      $$NutrientsTableUpdateCompanionBuilder,
      (Nutrient, $$NutrientsTableReferences),
      Nutrient,
      PrefetchHooks Function({bool foodNutrientsRefs})
    >;
typedef $$FoodsTableCreateCompanionBuilder = FoodsCompanion Function({
  Value<int> id,
  required String name,
  required String source,
  Value<String?> sourceId,
});
typedef $$FoodsTableUpdateCompanionBuilder = FoodsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> source,
  Value<String?> sourceId,
});

final class $$FoodsTableReferences
    extends BaseReferences<_$AppDatabase, $FoodsTable, Food> {
  $$FoodsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FoodNutrientsTable, List<FoodNutrient>>
  _foodNutrientsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.foodNutrients,
    aliasName: 'foods__id__food_nutrients__food_id',
  );

  $$FoodNutrientsTableProcessedTableManager get foodNutrientsRefs {
    final manager = $$FoodNutrientsTableTableManager(
      $_db,
      $_db.foodNutrients,
    ).filter((f) => f.foodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_foodNutrientsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DiaryEntriesTable, List<DiaryEntry>>
  _diaryEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.diaryEntries,
    aliasName: 'foods__id__diary_entries__food_id',
  );

  $$DiaryEntriesTableProcessedTableManager get diaryEntriesRefs {
    final manager = $$DiaryEntriesTableTableManager(
      $_db,
      $_db.diaryEntries,
    ).filter((f) => f.foodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_diaryEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoodsTableFilterComposer extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> foodNutrientsRefs(
    Expression<bool> Function($$FoodNutrientsTableFilterComposer f) f,
  ) {
    final $$FoodNutrientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.foodNutrients,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodNutrientsTableFilterComposer(
            $db: $db,
            $table: $db.foodNutrients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> diaryEntriesRefs(
    Expression<bool> Function($$DiaryEntriesTableFilterComposer f) f,
  ) {
    final $$DiaryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diaryEntries,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiaryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.diaryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  Expression<T> foodNutrientsRefs<T extends Object>(
    Expression<T> Function($$FoodNutrientsTableAnnotationComposer a) f,
  ) {
    final $$FoodNutrientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.foodNutrients,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodNutrientsTableAnnotationComposer(
            $db: $db,
            $table: $db.foodNutrients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> diaryEntriesRefs<T extends Object>(
    Expression<T> Function($$DiaryEntriesTableAnnotationComposer a) f,
  ) {
    final $$DiaryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diaryEntries,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiaryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.diaryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodsTable,
          Food,
          $$FoodsTableFilterComposer,
          $$FoodsTableOrderingComposer,
          $$FoodsTableAnnotationComposer,
          $$FoodsTableCreateCompanionBuilder,
          $$FoodsTableUpdateCompanionBuilder,
          (Food, $$FoodsTableReferences),
          Food,
          PrefetchHooks Function({
            bool foodNutrientsRefs,
            bool diaryEntriesRefs,
          })
        > {
  $$FoodsTableTableManager(_$AppDatabase db, $FoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
              }) => FoodsCompanion(
                id: id,
                name: name,
                source: source,
                sourceId: sourceId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String source,
                Value<String?> sourceId = const Value.absent(),
              }) => FoodsCompanion.insert(
                id: id,
                name: name,
                source: source,
                sourceId: sourceId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodsTable, Food>(table),
                  $$FoodsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({foodNutrientsRefs = false, diaryEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (foodNutrientsRefs) db.foodNutrients,
                    if (diaryEntriesRefs) db.diaryEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (foodNutrientsRefs)
                        await $_getPrefetchedData<
                          Food,
                          $FoodsTable,
                          FoodNutrient
                        >(
                          currentTable: table,
                          referencedTable: $$FoodsTableReferences
                              ._foodNutrientsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FoodsTableReferences(
                                db,
                                table,
                                p0,
                              ).foodNutrientsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.foodId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (diaryEntriesRefs)
                        await $_getPrefetchedData<
                          Food,
                          $FoodsTable,
                          DiaryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$FoodsTableReferences
                              ._diaryEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FoodsTableReferences(
                                db,
                                table,
                                p0,
                              ).diaryEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.foodId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodsTable,
      Food,
      $$FoodsTableFilterComposer,
      $$FoodsTableOrderingComposer,
      $$FoodsTableAnnotationComposer,
      $$FoodsTableCreateCompanionBuilder,
      $$FoodsTableUpdateCompanionBuilder,
      (Food, $$FoodsTableReferences),
      Food,
      PrefetchHooks Function({bool foodNutrientsRefs, bool diaryEntriesRefs})
    >;
typedef $$FoodNutrientsTableCreateCompanionBuilder =
    FoodNutrientsCompanion Function({
      required int foodId,
      required int nutrientId,
      required double amount,
      Value<int> rowid,
    });
typedef $$FoodNutrientsTableUpdateCompanionBuilder =
    FoodNutrientsCompanion Function({
      Value<int> foodId,
      Value<int> nutrientId,
      Value<double> amount,
      Value<int> rowid,
    });

final class $$FoodNutrientsTableReferences
    extends BaseReferences<_$AppDatabase, $FoodNutrientsTable, FoodNutrient> {
  $$FoodNutrientsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FoodsTable _foodIdTable(_$AppDatabase db) =>
      db.foods.createAlias('food_nutrients__food_id__foods__id');

  $$FoodsTableProcessedTableManager get foodId {
    final $_column = $_itemColumn<int>('food_id')!;

    final manager = $$FoodsTableTableManager(
      $_db,
      $_db.foods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_foodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NutrientsTable _nutrientIdTable(_$AppDatabase db) =>
      db.nutrients.createAlias('food_nutrients__nutrient_id__nutrients__id');

  $$NutrientsTableProcessedTableManager get nutrientId {
    final $_column = $_itemColumn<int>('nutrient_id')!;

    final manager = $$NutrientsTableTableManager(
      $_db,
      $_db.nutrients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nutrientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FoodNutrientsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodNutrientsTable> {
  $$FoodNutrientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  $$FoodsTableFilterComposer get foodId {
    final $$FoodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableFilterComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NutrientsTableFilterComposer get nutrientId {
    final $$NutrientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nutrientId,
      referencedTable: $db.nutrients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NutrientsTableFilterComposer(
            $db: $db,
            $table: $db.nutrients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoodNutrientsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodNutrientsTable> {
  $$FoodNutrientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoodsTableOrderingComposer get foodId {
    final $$FoodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableOrderingComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NutrientsTableOrderingComposer get nutrientId {
    final $$NutrientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nutrientId,
      referencedTable: $db.nutrients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NutrientsTableOrderingComposer(
            $db: $db,
            $table: $db.nutrients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoodNutrientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodNutrientsTable> {
  $$FoodNutrientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  $$FoodsTableAnnotationComposer get foodId {
    final $$FoodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableAnnotationComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NutrientsTableAnnotationComposer get nutrientId {
    final $$NutrientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nutrientId,
      referencedTable: $db.nutrients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NutrientsTableAnnotationComposer(
            $db: $db,
            $table: $db.nutrients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoodNutrientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodNutrientsTable,
          FoodNutrient,
          $$FoodNutrientsTableFilterComposer,
          $$FoodNutrientsTableOrderingComposer,
          $$FoodNutrientsTableAnnotationComposer,
          $$FoodNutrientsTableCreateCompanionBuilder,
          $$FoodNutrientsTableUpdateCompanionBuilder,
          (FoodNutrient, $$FoodNutrientsTableReferences),
          FoodNutrient,
          PrefetchHooks Function({bool foodId, bool nutrientId})
        > {
  $$FoodNutrientsTableTableManager(_$AppDatabase db, $FoodNutrientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodNutrientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodNutrientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodNutrientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> foodId = const Value.absent(),
                Value<int> nutrientId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodNutrientsCompanion(
                foodId: foodId,
                nutrientId: nutrientId,
                amount: amount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int foodId,
                required int nutrientId,
                required double amount,
                Value<int> rowid = const Value.absent(),
              }) => FoodNutrientsCompanion.insert(
                foodId: foodId,
                nutrientId: nutrientId,
                amount: amount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodNutrientsTable, FoodNutrient>(table),
                  $$FoodNutrientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({foodId = false, nutrientId = false}) {
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
                    if (foodId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.foodId,
                        referencedTable: $$FoodNutrientsTableReferences
                            ._foodIdTable(db),
                        referencedColumn: $$FoodNutrientsTableReferences
                            ._foodIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (nutrientId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.nutrientId,
                        referencedTable: $$FoodNutrientsTableReferences
                            ._nutrientIdTable(db),
                        referencedColumn: $$FoodNutrientsTableReferences
                            ._nutrientIdTable(db)
                            .id,
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

typedef $$FoodNutrientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodNutrientsTable,
      FoodNutrient,
      $$FoodNutrientsTableFilterComposer,
      $$FoodNutrientsTableOrderingComposer,
      $$FoodNutrientsTableAnnotationComposer,
      $$FoodNutrientsTableCreateCompanionBuilder,
      $$FoodNutrientsTableUpdateCompanionBuilder,
      (FoodNutrient, $$FoodNutrientsTableReferences),
      FoodNutrient,
      PrefetchHooks Function({bool foodId, bool nutrientId})
    >;
typedef $$DiaryEntriesTableCreateCompanionBuilder =
    DiaryEntriesCompanion Function({
      Value<int> id,
      required String day,
      required Meal meal,
      required int foodId,
      required double grams,
      Value<DateTime> createdAt,
    });
typedef $$DiaryEntriesTableUpdateCompanionBuilder =
    DiaryEntriesCompanion Function({
      Value<int> id,
      Value<String> day,
      Value<Meal> meal,
      Value<int> foodId,
      Value<double> grams,
      Value<DateTime> createdAt,
    });

final class $$DiaryEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $DiaryEntriesTable, DiaryEntry> {
  $$DiaryEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoodsTable _foodIdTable(_$AppDatabase db) =>
      db.foods.createAlias('diary_entries__food_id__foods__id');

  $$FoodsTableProcessedTableManager get foodId {
    final $_column = $_itemColumn<int>('food_id')!;

    final manager = $$FoodsTableTableManager(
      $_db,
      $_db.foods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_foodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DiaryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Meal, Meal, int> get meal =>
      $composableBuilder(
        column: $table.meal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FoodsTableFilterComposer get foodId {
    final $$FoodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableFilterComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiaryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoodsTableOrderingComposer get foodId {
    final $$FoodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableOrderingComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiaryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Meal, int> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FoodsTableAnnotationComposer get foodId {
    final $$FoodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableAnnotationComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiaryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiaryEntriesTable,
          DiaryEntry,
          $$DiaryEntriesTableFilterComposer,
          $$DiaryEntriesTableOrderingComposer,
          $$DiaryEntriesTableAnnotationComposer,
          $$DiaryEntriesTableCreateCompanionBuilder,
          $$DiaryEntriesTableUpdateCompanionBuilder,
          (DiaryEntry, $$DiaryEntriesTableReferences),
          DiaryEntry,
          PrefetchHooks Function({bool foodId})
        > {
  $$DiaryEntriesTableTableManager(_$AppDatabase db, $DiaryEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiaryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiaryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiaryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<Meal> meal = const Value.absent(),
                Value<int> foodId = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DiaryEntriesCompanion(
                id: id,
                day: day,
                meal: meal,
                foodId: foodId,
                grams: grams,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String day,
                required Meal meal,
                required int foodId,
                required double grams,
                Value<DateTime> createdAt = const Value.absent(),
              }) => DiaryEntriesCompanion.insert(
                id: id,
                day: day,
                meal: meal,
                foodId: foodId,
                grams: grams,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiaryEntriesTable, DiaryEntry>(table),
                  $$DiaryEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({foodId = false}) {
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
                    if (foodId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.foodId,
                        referencedTable: $$DiaryEntriesTableReferences
                            ._foodIdTable(db),
                        referencedColumn: $$DiaryEntriesTableReferences
                            ._foodIdTable(db)
                            .id,
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

typedef $$DiaryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiaryEntriesTable,
      DiaryEntry,
      $$DiaryEntriesTableFilterComposer,
      $$DiaryEntriesTableOrderingComposer,
      $$DiaryEntriesTableAnnotationComposer,
      $$DiaryEntriesTableCreateCompanionBuilder,
      $$DiaryEntriesTableUpdateCompanionBuilder,
      (DiaryEntry, $$DiaryEntriesTableReferences),
      DiaryEntry,
      PrefetchHooks Function({bool foodId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NutrientsTableTableManager get nutrients =>
      $$NutrientsTableTableManager(_db, _db.nutrients);
  $$FoodsTableTableManager get foods =>
      $$FoodsTableTableManager(_db, _db.foods);
  $$FoodNutrientsTableTableManager get foodNutrients =>
      $$FoodNutrientsTableTableManager(_db, _db.foodNutrients);
  $$DiaryEntriesTableTableManager get diaryEntries =>
      $$DiaryEntriesTableTableManager(_db, _db.diaryEntries);
}
