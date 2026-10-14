// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MarketPricesTable extends MarketPrices
    with TableInfo<$MarketPricesTable, MarketPrice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MarketPricesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _commodityMeta = const VerificationMeta(
    'commodity',
  );
  @override
  late final GeneratedColumn<String> commodity = GeneratedColumn<String>(
    'commodity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mandiMeta = const VerificationMeta('mandi');
  @override
  late final GeneratedColumn<String> mandi = GeneratedColumn<String>(
    'mandi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricePerQuintalMeta = const VerificationMeta(
    'pricePerQuintal',
  );
  @override
  late final GeneratedColumn<double> pricePerQuintal = GeneratedColumn<double>(
    'price_per_quintal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceDateMeta = const VerificationMeta(
    'priceDate',
  );
  @override
  late final GeneratedColumn<DateTime> priceDate = GeneratedColumn<DateTime>(
    'price_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    commodity,
    mandi,
    pricePerQuintal,
    priceDate,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'market_prices';
  @override
  VerificationContext validateIntegrity(
    Insertable<MarketPrice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('commodity')) {
      context.handle(
        _commodityMeta,
        commodity.isAcceptableOrUnknown(data['commodity']!, _commodityMeta),
      );
    } else if (isInserting) {
      context.missing(_commodityMeta);
    }
    if (data.containsKey('mandi')) {
      context.handle(
        _mandiMeta,
        mandi.isAcceptableOrUnknown(data['mandi']!, _mandiMeta),
      );
    } else if (isInserting) {
      context.missing(_mandiMeta);
    }
    if (data.containsKey('price_per_quintal')) {
      context.handle(
        _pricePerQuintalMeta,
        pricePerQuintal.isAcceptableOrUnknown(
          data['price_per_quintal']!,
          _pricePerQuintalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerQuintalMeta);
    }
    if (data.containsKey('price_date')) {
      context.handle(
        _priceDateMeta,
        priceDate.isAcceptableOrUnknown(data['price_date']!, _priceDateMeta),
      );
    } else if (isInserting) {
      context.missing(_priceDateMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MarketPrice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MarketPrice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      commodity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commodity'],
      )!,
      mandi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mandi'],
      )!,
      pricePerQuintal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_quintal'],
      )!,
      priceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}price_date'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $MarketPricesTable createAlias(String alias) {
    return $MarketPricesTable(attachedDatabase, alias);
  }
}

class MarketPrice extends DataClass implements Insertable<MarketPrice> {
  final int id;
  final String commodity;
  final String mandi;
  final double pricePerQuintal;
  final DateTime priceDate;
  final DateTime fetchedAt;
  const MarketPrice({
    required this.id,
    required this.commodity,
    required this.mandi,
    required this.pricePerQuintal,
    required this.priceDate,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['commodity'] = Variable<String>(commodity);
    map['mandi'] = Variable<String>(mandi);
    map['price_per_quintal'] = Variable<double>(pricePerQuintal);
    map['price_date'] = Variable<DateTime>(priceDate);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  MarketPricesCompanion toCompanion(bool nullToAbsent) {
    return MarketPricesCompanion(
      id: Value(id),
      commodity: Value(commodity),
      mandi: Value(mandi),
      pricePerQuintal: Value(pricePerQuintal),
      priceDate: Value(priceDate),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory MarketPrice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MarketPrice(
      id: serializer.fromJson<int>(json['id']),
      commodity: serializer.fromJson<String>(json['commodity']),
      mandi: serializer.fromJson<String>(json['mandi']),
      pricePerQuintal: serializer.fromJson<double>(json['pricePerQuintal']),
      priceDate: serializer.fromJson<DateTime>(json['priceDate']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'commodity': serializer.toJson<String>(commodity),
      'mandi': serializer.toJson<String>(mandi),
      'pricePerQuintal': serializer.toJson<double>(pricePerQuintal),
      'priceDate': serializer.toJson<DateTime>(priceDate),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  MarketPrice copyWith({
    int? id,
    String? commodity,
    String? mandi,
    double? pricePerQuintal,
    DateTime? priceDate,
    DateTime? fetchedAt,
  }) => MarketPrice(
    id: id ?? this.id,
    commodity: commodity ?? this.commodity,
    mandi: mandi ?? this.mandi,
    pricePerQuintal: pricePerQuintal ?? this.pricePerQuintal,
    priceDate: priceDate ?? this.priceDate,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  MarketPrice copyWithCompanion(MarketPricesCompanion data) {
    return MarketPrice(
      id: data.id.present ? data.id.value : this.id,
      commodity: data.commodity.present ? data.commodity.value : this.commodity,
      mandi: data.mandi.present ? data.mandi.value : this.mandi,
      pricePerQuintal: data.pricePerQuintal.present
          ? data.pricePerQuintal.value
          : this.pricePerQuintal,
      priceDate: data.priceDate.present ? data.priceDate.value : this.priceDate,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MarketPrice(')
          ..write('id: $id, ')
          ..write('commodity: $commodity, ')
          ..write('mandi: $mandi, ')
          ..write('pricePerQuintal: $pricePerQuintal, ')
          ..write('priceDate: $priceDate, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, commodity, mandi, pricePerQuintal, priceDate, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MarketPrice &&
          other.id == this.id &&
          other.commodity == this.commodity &&
          other.mandi == this.mandi &&
          other.pricePerQuintal == this.pricePerQuintal &&
          other.priceDate == this.priceDate &&
          other.fetchedAt == this.fetchedAt);
}

class MarketPricesCompanion extends UpdateCompanion<MarketPrice> {
  final Value<int> id;
  final Value<String> commodity;
  final Value<String> mandi;
  final Value<double> pricePerQuintal;
  final Value<DateTime> priceDate;
  final Value<DateTime> fetchedAt;
  const MarketPricesCompanion({
    this.id = const Value.absent(),
    this.commodity = const Value.absent(),
    this.mandi = const Value.absent(),
    this.pricePerQuintal = const Value.absent(),
    this.priceDate = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  MarketPricesCompanion.insert({
    this.id = const Value.absent(),
    required String commodity,
    required String mandi,
    required double pricePerQuintal,
    required DateTime priceDate,
    required DateTime fetchedAt,
  }) : commodity = Value(commodity),
       mandi = Value(mandi),
       pricePerQuintal = Value(pricePerQuintal),
       priceDate = Value(priceDate),
       fetchedAt = Value(fetchedAt);
  static Insertable<MarketPrice> custom({
    Expression<int>? id,
    Expression<String>? commodity,
    Expression<String>? mandi,
    Expression<double>? pricePerQuintal,
    Expression<DateTime>? priceDate,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (commodity != null) 'commodity': commodity,
      if (mandi != null) 'mandi': mandi,
      if (pricePerQuintal != null) 'price_per_quintal': pricePerQuintal,
      if (priceDate != null) 'price_date': priceDate,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  MarketPricesCompanion copyWith({
    Value<int>? id,
    Value<String>? commodity,
    Value<String>? mandi,
    Value<double>? pricePerQuintal,
    Value<DateTime>? priceDate,
    Value<DateTime>? fetchedAt,
  }) {
    return MarketPricesCompanion(
      id: id ?? this.id,
      commodity: commodity ?? this.commodity,
      mandi: mandi ?? this.mandi,
      pricePerQuintal: pricePerQuintal ?? this.pricePerQuintal,
      priceDate: priceDate ?? this.priceDate,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (commodity.present) {
      map['commodity'] = Variable<String>(commodity.value);
    }
    if (mandi.present) {
      map['mandi'] = Variable<String>(mandi.value);
    }
    if (pricePerQuintal.present) {
      map['price_per_quintal'] = Variable<double>(pricePerQuintal.value);
    }
    if (priceDate.present) {
      map['price_date'] = Variable<DateTime>(priceDate.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MarketPricesCompanion(')
          ..write('id: $id, ')
          ..write('commodity: $commodity, ')
          ..write('mandi: $mandi, ')
          ..write('pricePerQuintal: $pricePerQuintal, ')
          ..write('priceDate: $priceDate, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $MspRatesTable extends MspRates with TableInfo<$MspRatesTable, MspRate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MspRatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _cropMeta = const VerificationMeta('crop');
  @override
  late final GeneratedColumn<String> crop = GeneratedColumn<String>(
    'crop',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<String> season = GeneratedColumn<String>(
    'season',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _pricePerQuintalMeta = const VerificationMeta(
    'pricePerQuintal',
  );
  @override
  late final GeneratedColumn<double> pricePerQuintal = GeneratedColumn<double>(
    'price_per_quintal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    crop,
    season,
    year,
    pricePerQuintal,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'msp_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MspRate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('crop')) {
      context.handle(
        _cropMeta,
        crop.isAcceptableOrUnknown(data['crop']!, _cropMeta),
      );
    } else if (isInserting) {
      context.missing(_cropMeta);
    }
    if (data.containsKey('season')) {
      context.handle(
        _seasonMeta,
        season.isAcceptableOrUnknown(data['season']!, _seasonMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('price_per_quintal')) {
      context.handle(
        _pricePerQuintalMeta,
        pricePerQuintal.isAcceptableOrUnknown(
          data['price_per_quintal']!,
          _pricePerQuintalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerQuintalMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MspRate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MspRate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      crop: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop'],
      )!,
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      pricePerQuintal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_quintal'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $MspRatesTable createAlias(String alias) {
    return $MspRatesTable(attachedDatabase, alias);
  }
}

class MspRate extends DataClass implements Insertable<MspRate> {
  final int id;
  final String crop;
  final String season;
  final int year;
  final double pricePerQuintal;
  final DateTime fetchedAt;
  const MspRate({
    required this.id,
    required this.crop,
    required this.season,
    required this.year,
    required this.pricePerQuintal,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['crop'] = Variable<String>(crop);
    map['season'] = Variable<String>(season);
    map['year'] = Variable<int>(year);
    map['price_per_quintal'] = Variable<double>(pricePerQuintal);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  MspRatesCompanion toCompanion(bool nullToAbsent) {
    return MspRatesCompanion(
      id: Value(id),
      crop: Value(crop),
      season: Value(season),
      year: Value(year),
      pricePerQuintal: Value(pricePerQuintal),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory MspRate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MspRate(
      id: serializer.fromJson<int>(json['id']),
      crop: serializer.fromJson<String>(json['crop']),
      season: serializer.fromJson<String>(json['season']),
      year: serializer.fromJson<int>(json['year']),
      pricePerQuintal: serializer.fromJson<double>(json['pricePerQuintal']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'crop': serializer.toJson<String>(crop),
      'season': serializer.toJson<String>(season),
      'year': serializer.toJson<int>(year),
      'pricePerQuintal': serializer.toJson<double>(pricePerQuintal),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  MspRate copyWith({
    int? id,
    String? crop,
    String? season,
    int? year,
    double? pricePerQuintal,
    DateTime? fetchedAt,
  }) => MspRate(
    id: id ?? this.id,
    crop: crop ?? this.crop,
    season: season ?? this.season,
    year: year ?? this.year,
    pricePerQuintal: pricePerQuintal ?? this.pricePerQuintal,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  MspRate copyWithCompanion(MspRatesCompanion data) {
    return MspRate(
      id: data.id.present ? data.id.value : this.id,
      crop: data.crop.present ? data.crop.value : this.crop,
      season: data.season.present ? data.season.value : this.season,
      year: data.year.present ? data.year.value : this.year,
      pricePerQuintal: data.pricePerQuintal.present
          ? data.pricePerQuintal.value
          : this.pricePerQuintal,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MspRate(')
          ..write('id: $id, ')
          ..write('crop: $crop, ')
          ..write('season: $season, ')
          ..write('year: $year, ')
          ..write('pricePerQuintal: $pricePerQuintal, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, crop, season, year, pricePerQuintal, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MspRate &&
          other.id == this.id &&
          other.crop == this.crop &&
          other.season == this.season &&
          other.year == this.year &&
          other.pricePerQuintal == this.pricePerQuintal &&
          other.fetchedAt == this.fetchedAt);
}

class MspRatesCompanion extends UpdateCompanion<MspRate> {
  final Value<int> id;
  final Value<String> crop;
  final Value<String> season;
  final Value<int> year;
  final Value<double> pricePerQuintal;
  final Value<DateTime> fetchedAt;
  const MspRatesCompanion({
    this.id = const Value.absent(),
    this.crop = const Value.absent(),
    this.season = const Value.absent(),
    this.year = const Value.absent(),
    this.pricePerQuintal = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  MspRatesCompanion.insert({
    this.id = const Value.absent(),
    required String crop,
    required String season,
    required int year,
    required double pricePerQuintal,
    required DateTime fetchedAt,
  }) : crop = Value(crop),
       season = Value(season),
       year = Value(year),
       pricePerQuintal = Value(pricePerQuintal),
       fetchedAt = Value(fetchedAt);
  static Insertable<MspRate> custom({
    Expression<int>? id,
    Expression<String>? crop,
    Expression<String>? season,
    Expression<int>? year,
    Expression<double>? pricePerQuintal,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (crop != null) 'crop': crop,
      if (season != null) 'season': season,
      if (year != null) 'year': year,
      if (pricePerQuintal != null) 'price_per_quintal': pricePerQuintal,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  MspRatesCompanion copyWith({
    Value<int>? id,
    Value<String>? crop,
    Value<String>? season,
    Value<int>? year,
    Value<double>? pricePerQuintal,
    Value<DateTime>? fetchedAt,
  }) {
    return MspRatesCompanion(
      id: id ?? this.id,
      crop: crop ?? this.crop,
      season: season ?? this.season,
      year: year ?? this.year,
      pricePerQuintal: pricePerQuintal ?? this.pricePerQuintal,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (crop.present) {
      map['crop'] = Variable<String>(crop.value);
    }
    if (season.present) {
      map['season'] = Variable<String>(season.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (pricePerQuintal.present) {
      map['price_per_quintal'] = Variable<double>(pricePerQuintal.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MspRatesCompanion(')
          ..write('id: $id, ')
          ..write('crop: $crop, ')
          ..write('season: $season, ')
          ..write('year: $year, ')
          ..write('pricePerQuintal: $pricePerQuintal, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $SoilReportsTable extends SoilReports
    with TableInfo<$SoilReportsTable, SoilReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SoilReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nitrogenMeta = const VerificationMeta(
    'nitrogen',
  );
  @override
  late final GeneratedColumn<double> nitrogen = GeneratedColumn<double>(
    'nitrogen',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phosphorusMeta = const VerificationMeta(
    'phosphorus',
  );
  @override
  late final GeneratedColumn<double> phosphorus = GeneratedColumn<double>(
    'phosphorus',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _potassiumMeta = const VerificationMeta(
    'potassium',
  );
  @override
  late final GeneratedColumn<double> potassium = GeneratedColumn<double>(
    'potassium',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phMeta = const VerificationMeta('ph');
  @override
  late final GeneratedColumn<double> ph = GeneratedColumn<double>(
    'ph',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _organicCarbonMeta = const VerificationMeta(
    'organicCarbon',
  );
  @override
  late final GeneratedColumn<double> organicCarbon = GeneratedColumn<double>(
    'organic_carbon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rainfallMmMeta = const VerificationMeta(
    'rainfallMm',
  );
  @override
  late final GeneratedColumn<double> rainfallMm = GeneratedColumn<double>(
    'rainfall_mm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _temperatureCMeta = const VerificationMeta(
    'temperatureC',
  );
  @override
  late final GeneratedColumn<double> temperatureC = GeneratedColumn<double>(
    'temperature_c',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _humidityPctMeta = const VerificationMeta(
    'humidityPct',
  );
  @override
  late final GeneratedColumn<double> humidityPct = GeneratedColumn<double>(
    'humidity_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nitrogen,
    phosphorus,
    potassium,
    ph,
    organicCarbon,
    rainfallMm,
    temperatureC,
    humidityPct,
    createdAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'soil_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<SoilReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nitrogen')) {
      context.handle(
        _nitrogenMeta,
        nitrogen.isAcceptableOrUnknown(data['nitrogen']!, _nitrogenMeta),
      );
    } else if (isInserting) {
      context.missing(_nitrogenMeta);
    }
    if (data.containsKey('phosphorus')) {
      context.handle(
        _phosphorusMeta,
        phosphorus.isAcceptableOrUnknown(data['phosphorus']!, _phosphorusMeta),
      );
    } else if (isInserting) {
      context.missing(_phosphorusMeta);
    }
    if (data.containsKey('potassium')) {
      context.handle(
        _potassiumMeta,
        potassium.isAcceptableOrUnknown(data['potassium']!, _potassiumMeta),
      );
    } else if (isInserting) {
      context.missing(_potassiumMeta);
    }
    if (data.containsKey('ph')) {
      context.handle(_phMeta, ph.isAcceptableOrUnknown(data['ph']!, _phMeta));
    } else if (isInserting) {
      context.missing(_phMeta);
    }
    if (data.containsKey('organic_carbon')) {
      context.handle(
        _organicCarbonMeta,
        organicCarbon.isAcceptableOrUnknown(
          data['organic_carbon']!,
          _organicCarbonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organicCarbonMeta);
    }
    if (data.containsKey('rainfall_mm')) {
      context.handle(
        _rainfallMmMeta,
        rainfallMm.isAcceptableOrUnknown(data['rainfall_mm']!, _rainfallMmMeta),
      );
    }
    if (data.containsKey('temperature_c')) {
      context.handle(
        _temperatureCMeta,
        temperatureC.isAcceptableOrUnknown(
          data['temperature_c']!,
          _temperatureCMeta,
        ),
      );
    }
    if (data.containsKey('humidity_pct')) {
      context.handle(
        _humidityPctMeta,
        humidityPct.isAcceptableOrUnknown(
          data['humidity_pct']!,
          _humidityPctMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SoilReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SoilReport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nitrogen: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}nitrogen'],
      )!,
      phosphorus: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}phosphorus'],
      )!,
      potassium: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}potassium'],
      )!,
      ph: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ph'],
      )!,
      organicCarbon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}organic_carbon'],
      )!,
      rainfallMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rainfall_mm'],
      )!,
      temperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_c'],
      )!,
      humidityPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}humidity_pct'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $SoilReportsTable createAlias(String alias) {
    return $SoilReportsTable(attachedDatabase, alias);
  }
}

class SoilReport extends DataClass implements Insertable<SoilReport> {
  final String id;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double ph;
  final double organicCarbon;
  final double rainfallMm;
  final double temperatureC;
  final double humidityPct;
  final DateTime createdAt;
  final String syncStatus;
  const SoilReport({
    required this.id,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.ph,
    required this.organicCarbon,
    required this.rainfallMm,
    required this.temperatureC,
    required this.humidityPct,
    required this.createdAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nitrogen'] = Variable<double>(nitrogen);
    map['phosphorus'] = Variable<double>(phosphorus);
    map['potassium'] = Variable<double>(potassium);
    map['ph'] = Variable<double>(ph);
    map['organic_carbon'] = Variable<double>(organicCarbon);
    map['rainfall_mm'] = Variable<double>(rainfallMm);
    map['temperature_c'] = Variable<double>(temperatureC);
    map['humidity_pct'] = Variable<double>(humidityPct);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  SoilReportsCompanion toCompanion(bool nullToAbsent) {
    return SoilReportsCompanion(
      id: Value(id),
      nitrogen: Value(nitrogen),
      phosphorus: Value(phosphorus),
      potassium: Value(potassium),
      ph: Value(ph),
      organicCarbon: Value(organicCarbon),
      rainfallMm: Value(rainfallMm),
      temperatureC: Value(temperatureC),
      humidityPct: Value(humidityPct),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory SoilReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SoilReport(
      id: serializer.fromJson<String>(json['id']),
      nitrogen: serializer.fromJson<double>(json['nitrogen']),
      phosphorus: serializer.fromJson<double>(json['phosphorus']),
      potassium: serializer.fromJson<double>(json['potassium']),
      ph: serializer.fromJson<double>(json['ph']),
      organicCarbon: serializer.fromJson<double>(json['organicCarbon']),
      rainfallMm: serializer.fromJson<double>(json['rainfallMm']),
      temperatureC: serializer.fromJson<double>(json['temperatureC']),
      humidityPct: serializer.fromJson<double>(json['humidityPct']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nitrogen': serializer.toJson<double>(nitrogen),
      'phosphorus': serializer.toJson<double>(phosphorus),
      'potassium': serializer.toJson<double>(potassium),
      'ph': serializer.toJson<double>(ph),
      'organicCarbon': serializer.toJson<double>(organicCarbon),
      'rainfallMm': serializer.toJson<double>(rainfallMm),
      'temperatureC': serializer.toJson<double>(temperatureC),
      'humidityPct': serializer.toJson<double>(humidityPct),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  SoilReport copyWith({
    String? id,
    double? nitrogen,
    double? phosphorus,
    double? potassium,
    double? ph,
    double? organicCarbon,
    double? rainfallMm,
    double? temperatureC,
    double? humidityPct,
    DateTime? createdAt,
    String? syncStatus,
  }) => SoilReport(
    id: id ?? this.id,
    nitrogen: nitrogen ?? this.nitrogen,
    phosphorus: phosphorus ?? this.phosphorus,
    potassium: potassium ?? this.potassium,
    ph: ph ?? this.ph,
    organicCarbon: organicCarbon ?? this.organicCarbon,
    rainfallMm: rainfallMm ?? this.rainfallMm,
    temperatureC: temperatureC ?? this.temperatureC,
    humidityPct: humidityPct ?? this.humidityPct,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  SoilReport copyWithCompanion(SoilReportsCompanion data) {
    return SoilReport(
      id: data.id.present ? data.id.value : this.id,
      nitrogen: data.nitrogen.present ? data.nitrogen.value : this.nitrogen,
      phosphorus: data.phosphorus.present
          ? data.phosphorus.value
          : this.phosphorus,
      potassium: data.potassium.present ? data.potassium.value : this.potassium,
      ph: data.ph.present ? data.ph.value : this.ph,
      organicCarbon: data.organicCarbon.present
          ? data.organicCarbon.value
          : this.organicCarbon,
      rainfallMm: data.rainfallMm.present
          ? data.rainfallMm.value
          : this.rainfallMm,
      temperatureC: data.temperatureC.present
          ? data.temperatureC.value
          : this.temperatureC,
      humidityPct: data.humidityPct.present
          ? data.humidityPct.value
          : this.humidityPct,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SoilReport(')
          ..write('id: $id, ')
          ..write('nitrogen: $nitrogen, ')
          ..write('phosphorus: $phosphorus, ')
          ..write('potassium: $potassium, ')
          ..write('ph: $ph, ')
          ..write('organicCarbon: $organicCarbon, ')
          ..write('rainfallMm: $rainfallMm, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('humidityPct: $humidityPct, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nitrogen,
    phosphorus,
    potassium,
    ph,
    organicCarbon,
    rainfallMm,
    temperatureC,
    humidityPct,
    createdAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SoilReport &&
          other.id == this.id &&
          other.nitrogen == this.nitrogen &&
          other.phosphorus == this.phosphorus &&
          other.potassium == this.potassium &&
          other.ph == this.ph &&
          other.organicCarbon == this.organicCarbon &&
          other.rainfallMm == this.rainfallMm &&
          other.temperatureC == this.temperatureC &&
          other.humidityPct == this.humidityPct &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus);
}

class SoilReportsCompanion extends UpdateCompanion<SoilReport> {
  final Value<String> id;
  final Value<double> nitrogen;
  final Value<double> phosphorus;
  final Value<double> potassium;
  final Value<double> ph;
  final Value<double> organicCarbon;
  final Value<double> rainfallMm;
  final Value<double> temperatureC;
  final Value<double> humidityPct;
  final Value<DateTime> createdAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const SoilReportsCompanion({
    this.id = const Value.absent(),
    this.nitrogen = const Value.absent(),
    this.phosphorus = const Value.absent(),
    this.potassium = const Value.absent(),
    this.ph = const Value.absent(),
    this.organicCarbon = const Value.absent(),
    this.rainfallMm = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.humidityPct = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SoilReportsCompanion.insert({
    required String id,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
    required double organicCarbon,
    this.rainfallMm = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.humidityPct = const Value.absent(),
    required DateTime createdAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nitrogen = Value(nitrogen),
       phosphorus = Value(phosphorus),
       potassium = Value(potassium),
       ph = Value(ph),
       organicCarbon = Value(organicCarbon),
       createdAt = Value(createdAt);
  static Insertable<SoilReport> custom({
    Expression<String>? id,
    Expression<double>? nitrogen,
    Expression<double>? phosphorus,
    Expression<double>? potassium,
    Expression<double>? ph,
    Expression<double>? organicCarbon,
    Expression<double>? rainfallMm,
    Expression<double>? temperatureC,
    Expression<double>? humidityPct,
    Expression<DateTime>? createdAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nitrogen != null) 'nitrogen': nitrogen,
      if (phosphorus != null) 'phosphorus': phosphorus,
      if (potassium != null) 'potassium': potassium,
      if (ph != null) 'ph': ph,
      if (organicCarbon != null) 'organic_carbon': organicCarbon,
      if (rainfallMm != null) 'rainfall_mm': rainfallMm,
      if (temperatureC != null) 'temperature_c': temperatureC,
      if (humidityPct != null) 'humidity_pct': humidityPct,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SoilReportsCompanion copyWith({
    Value<String>? id,
    Value<double>? nitrogen,
    Value<double>? phosphorus,
    Value<double>? potassium,
    Value<double>? ph,
    Value<double>? organicCarbon,
    Value<double>? rainfallMm,
    Value<double>? temperatureC,
    Value<double>? humidityPct,
    Value<DateTime>? createdAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return SoilReportsCompanion(
      id: id ?? this.id,
      nitrogen: nitrogen ?? this.nitrogen,
      phosphorus: phosphorus ?? this.phosphorus,
      potassium: potassium ?? this.potassium,
      ph: ph ?? this.ph,
      organicCarbon: organicCarbon ?? this.organicCarbon,
      rainfallMm: rainfallMm ?? this.rainfallMm,
      temperatureC: temperatureC ?? this.temperatureC,
      humidityPct: humidityPct ?? this.humidityPct,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nitrogen.present) {
      map['nitrogen'] = Variable<double>(nitrogen.value);
    }
    if (phosphorus.present) {
      map['phosphorus'] = Variable<double>(phosphorus.value);
    }
    if (potassium.present) {
      map['potassium'] = Variable<double>(potassium.value);
    }
    if (ph.present) {
      map['ph'] = Variable<double>(ph.value);
    }
    if (organicCarbon.present) {
      map['organic_carbon'] = Variable<double>(organicCarbon.value);
    }
    if (rainfallMm.present) {
      map['rainfall_mm'] = Variable<double>(rainfallMm.value);
    }
    if (temperatureC.present) {
      map['temperature_c'] = Variable<double>(temperatureC.value);
    }
    if (humidityPct.present) {
      map['humidity_pct'] = Variable<double>(humidityPct.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SoilReportsCompanion(')
          ..write('id: $id, ')
          ..write('nitrogen: $nitrogen, ')
          ..write('phosphorus: $phosphorus, ')
          ..write('potassium: $potassium, ')
          ..write('ph: $ph, ')
          ..write('organicCarbon: $organicCarbon, ')
          ..write('rainfallMm: $rainfallMm, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('humidityPct: $humidityPct, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CropRecommendationsTable extends CropRecommendations
    with TableInfo<$CropRecommendationsTable, CropRecommendation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CropRecommendationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _soilReportIdMeta = const VerificationMeta(
    'soilReportId',
  );
  @override
  late final GeneratedColumn<String> soilReportId = GeneratedColumn<String>(
    'soil_report_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropNameMeta = const VerificationMeta(
    'cropName',
  );
  @override
  late final GeneratedColumn<String> cropName = GeneratedColumn<String>(
    'crop_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rankPositionMeta = const VerificationMeta(
    'rankPosition',
  );
  @override
  late final GeneratedColumn<int> rankPosition = GeneratedColumn<int>(
    'rank_position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _suitabilityScoreMeta = const VerificationMeta(
    'suitabilityScore',
  );
  @override
  late final GeneratedColumn<double> suitabilityScore = GeneratedColumn<double>(
    'suitability_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nutrientAdviceJsonMeta =
      const VerificationMeta('nutrientAdviceJson');
  @override
  late final GeneratedColumn<String> nutrientAdviceJson =
      GeneratedColumn<String>(
        'nutrient_advice_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    soilReportId,
    cropName,
    rankPosition,
    suitabilityScore,
    nutrientAdviceJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crop_recommendations';
  @override
  VerificationContext validateIntegrity(
    Insertable<CropRecommendation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('soil_report_id')) {
      context.handle(
        _soilReportIdMeta,
        soilReportId.isAcceptableOrUnknown(
          data['soil_report_id']!,
          _soilReportIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_soilReportIdMeta);
    }
    if (data.containsKey('crop_name')) {
      context.handle(
        _cropNameMeta,
        cropName.isAcceptableOrUnknown(data['crop_name']!, _cropNameMeta),
      );
    } else if (isInserting) {
      context.missing(_cropNameMeta);
    }
    if (data.containsKey('rank_position')) {
      context.handle(
        _rankPositionMeta,
        rankPosition.isAcceptableOrUnknown(
          data['rank_position']!,
          _rankPositionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rankPositionMeta);
    }
    if (data.containsKey('suitability_score')) {
      context.handle(
        _suitabilityScoreMeta,
        suitabilityScore.isAcceptableOrUnknown(
          data['suitability_score']!,
          _suitabilityScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_suitabilityScoreMeta);
    }
    if (data.containsKey('nutrient_advice_json')) {
      context.handle(
        _nutrientAdviceJsonMeta,
        nutrientAdviceJson.isAcceptableOrUnknown(
          data['nutrient_advice_json']!,
          _nutrientAdviceJsonMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CropRecommendation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CropRecommendation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      soilReportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}soil_report_id'],
      )!,
      cropName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_name'],
      )!,
      rankPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank_position'],
      )!,
      suitabilityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}suitability_score'],
      )!,
      nutrientAdviceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nutrient_advice_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CropRecommendationsTable createAlias(String alias) {
    return $CropRecommendationsTable(attachedDatabase, alias);
  }
}

class CropRecommendation extends DataClass
    implements Insertable<CropRecommendation> {
  final int id;
  final String soilReportId;
  final String cropName;
  final int rankPosition;
  final double suitabilityScore;
  final String nutrientAdviceJson;
  final DateTime cachedAt;
  const CropRecommendation({
    required this.id,
    required this.soilReportId,
    required this.cropName,
    required this.rankPosition,
    required this.suitabilityScore,
    required this.nutrientAdviceJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['soil_report_id'] = Variable<String>(soilReportId);
    map['crop_name'] = Variable<String>(cropName);
    map['rank_position'] = Variable<int>(rankPosition);
    map['suitability_score'] = Variable<double>(suitabilityScore);
    map['nutrient_advice_json'] = Variable<String>(nutrientAdviceJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CropRecommendationsCompanion toCompanion(bool nullToAbsent) {
    return CropRecommendationsCompanion(
      id: Value(id),
      soilReportId: Value(soilReportId),
      cropName: Value(cropName),
      rankPosition: Value(rankPosition),
      suitabilityScore: Value(suitabilityScore),
      nutrientAdviceJson: Value(nutrientAdviceJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CropRecommendation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CropRecommendation(
      id: serializer.fromJson<int>(json['id']),
      soilReportId: serializer.fromJson<String>(json['soilReportId']),
      cropName: serializer.fromJson<String>(json['cropName']),
      rankPosition: serializer.fromJson<int>(json['rankPosition']),
      suitabilityScore: serializer.fromJson<double>(json['suitabilityScore']),
      nutrientAdviceJson: serializer.fromJson<String>(
        json['nutrientAdviceJson'],
      ),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'soilReportId': serializer.toJson<String>(soilReportId),
      'cropName': serializer.toJson<String>(cropName),
      'rankPosition': serializer.toJson<int>(rankPosition),
      'suitabilityScore': serializer.toJson<double>(suitabilityScore),
      'nutrientAdviceJson': serializer.toJson<String>(nutrientAdviceJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CropRecommendation copyWith({
    int? id,
    String? soilReportId,
    String? cropName,
    int? rankPosition,
    double? suitabilityScore,
    String? nutrientAdviceJson,
    DateTime? cachedAt,
  }) => CropRecommendation(
    id: id ?? this.id,
    soilReportId: soilReportId ?? this.soilReportId,
    cropName: cropName ?? this.cropName,
    rankPosition: rankPosition ?? this.rankPosition,
    suitabilityScore: suitabilityScore ?? this.suitabilityScore,
    nutrientAdviceJson: nutrientAdviceJson ?? this.nutrientAdviceJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CropRecommendation copyWithCompanion(CropRecommendationsCompanion data) {
    return CropRecommendation(
      id: data.id.present ? data.id.value : this.id,
      soilReportId: data.soilReportId.present
          ? data.soilReportId.value
          : this.soilReportId,
      cropName: data.cropName.present ? data.cropName.value : this.cropName,
      rankPosition: data.rankPosition.present
          ? data.rankPosition.value
          : this.rankPosition,
      suitabilityScore: data.suitabilityScore.present
          ? data.suitabilityScore.value
          : this.suitabilityScore,
      nutrientAdviceJson: data.nutrientAdviceJson.present
          ? data.nutrientAdviceJson.value
          : this.nutrientAdviceJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CropRecommendation(')
          ..write('id: $id, ')
          ..write('soilReportId: $soilReportId, ')
          ..write('cropName: $cropName, ')
          ..write('rankPosition: $rankPosition, ')
          ..write('suitabilityScore: $suitabilityScore, ')
          ..write('nutrientAdviceJson: $nutrientAdviceJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    soilReportId,
    cropName,
    rankPosition,
    suitabilityScore,
    nutrientAdviceJson,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CropRecommendation &&
          other.id == this.id &&
          other.soilReportId == this.soilReportId &&
          other.cropName == this.cropName &&
          other.rankPosition == this.rankPosition &&
          other.suitabilityScore == this.suitabilityScore &&
          other.nutrientAdviceJson == this.nutrientAdviceJson &&
          other.cachedAt == this.cachedAt);
}

class CropRecommendationsCompanion extends UpdateCompanion<CropRecommendation> {
  final Value<int> id;
  final Value<String> soilReportId;
  final Value<String> cropName;
  final Value<int> rankPosition;
  final Value<double> suitabilityScore;
  final Value<String> nutrientAdviceJson;
  final Value<DateTime> cachedAt;
  const CropRecommendationsCompanion({
    this.id = const Value.absent(),
    this.soilReportId = const Value.absent(),
    this.cropName = const Value.absent(),
    this.rankPosition = const Value.absent(),
    this.suitabilityScore = const Value.absent(),
    this.nutrientAdviceJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CropRecommendationsCompanion.insert({
    this.id = const Value.absent(),
    required String soilReportId,
    required String cropName,
    required int rankPosition,
    required double suitabilityScore,
    this.nutrientAdviceJson = const Value.absent(),
    required DateTime cachedAt,
  }) : soilReportId = Value(soilReportId),
       cropName = Value(cropName),
       rankPosition = Value(rankPosition),
       suitabilityScore = Value(suitabilityScore),
       cachedAt = Value(cachedAt);
  static Insertable<CropRecommendation> custom({
    Expression<int>? id,
    Expression<String>? soilReportId,
    Expression<String>? cropName,
    Expression<int>? rankPosition,
    Expression<double>? suitabilityScore,
    Expression<String>? nutrientAdviceJson,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (soilReportId != null) 'soil_report_id': soilReportId,
      if (cropName != null) 'crop_name': cropName,
      if (rankPosition != null) 'rank_position': rankPosition,
      if (suitabilityScore != null) 'suitability_score': suitabilityScore,
      if (nutrientAdviceJson != null)
        'nutrient_advice_json': nutrientAdviceJson,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CropRecommendationsCompanion copyWith({
    Value<int>? id,
    Value<String>? soilReportId,
    Value<String>? cropName,
    Value<int>? rankPosition,
    Value<double>? suitabilityScore,
    Value<String>? nutrientAdviceJson,
    Value<DateTime>? cachedAt,
  }) {
    return CropRecommendationsCompanion(
      id: id ?? this.id,
      soilReportId: soilReportId ?? this.soilReportId,
      cropName: cropName ?? this.cropName,
      rankPosition: rankPosition ?? this.rankPosition,
      suitabilityScore: suitabilityScore ?? this.suitabilityScore,
      nutrientAdviceJson: nutrientAdviceJson ?? this.nutrientAdviceJson,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (soilReportId.present) {
      map['soil_report_id'] = Variable<String>(soilReportId.value);
    }
    if (cropName.present) {
      map['crop_name'] = Variable<String>(cropName.value);
    }
    if (rankPosition.present) {
      map['rank_position'] = Variable<int>(rankPosition.value);
    }
    if (suitabilityScore.present) {
      map['suitability_score'] = Variable<double>(suitabilityScore.value);
    }
    if (nutrientAdviceJson.present) {
      map['nutrient_advice_json'] = Variable<String>(nutrientAdviceJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CropRecommendationsCompanion(')
          ..write('id: $id, ')
          ..write('soilReportId: $soilReportId, ')
          ..write('cropName: $cropName, ')
          ..write('rankPosition: $rankPosition, ')
          ..write('suitabilityScore: $suitabilityScore, ')
          ..write('nutrientAdviceJson: $nutrientAdviceJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $DiseaseDetectionsTable extends DiseaseDetections
    with TableInfo<$DiseaseDetectionsTable, DiseaseDetection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiseaseDetectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropIdMeta = const VerificationMeta('cropId');
  @override
  late final GeneratedColumn<String> cropId = GeneratedColumn<String>(
    'crop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('potato'),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consentSharedMeta = const VerificationMeta(
    'consentShared',
  );
  @override
  late final GeneratedColumn<bool> consentShared = GeneratedColumn<bool>(
    'consent_shared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("consent_shared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isMockMeta = const VerificationMeta('isMock');
  @override
  late final GeneratedColumn<bool> isMock = GeneratedColumn<bool>(
    'is_mock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_mock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cropId,
    label,
    confidence,
    imagePath,
    lat,
    lng,
    consentShared,
    isMock,
    createdAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'disease_detections';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiseaseDetection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('crop_id')) {
      context.handle(
        _cropIdMeta,
        cropId.isAcceptableOrUnknown(data['crop_id']!, _cropIdMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('consent_shared')) {
      context.handle(
        _consentSharedMeta,
        consentShared.isAcceptableOrUnknown(
          data['consent_shared']!,
          _consentSharedMeta,
        ),
      );
    }
    if (data.containsKey('is_mock')) {
      context.handle(
        _isMockMeta,
        isMock.isAcceptableOrUnknown(data['is_mock']!, _isMockMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiseaseDetection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiseaseDetection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cropId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      consentShared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consent_shared'],
      )!,
      isMock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_mock'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $DiseaseDetectionsTable createAlias(String alias) {
    return $DiseaseDetectionsTable(attachedDatabase, alias);
  }
}

class DiseaseDetection extends DataClass
    implements Insertable<DiseaseDetection> {
  final String id;
  final String cropId;
  final String label;
  final double confidence;
  final String? imagePath;
  final double? lat;
  final double? lng;
  final bool consentShared;
  final bool isMock;
  final DateTime createdAt;
  final String syncStatus;
  const DiseaseDetection({
    required this.id,
    required this.cropId,
    required this.label,
    required this.confidence,
    this.imagePath,
    this.lat,
    this.lng,
    required this.consentShared,
    required this.isMock,
    required this.createdAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['crop_id'] = Variable<String>(cropId);
    map['label'] = Variable<String>(label);
    map['confidence'] = Variable<double>(confidence);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    map['consent_shared'] = Variable<bool>(consentShared);
    map['is_mock'] = Variable<bool>(isMock);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  DiseaseDetectionsCompanion toCompanion(bool nullToAbsent) {
    return DiseaseDetectionsCompanion(
      id: Value(id),
      cropId: Value(cropId),
      label: Value(label),
      confidence: Value(confidence),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      consentShared: Value(consentShared),
      isMock: Value(isMock),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory DiseaseDetection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiseaseDetection(
      id: serializer.fromJson<String>(json['id']),
      cropId: serializer.fromJson<String>(json['cropId']),
      label: serializer.fromJson<String>(json['label']),
      confidence: serializer.fromJson<double>(json['confidence']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      consentShared: serializer.fromJson<bool>(json['consentShared']),
      isMock: serializer.fromJson<bool>(json['isMock']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cropId': serializer.toJson<String>(cropId),
      'label': serializer.toJson<String>(label),
      'confidence': serializer.toJson<double>(confidence),
      'imagePath': serializer.toJson<String?>(imagePath),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'consentShared': serializer.toJson<bool>(consentShared),
      'isMock': serializer.toJson<bool>(isMock),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  DiseaseDetection copyWith({
    String? id,
    String? cropId,
    String? label,
    double? confidence,
    Value<String?> imagePath = const Value.absent(),
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    bool? consentShared,
    bool? isMock,
    DateTime? createdAt,
    String? syncStatus,
  }) => DiseaseDetection(
    id: id ?? this.id,
    cropId: cropId ?? this.cropId,
    label: label ?? this.label,
    confidence: confidence ?? this.confidence,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    consentShared: consentShared ?? this.consentShared,
    isMock: isMock ?? this.isMock,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  DiseaseDetection copyWithCompanion(DiseaseDetectionsCompanion data) {
    return DiseaseDetection(
      id: data.id.present ? data.id.value : this.id,
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      label: data.label.present ? data.label.value : this.label,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      consentShared: data.consentShared.present
          ? data.consentShared.value
          : this.consentShared,
      isMock: data.isMock.present ? data.isMock.value : this.isMock,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiseaseDetection(')
          ..write('id: $id, ')
          ..write('cropId: $cropId, ')
          ..write('label: $label, ')
          ..write('confidence: $confidence, ')
          ..write('imagePath: $imagePath, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('consentShared: $consentShared, ')
          ..write('isMock: $isMock, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cropId,
    label,
    confidence,
    imagePath,
    lat,
    lng,
    consentShared,
    isMock,
    createdAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiseaseDetection &&
          other.id == this.id &&
          other.cropId == this.cropId &&
          other.label == this.label &&
          other.confidence == this.confidence &&
          other.imagePath == this.imagePath &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.consentShared == this.consentShared &&
          other.isMock == this.isMock &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus);
}

class DiseaseDetectionsCompanion extends UpdateCompanion<DiseaseDetection> {
  final Value<String> id;
  final Value<String> cropId;
  final Value<String> label;
  final Value<double> confidence;
  final Value<String?> imagePath;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<bool> consentShared;
  final Value<bool> isMock;
  final Value<DateTime> createdAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const DiseaseDetectionsCompanion({
    this.id = const Value.absent(),
    this.cropId = const Value.absent(),
    this.label = const Value.absent(),
    this.confidence = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.consentShared = const Value.absent(),
    this.isMock = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiseaseDetectionsCompanion.insert({
    required String id,
    this.cropId = const Value.absent(),
    required String label,
    required double confidence,
    this.imagePath = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.consentShared = const Value.absent(),
    this.isMock = const Value.absent(),
    required DateTime createdAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       confidence = Value(confidence),
       createdAt = Value(createdAt);
  static Insertable<DiseaseDetection> custom({
    Expression<String>? id,
    Expression<String>? cropId,
    Expression<String>? label,
    Expression<double>? confidence,
    Expression<String>? imagePath,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<bool>? consentShared,
    Expression<bool>? isMock,
    Expression<DateTime>? createdAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cropId != null) 'crop_id': cropId,
      if (label != null) 'label': label,
      if (confidence != null) 'confidence': confidence,
      if (imagePath != null) 'image_path': imagePath,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (consentShared != null) 'consent_shared': consentShared,
      if (isMock != null) 'is_mock': isMock,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiseaseDetectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? cropId,
    Value<String>? label,
    Value<double>? confidence,
    Value<String?>? imagePath,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<bool>? consentShared,
    Value<bool>? isMock,
    Value<DateTime>? createdAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return DiseaseDetectionsCompanion(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      imagePath: imagePath ?? this.imagePath,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      consentShared: consentShared ?? this.consentShared,
      isMock: isMock ?? this.isMock,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cropId.present) {
      map['crop_id'] = Variable<String>(cropId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (consentShared.present) {
      map['consent_shared'] = Variable<bool>(consentShared.value);
    }
    if (isMock.present) {
      map['is_mock'] = Variable<bool>(isMock.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiseaseDetectionsCompanion(')
          ..write('id: $id, ')
          ..write('cropId: $cropId, ')
          ..write('label: $label, ')
          ..write('confidence: $confidence, ')
          ..write('imagePath: $imagePath, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('consentShared: $consentShared, ')
          ..write('isMock: $isMock, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricePerUnitMeta = const VerificationMeta(
    'pricePerUnit',
  );
  @override
  late final GeneratedColumn<double> pricePerUnit = GeneratedColumn<double>(
    'price_per_unit',
    aliasedName,
    false,
    type: DriftSqlType.double,
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
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    pricePerUnit,
    unit,
    imageUrl,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('price_per_unit')) {
      context.handle(
        _pricePerUnitMeta,
        pricePerUnit.isAcceptableOrUnknown(
          data['price_per_unit']!,
          _pricePerUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerUnitMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      pricePerUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_unit'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String name;
  final String category;
  final double pricePerUnit;
  final String unit;
  final String? imageUrl;
  final String? description;
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerUnit,
    required this.unit,
    this.imageUrl,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['price_per_unit'] = Variable<double>(pricePerUnit);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      pricePerUnit: Value(pricePerUnit),
      unit: Value(unit),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      pricePerUnit: serializer.fromJson<double>(json['pricePerUnit']),
      unit: serializer.fromJson<String>(json['unit']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'pricePerUnit': serializer.toJson<double>(pricePerUnit),
      'unit': serializer.toJson<String>(unit),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'description': serializer.toJson<String?>(description),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? pricePerUnit,
    String? unit,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> description = const Value.absent(),
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    unit: unit ?? this.unit,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    description: description.present ? description.value : this.description,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      pricePerUnit: data.pricePerUnit.present
          ? data.pricePerUnit.value
          : this.pricePerUnit,
      unit: data.unit.present ? data.unit.value : this.unit,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('pricePerUnit: $pricePerUnit, ')
          ..write('unit: $unit, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    pricePerUnit,
    unit,
    imageUrl,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.pricePerUnit == this.pricePerUnit &&
          other.unit == this.unit &&
          other.imageUrl == this.imageUrl &&
          other.description == this.description);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<double> pricePerUnit;
  final Value<String> unit;
  final Value<String?> imageUrl;
  final Value<String?> description;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.pricePerUnit = const Value.absent(),
    this.unit = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    required String category,
    required double pricePerUnit,
    required String unit,
    this.imageUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       pricePerUnit = Value(pricePerUnit),
       unit = Value(unit);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<double>? pricePerUnit,
    Expression<String>? unit,
    Expression<String>? imageUrl,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (pricePerUnit != null) 'price_per_unit': pricePerUnit,
      if (unit != null) 'unit': unit,
      if (imageUrl != null) 'image_url': imageUrl,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<double>? pricePerUnit,
    Value<String>? unit,
    Value<String?>? imageUrl,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (pricePerUnit.present) {
      map['price_per_unit'] = Variable<double>(pricePerUnit.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('pricePerUnit: $pricePerUnit, ')
          ..write('unit: $unit, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('placed'),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    status,
    totalAmount,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Order> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final String id;
  final DateTime createdAt;
  final String status;
  final double totalAmount;
  final String syncStatus;
  const Order({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    map['total_amount'] = Variable<double>(totalAmount);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      status: Value(status),
      totalAmount: Value(totalAmount),
      syncStatus: Value(syncStatus),
    );
  }

  factory Order.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  Order copyWith({
    String? id,
    DateTime? createdAt,
    String? status,
    double? totalAmount,
    String? syncStatus,
  }) => Order(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    totalAmount: totalAmount ?? this.totalAmount,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, status, totalAmount, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.totalAmount == this.totalAmount &&
          other.syncStatus == this.syncStatus);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<double> totalAmount;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required DateTime createdAt,
    this.status = const Value.absent(),
    required double totalAmount,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       totalAmount = Value(totalAmount);
  static Insertable<Order> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<double>? totalAmount,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<String>? status,
    Value<double>? totalAmount,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderItemsTable extends OrderItems
    with TableInfo<$OrderItemsTable, OrderItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    productId,
    productName,
    quantity,
    unitPrice,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
    );
  }

  @override
  $OrderItemsTable createAlias(String alias) {
    return $OrderItemsTable(attachedDatabase, alias);
  }
}

class OrderItem extends DataClass implements Insertable<OrderItem> {
  final int id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order_id'] = Variable<String>(orderId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['quantity'] = Variable<int>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    return map;
  }

  OrderItemsCompanion toCompanion(bool nullToAbsent) {
    return OrderItemsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      productId: Value(productId),
      productName: Value(productName),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
    );
  }

  factory OrderItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderItem(
      id: serializer.fromJson<int>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderId': serializer.toJson<String>(orderId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'quantity': serializer.toJson<int>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
    };
  }

  OrderItem copyWith({
    int? id,
    String? orderId,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
  }) => OrderItem(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
  );
  OrderItem copyWithCompanion(OrderItemsCompanion data) {
    return OrderItem(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderItem(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, orderId, productId, productName, quantity, unitPrice);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItem &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice);
}

class OrderItemsCompanion extends UpdateCompanion<OrderItem> {
  final Value<int> id;
  final Value<String> orderId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<int> quantity;
  final Value<double> unitPrice;
  const OrderItemsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
  });
  OrderItemsCompanion.insert({
    this.id = const Value.absent(),
    required String orderId,
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
  }) : orderId = Value(orderId),
       productId = Value(productId),
       productName = Value(productName),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice);
  static Insertable<OrderItem> custom({
    Expression<int>? id,
    Expression<String>? orderId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<int>? quantity,
    Expression<double>? unitPrice,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
    });
  }

  OrderItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? orderId,
    Value<String>? productId,
    Value<String>? productName,
    Value<int>? quantity,
    Value<double>? unitPrice,
  }) {
    return OrderItemsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderItemsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice')
          ..write(')'))
        .toString();
  }
}

class $DiseaseAlertsTable extends DiseaseAlerts
    with TableInfo<$DiseaseAlertsTable, DiseaseAlert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiseaseAlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detectionCountMeta = const VerificationMeta(
    'detectionCount',
  );
  @override
  late final GeneratedColumn<int> detectionCount = GeneratedColumn<int>(
    'detection_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusKmMeta = const VerificationMeta(
    'radiusKm',
  );
  @override
  late final GeneratedColumn<double> radiusKm = GeneratedColumn<double>(
    'radius_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowStartMeta = const VerificationMeta(
    'windowStart',
  );
  @override
  late final GeneratedColumn<DateTime> windowStart = GeneratedColumn<DateTime>(
    'window_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    lat,
    lng,
    detectionCount,
    radiusKm,
    windowStart,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'disease_alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiseaseAlert> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('detection_count')) {
      context.handle(
        _detectionCountMeta,
        detectionCount.isAcceptableOrUnknown(
          data['detection_count']!,
          _detectionCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_detectionCountMeta);
    }
    if (data.containsKey('radius_km')) {
      context.handle(
        _radiusKmMeta,
        radiusKm.isAcceptableOrUnknown(data['radius_km']!, _radiusKmMeta),
      );
    } else if (isInserting) {
      context.missing(_radiusKmMeta);
    }
    if (data.containsKey('window_start')) {
      context.handle(
        _windowStartMeta,
        windowStart.isAcceptableOrUnknown(
          data['window_start']!,
          _windowStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_windowStartMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiseaseAlert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiseaseAlert(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      detectionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}detection_count'],
      )!,
      radiusKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_km'],
      )!,
      windowStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}window_start'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $DiseaseAlertsTable createAlias(String alias) {
    return $DiseaseAlertsTable(attachedDatabase, alias);
  }
}

class DiseaseAlert extends DataClass implements Insertable<DiseaseAlert> {
  final String id;
  final String label;
  final double lat;
  final double lng;
  final int detectionCount;
  final double radiusKm;
  final DateTime windowStart;
  final DateTime fetchedAt;
  const DiseaseAlert({
    required this.id,
    required this.label,
    required this.lat,
    required this.lng,
    required this.detectionCount,
    required this.radiusKm,
    required this.windowStart,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['detection_count'] = Variable<int>(detectionCount);
    map['radius_km'] = Variable<double>(radiusKm);
    map['window_start'] = Variable<DateTime>(windowStart);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  DiseaseAlertsCompanion toCompanion(bool nullToAbsent) {
    return DiseaseAlertsCompanion(
      id: Value(id),
      label: Value(label),
      lat: Value(lat),
      lng: Value(lng),
      detectionCount: Value(detectionCount),
      radiusKm: Value(radiusKm),
      windowStart: Value(windowStart),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory DiseaseAlert.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiseaseAlert(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      detectionCount: serializer.fromJson<int>(json['detectionCount']),
      radiusKm: serializer.fromJson<double>(json['radiusKm']),
      windowStart: serializer.fromJson<DateTime>(json['windowStart']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'detectionCount': serializer.toJson<int>(detectionCount),
      'radiusKm': serializer.toJson<double>(radiusKm),
      'windowStart': serializer.toJson<DateTime>(windowStart),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  DiseaseAlert copyWith({
    String? id,
    String? label,
    double? lat,
    double? lng,
    int? detectionCount,
    double? radiusKm,
    DateTime? windowStart,
    DateTime? fetchedAt,
  }) => DiseaseAlert(
    id: id ?? this.id,
    label: label ?? this.label,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    detectionCount: detectionCount ?? this.detectionCount,
    radiusKm: radiusKm ?? this.radiusKm,
    windowStart: windowStart ?? this.windowStart,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  DiseaseAlert copyWithCompanion(DiseaseAlertsCompanion data) {
    return DiseaseAlert(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      detectionCount: data.detectionCount.present
          ? data.detectionCount.value
          : this.detectionCount,
      radiusKm: data.radiusKm.present ? data.radiusKm.value : this.radiusKm,
      windowStart: data.windowStart.present
          ? data.windowStart.value
          : this.windowStart,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiseaseAlert(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('detectionCount: $detectionCount, ')
          ..write('radiusKm: $radiusKm, ')
          ..write('windowStart: $windowStart, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    lat,
    lng,
    detectionCount,
    radiusKm,
    windowStart,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiseaseAlert &&
          other.id == this.id &&
          other.label == this.label &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.detectionCount == this.detectionCount &&
          other.radiusKm == this.radiusKm &&
          other.windowStart == this.windowStart &&
          other.fetchedAt == this.fetchedAt);
}

class DiseaseAlertsCompanion extends UpdateCompanion<DiseaseAlert> {
  final Value<String> id;
  final Value<String> label;
  final Value<double> lat;
  final Value<double> lng;
  final Value<int> detectionCount;
  final Value<double> radiusKm;
  final Value<DateTime> windowStart;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const DiseaseAlertsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.detectionCount = const Value.absent(),
    this.radiusKm = const Value.absent(),
    this.windowStart = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiseaseAlertsCompanion.insert({
    required String id,
    required String label,
    required double lat,
    required double lng,
    required int detectionCount,
    required double radiusKm,
    required DateTime windowStart,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       lat = Value(lat),
       lng = Value(lng),
       detectionCount = Value(detectionCount),
       radiusKm = Value(radiusKm),
       windowStart = Value(windowStart),
       fetchedAt = Value(fetchedAt);
  static Insertable<DiseaseAlert> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<int>? detectionCount,
    Expression<double>? radiusKm,
    Expression<DateTime>? windowStart,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (detectionCount != null) 'detection_count': detectionCount,
      if (radiusKm != null) 'radius_km': radiusKm,
      if (windowStart != null) 'window_start': windowStart,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiseaseAlertsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<double>? lat,
    Value<double>? lng,
    Value<int>? detectionCount,
    Value<double>? radiusKm,
    Value<DateTime>? windowStart,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return DiseaseAlertsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      detectionCount: detectionCount ?? this.detectionCount,
      radiusKm: radiusKm ?? this.radiusKm,
      windowStart: windowStart ?? this.windowStart,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (detectionCount.present) {
      map['detection_count'] = Variable<int>(detectionCount.value);
    }
    if (radiusKm.present) {
      map['radius_km'] = Variable<double>(radiusKm.value);
    }
    if (windowStart.present) {
      map['window_start'] = Variable<DateTime>(windowStart.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiseaseAlertsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('detectionCount: $detectionCount, ')
          ..write('radiusKm: $radiusKm, ')
          ..write('windowStart: $windowStart, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $P2pPacketsTable extends P2pPackets
    with TableInfo<$P2pPacketsTable, P2pPacket> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $P2pPacketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packetIdMeta = const VerificationMeta(
    'packetId',
  );
  @override
  late final GeneratedColumn<String> packetId = GeneratedColumn<String>(
    'packet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawBytesMeta = const VerificationMeta(
    'rawBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> rawBytes = GeneratedColumn<Uint8List>(
    'raw_bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropIdMeta = const VerificationMeta('cropId');
  @override
  late final GeneratedColumn<String> cropId = GeneratedColumn<String>(
    'crop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observedAtMeta = const VerificationMeta(
    'observedAt',
  );
  @override
  late final GeneratedColumn<DateTime> observedAt = GeneratedColumn<DateTime>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceDeviceIdMeta = const VerificationMeta(
    'sourceDeviceId',
  );
  @override
  late final GeneratedColumn<String> sourceDeviceId = GeneratedColumn<String>(
    'source_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedFromPeerIdMeta =
      const VerificationMeta('receivedFromPeerId');
  @override
  late final GeneratedColumn<String> receivedFromPeerId =
      GeneratedColumn<String>(
        'received_from_peer_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _forwardedToPeerIdsJsonMeta =
      const VerificationMeta('forwardedToPeerIdsJson');
  @override
  late final GeneratedColumn<String> forwardedToPeerIdsJson =
      GeneratedColumn<String>(
        'forwarded_to_peer_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _aggregationGroupIdMeta =
      const VerificationMeta('aggregationGroupId');
  @override
  late final GeneratedColumn<String> aggregationGroupId =
      GeneratedColumn<String>(
        'aggregation_group_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _verifiedMeta = const VerificationMeta(
    'verified',
  );
  @override
  late final GeneratedColumn<bool> verified = GeneratedColumn<bool>(
    'verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedToBackendMeta = const VerificationMeta(
    'syncedToBackend',
  );
  @override
  late final GeneratedColumn<bool> syncedToBackend = GeneratedColumn<bool>(
    'synced_to_backend',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced_to_backend" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    packetId,
    rawBytes,
    type,
    cropId,
    label,
    confidence,
    severity,
    lat,
    lng,
    observedAt,
    expiresAt,
    sourceDeviceId,
    receivedFromPeerId,
    forwardedToPeerIdsJson,
    aggregationGroupId,
    verified,
    syncedToBackend,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'p2p_packets';
  @override
  VerificationContext validateIntegrity(
    Insertable<P2pPacket> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('packet_id')) {
      context.handle(
        _packetIdMeta,
        packetId.isAcceptableOrUnknown(data['packet_id']!, _packetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packetIdMeta);
    }
    if (data.containsKey('raw_bytes')) {
      context.handle(
        _rawBytesMeta,
        rawBytes.isAcceptableOrUnknown(data['raw_bytes']!, _rawBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_rawBytesMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('crop_id')) {
      context.handle(
        _cropIdMeta,
        cropId.isAcceptableOrUnknown(data['crop_id']!, _cropIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cropIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('observed_at')) {
      context.handle(
        _observedAtMeta,
        observedAt.isAcceptableOrUnknown(data['observed_at']!, _observedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_observedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('source_device_id')) {
      context.handle(
        _sourceDeviceIdMeta,
        sourceDeviceId.isAcceptableOrUnknown(
          data['source_device_id']!,
          _sourceDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceDeviceIdMeta);
    }
    if (data.containsKey('received_from_peer_id')) {
      context.handle(
        _receivedFromPeerIdMeta,
        receivedFromPeerId.isAcceptableOrUnknown(
          data['received_from_peer_id']!,
          _receivedFromPeerIdMeta,
        ),
      );
    }
    if (data.containsKey('forwarded_to_peer_ids_json')) {
      context.handle(
        _forwardedToPeerIdsJsonMeta,
        forwardedToPeerIdsJson.isAcceptableOrUnknown(
          data['forwarded_to_peer_ids_json']!,
          _forwardedToPeerIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('aggregation_group_id')) {
      context.handle(
        _aggregationGroupIdMeta,
        aggregationGroupId.isAcceptableOrUnknown(
          data['aggregation_group_id']!,
          _aggregationGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('verified')) {
      context.handle(
        _verifiedMeta,
        verified.isAcceptableOrUnknown(data['verified']!, _verifiedMeta),
      );
    }
    if (data.containsKey('synced_to_backend')) {
      context.handle(
        _syncedToBackendMeta,
        syncedToBackend.isAcceptableOrUnknown(
          data['synced_to_backend']!,
          _syncedToBackendMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packetId};
  @override
  P2pPacket map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return P2pPacket(
      packetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}packet_id'],
      )!,
      rawBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}raw_bytes'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      cropId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}observed_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      sourceDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_device_id'],
      )!,
      receivedFromPeerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}received_from_peer_id'],
      ),
      forwardedToPeerIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}forwarded_to_peer_ids_json'],
      )!,
      aggregationGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggregation_group_id'],
      ),
      verified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}verified'],
      )!,
      syncedToBackend: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced_to_backend'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $P2pPacketsTable createAlias(String alias) {
    return $P2pPacketsTable(attachedDatabase, alias);
  }
}

class P2pPacket extends DataClass implements Insertable<P2pPacket> {
  final String packetId;

  /// Full encoded wire packet (CBOR, signature intact) — needed to forward
  /// this packet on to another peer unchanged. The columns below are a
  /// flattened projection of its payload for querying (relevance filtering,
  /// aggregation) without decoding the blob on every read.
  final Uint8List rawBytes;
  final int type;
  final String cropId;
  final String label;
  final double confidence;
  final String severity;
  final double lat;
  final double lng;
  final DateTime observedAt;
  final DateTime expiresAt;
  final String sourceDeviceId;
  final String? receivedFromPeerId;
  final String forwardedToPeerIdsJson;
  final String? aggregationGroupId;
  final bool verified;
  final bool syncedToBackend;
  final DateTime createdAt;
  const P2pPacket({
    required this.packetId,
    required this.rawBytes,
    required this.type,
    required this.cropId,
    required this.label,
    required this.confidence,
    required this.severity,
    required this.lat,
    required this.lng,
    required this.observedAt,
    required this.expiresAt,
    required this.sourceDeviceId,
    this.receivedFromPeerId,
    required this.forwardedToPeerIdsJson,
    this.aggregationGroupId,
    required this.verified,
    required this.syncedToBackend,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['packet_id'] = Variable<String>(packetId);
    map['raw_bytes'] = Variable<Uint8List>(rawBytes);
    map['type'] = Variable<int>(type);
    map['crop_id'] = Variable<String>(cropId);
    map['label'] = Variable<String>(label);
    map['confidence'] = Variable<double>(confidence);
    map['severity'] = Variable<String>(severity);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['observed_at'] = Variable<DateTime>(observedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['source_device_id'] = Variable<String>(sourceDeviceId);
    if (!nullToAbsent || receivedFromPeerId != null) {
      map['received_from_peer_id'] = Variable<String>(receivedFromPeerId);
    }
    map['forwarded_to_peer_ids_json'] = Variable<String>(
      forwardedToPeerIdsJson,
    );
    if (!nullToAbsent || aggregationGroupId != null) {
      map['aggregation_group_id'] = Variable<String>(aggregationGroupId);
    }
    map['verified'] = Variable<bool>(verified);
    map['synced_to_backend'] = Variable<bool>(syncedToBackend);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  P2pPacketsCompanion toCompanion(bool nullToAbsent) {
    return P2pPacketsCompanion(
      packetId: Value(packetId),
      rawBytes: Value(rawBytes),
      type: Value(type),
      cropId: Value(cropId),
      label: Value(label),
      confidence: Value(confidence),
      severity: Value(severity),
      lat: Value(lat),
      lng: Value(lng),
      observedAt: Value(observedAt),
      expiresAt: Value(expiresAt),
      sourceDeviceId: Value(sourceDeviceId),
      receivedFromPeerId: receivedFromPeerId == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedFromPeerId),
      forwardedToPeerIdsJson: Value(forwardedToPeerIdsJson),
      aggregationGroupId: aggregationGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(aggregationGroupId),
      verified: Value(verified),
      syncedToBackend: Value(syncedToBackend),
      createdAt: Value(createdAt),
    );
  }

  factory P2pPacket.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return P2pPacket(
      packetId: serializer.fromJson<String>(json['packetId']),
      rawBytes: serializer.fromJson<Uint8List>(json['rawBytes']),
      type: serializer.fromJson<int>(json['type']),
      cropId: serializer.fromJson<String>(json['cropId']),
      label: serializer.fromJson<String>(json['label']),
      confidence: serializer.fromJson<double>(json['confidence']),
      severity: serializer.fromJson<String>(json['severity']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      observedAt: serializer.fromJson<DateTime>(json['observedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      sourceDeviceId: serializer.fromJson<String>(json['sourceDeviceId']),
      receivedFromPeerId: serializer.fromJson<String?>(
        json['receivedFromPeerId'],
      ),
      forwardedToPeerIdsJson: serializer.fromJson<String>(
        json['forwardedToPeerIdsJson'],
      ),
      aggregationGroupId: serializer.fromJson<String?>(
        json['aggregationGroupId'],
      ),
      verified: serializer.fromJson<bool>(json['verified']),
      syncedToBackend: serializer.fromJson<bool>(json['syncedToBackend']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packetId': serializer.toJson<String>(packetId),
      'rawBytes': serializer.toJson<Uint8List>(rawBytes),
      'type': serializer.toJson<int>(type),
      'cropId': serializer.toJson<String>(cropId),
      'label': serializer.toJson<String>(label),
      'confidence': serializer.toJson<double>(confidence),
      'severity': serializer.toJson<String>(severity),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'observedAt': serializer.toJson<DateTime>(observedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'sourceDeviceId': serializer.toJson<String>(sourceDeviceId),
      'receivedFromPeerId': serializer.toJson<String?>(receivedFromPeerId),
      'forwardedToPeerIdsJson': serializer.toJson<String>(
        forwardedToPeerIdsJson,
      ),
      'aggregationGroupId': serializer.toJson<String?>(aggregationGroupId),
      'verified': serializer.toJson<bool>(verified),
      'syncedToBackend': serializer.toJson<bool>(syncedToBackend),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  P2pPacket copyWith({
    String? packetId,
    Uint8List? rawBytes,
    int? type,
    String? cropId,
    String? label,
    double? confidence,
    String? severity,
    double? lat,
    double? lng,
    DateTime? observedAt,
    DateTime? expiresAt,
    String? sourceDeviceId,
    Value<String?> receivedFromPeerId = const Value.absent(),
    String? forwardedToPeerIdsJson,
    Value<String?> aggregationGroupId = const Value.absent(),
    bool? verified,
    bool? syncedToBackend,
    DateTime? createdAt,
  }) => P2pPacket(
    packetId: packetId ?? this.packetId,
    rawBytes: rawBytes ?? this.rawBytes,
    type: type ?? this.type,
    cropId: cropId ?? this.cropId,
    label: label ?? this.label,
    confidence: confidence ?? this.confidence,
    severity: severity ?? this.severity,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    observedAt: observedAt ?? this.observedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
    receivedFromPeerId: receivedFromPeerId.present
        ? receivedFromPeerId.value
        : this.receivedFromPeerId,
    forwardedToPeerIdsJson:
        forwardedToPeerIdsJson ?? this.forwardedToPeerIdsJson,
    aggregationGroupId: aggregationGroupId.present
        ? aggregationGroupId.value
        : this.aggregationGroupId,
    verified: verified ?? this.verified,
    syncedToBackend: syncedToBackend ?? this.syncedToBackend,
    createdAt: createdAt ?? this.createdAt,
  );
  P2pPacket copyWithCompanion(P2pPacketsCompanion data) {
    return P2pPacket(
      packetId: data.packetId.present ? data.packetId.value : this.packetId,
      rawBytes: data.rawBytes.present ? data.rawBytes.value : this.rawBytes,
      type: data.type.present ? data.type.value : this.type,
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      label: data.label.present ? data.label.value : this.label,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      severity: data.severity.present ? data.severity.value : this.severity,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      sourceDeviceId: data.sourceDeviceId.present
          ? data.sourceDeviceId.value
          : this.sourceDeviceId,
      receivedFromPeerId: data.receivedFromPeerId.present
          ? data.receivedFromPeerId.value
          : this.receivedFromPeerId,
      forwardedToPeerIdsJson: data.forwardedToPeerIdsJson.present
          ? data.forwardedToPeerIdsJson.value
          : this.forwardedToPeerIdsJson,
      aggregationGroupId: data.aggregationGroupId.present
          ? data.aggregationGroupId.value
          : this.aggregationGroupId,
      verified: data.verified.present ? data.verified.value : this.verified,
      syncedToBackend: data.syncedToBackend.present
          ? data.syncedToBackend.value
          : this.syncedToBackend,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('P2pPacket(')
          ..write('packetId: $packetId, ')
          ..write('rawBytes: $rawBytes, ')
          ..write('type: $type, ')
          ..write('cropId: $cropId, ')
          ..write('label: $label, ')
          ..write('confidence: $confidence, ')
          ..write('severity: $severity, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('observedAt: $observedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('receivedFromPeerId: $receivedFromPeerId, ')
          ..write('forwardedToPeerIdsJson: $forwardedToPeerIdsJson, ')
          ..write('aggregationGroupId: $aggregationGroupId, ')
          ..write('verified: $verified, ')
          ..write('syncedToBackend: $syncedToBackend, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    packetId,
    $driftBlobEquality.hash(rawBytes),
    type,
    cropId,
    label,
    confidence,
    severity,
    lat,
    lng,
    observedAt,
    expiresAt,
    sourceDeviceId,
    receivedFromPeerId,
    forwardedToPeerIdsJson,
    aggregationGroupId,
    verified,
    syncedToBackend,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is P2pPacket &&
          other.packetId == this.packetId &&
          $driftBlobEquality.equals(other.rawBytes, this.rawBytes) &&
          other.type == this.type &&
          other.cropId == this.cropId &&
          other.label == this.label &&
          other.confidence == this.confidence &&
          other.severity == this.severity &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.observedAt == this.observedAt &&
          other.expiresAt == this.expiresAt &&
          other.sourceDeviceId == this.sourceDeviceId &&
          other.receivedFromPeerId == this.receivedFromPeerId &&
          other.forwardedToPeerIdsJson == this.forwardedToPeerIdsJson &&
          other.aggregationGroupId == this.aggregationGroupId &&
          other.verified == this.verified &&
          other.syncedToBackend == this.syncedToBackend &&
          other.createdAt == this.createdAt);
}

class P2pPacketsCompanion extends UpdateCompanion<P2pPacket> {
  final Value<String> packetId;
  final Value<Uint8List> rawBytes;
  final Value<int> type;
  final Value<String> cropId;
  final Value<String> label;
  final Value<double> confidence;
  final Value<String> severity;
  final Value<double> lat;
  final Value<double> lng;
  final Value<DateTime> observedAt;
  final Value<DateTime> expiresAt;
  final Value<String> sourceDeviceId;
  final Value<String?> receivedFromPeerId;
  final Value<String> forwardedToPeerIdsJson;
  final Value<String?> aggregationGroupId;
  final Value<bool> verified;
  final Value<bool> syncedToBackend;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const P2pPacketsCompanion({
    this.packetId = const Value.absent(),
    this.rawBytes = const Value.absent(),
    this.type = const Value.absent(),
    this.cropId = const Value.absent(),
    this.label = const Value.absent(),
    this.confidence = const Value.absent(),
    this.severity = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.sourceDeviceId = const Value.absent(),
    this.receivedFromPeerId = const Value.absent(),
    this.forwardedToPeerIdsJson = const Value.absent(),
    this.aggregationGroupId = const Value.absent(),
    this.verified = const Value.absent(),
    this.syncedToBackend = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  P2pPacketsCompanion.insert({
    required String packetId,
    required Uint8List rawBytes,
    required int type,
    required String cropId,
    required String label,
    required double confidence,
    required String severity,
    required double lat,
    required double lng,
    required DateTime observedAt,
    required DateTime expiresAt,
    required String sourceDeviceId,
    this.receivedFromPeerId = const Value.absent(),
    this.forwardedToPeerIdsJson = const Value.absent(),
    this.aggregationGroupId = const Value.absent(),
    this.verified = const Value.absent(),
    this.syncedToBackend = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : packetId = Value(packetId),
       rawBytes = Value(rawBytes),
       type = Value(type),
       cropId = Value(cropId),
       label = Value(label),
       confidence = Value(confidence),
       severity = Value(severity),
       lat = Value(lat),
       lng = Value(lng),
       observedAt = Value(observedAt),
       expiresAt = Value(expiresAt),
       sourceDeviceId = Value(sourceDeviceId),
       createdAt = Value(createdAt);
  static Insertable<P2pPacket> custom({
    Expression<String>? packetId,
    Expression<Uint8List>? rawBytes,
    Expression<int>? type,
    Expression<String>? cropId,
    Expression<String>? label,
    Expression<double>? confidence,
    Expression<String>? severity,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<DateTime>? observedAt,
    Expression<DateTime>? expiresAt,
    Expression<String>? sourceDeviceId,
    Expression<String>? receivedFromPeerId,
    Expression<String>? forwardedToPeerIdsJson,
    Expression<String>? aggregationGroupId,
    Expression<bool>? verified,
    Expression<bool>? syncedToBackend,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packetId != null) 'packet_id': packetId,
      if (rawBytes != null) 'raw_bytes': rawBytes,
      if (type != null) 'type': type,
      if (cropId != null) 'crop_id': cropId,
      if (label != null) 'label': label,
      if (confidence != null) 'confidence': confidence,
      if (severity != null) 'severity': severity,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (observedAt != null) 'observed_at': observedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (sourceDeviceId != null) 'source_device_id': sourceDeviceId,
      if (receivedFromPeerId != null)
        'received_from_peer_id': receivedFromPeerId,
      if (forwardedToPeerIdsJson != null)
        'forwarded_to_peer_ids_json': forwardedToPeerIdsJson,
      if (aggregationGroupId != null)
        'aggregation_group_id': aggregationGroupId,
      if (verified != null) 'verified': verified,
      if (syncedToBackend != null) 'synced_to_backend': syncedToBackend,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  P2pPacketsCompanion copyWith({
    Value<String>? packetId,
    Value<Uint8List>? rawBytes,
    Value<int>? type,
    Value<String>? cropId,
    Value<String>? label,
    Value<double>? confidence,
    Value<String>? severity,
    Value<double>? lat,
    Value<double>? lng,
    Value<DateTime>? observedAt,
    Value<DateTime>? expiresAt,
    Value<String>? sourceDeviceId,
    Value<String?>? receivedFromPeerId,
    Value<String>? forwardedToPeerIdsJson,
    Value<String?>? aggregationGroupId,
    Value<bool>? verified,
    Value<bool>? syncedToBackend,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return P2pPacketsCompanion(
      packetId: packetId ?? this.packetId,
      rawBytes: rawBytes ?? this.rawBytes,
      type: type ?? this.type,
      cropId: cropId ?? this.cropId,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      observedAt: observedAt ?? this.observedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      receivedFromPeerId: receivedFromPeerId ?? this.receivedFromPeerId,
      forwardedToPeerIdsJson:
          forwardedToPeerIdsJson ?? this.forwardedToPeerIdsJson,
      aggregationGroupId: aggregationGroupId ?? this.aggregationGroupId,
      verified: verified ?? this.verified,
      syncedToBackend: syncedToBackend ?? this.syncedToBackend,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packetId.present) {
      map['packet_id'] = Variable<String>(packetId.value);
    }
    if (rawBytes.present) {
      map['raw_bytes'] = Variable<Uint8List>(rawBytes.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (cropId.present) {
      map['crop_id'] = Variable<String>(cropId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<DateTime>(observedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (sourceDeviceId.present) {
      map['source_device_id'] = Variable<String>(sourceDeviceId.value);
    }
    if (receivedFromPeerId.present) {
      map['received_from_peer_id'] = Variable<String>(receivedFromPeerId.value);
    }
    if (forwardedToPeerIdsJson.present) {
      map['forwarded_to_peer_ids_json'] = Variable<String>(
        forwardedToPeerIdsJson.value,
      );
    }
    if (aggregationGroupId.present) {
      map['aggregation_group_id'] = Variable<String>(aggregationGroupId.value);
    }
    if (verified.present) {
      map['verified'] = Variable<bool>(verified.value);
    }
    if (syncedToBackend.present) {
      map['synced_to_backend'] = Variable<bool>(syncedToBackend.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('P2pPacketsCompanion(')
          ..write('packetId: $packetId, ')
          ..write('rawBytes: $rawBytes, ')
          ..write('type: $type, ')
          ..write('cropId: $cropId, ')
          ..write('label: $label, ')
          ..write('confidence: $confidence, ')
          ..write('severity: $severity, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('observedAt: $observedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('receivedFromPeerId: $receivedFromPeerId, ')
          ..write('forwardedToPeerIdsJson: $forwardedToPeerIdsJson, ')
          ..write('aggregationGroupId: $aggregationGroupId, ')
          ..write('verified: $verified, ')
          ..write('syncedToBackend: $syncedToBackend, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $P2pAggregatedAlertsTable extends P2pAggregatedAlerts
    with TableInfo<$P2pAggregatedAlertsTable, P2pAggregatedAlert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $P2pAggregatedAlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropIdMeta = const VerificationMeta('cropId');
  @override
  late final GeneratedColumn<String> cropId = GeneratedColumn<String>(
    'crop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detectionCountMeta = const VerificationMeta(
    'detectionCount',
  );
  @override
  late final GeneratedColumn<int> detectionCount = GeneratedColumn<int>(
    'detection_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusKmMeta = const VerificationMeta(
    'radiusKm',
  );
  @override
  late final GeneratedColumn<double> radiusKm = GeneratedColumn<double>(
    'radius_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowStartMeta = const VerificationMeta(
    'windowStart',
  );
  @override
  late final GeneratedColumn<DateTime> windowStart = GeneratedColumn<DateTime>(
    'window_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    cropId,
    lat,
    lng,
    detectionCount,
    radiusKm,
    windowStart,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'p2p_aggregated_alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<P2pAggregatedAlert> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('crop_id')) {
      context.handle(
        _cropIdMeta,
        cropId.isAcceptableOrUnknown(data['crop_id']!, _cropIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cropIdMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('detection_count')) {
      context.handle(
        _detectionCountMeta,
        detectionCount.isAcceptableOrUnknown(
          data['detection_count']!,
          _detectionCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_detectionCountMeta);
    }
    if (data.containsKey('radius_km')) {
      context.handle(
        _radiusKmMeta,
        radiusKm.isAcceptableOrUnknown(data['radius_km']!, _radiusKmMeta),
      );
    } else if (isInserting) {
      context.missing(_radiusKmMeta);
    }
    if (data.containsKey('window_start')) {
      context.handle(
        _windowStartMeta,
        windowStart.isAcceptableOrUnknown(
          data['window_start']!,
          _windowStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_windowStartMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  P2pAggregatedAlert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return P2pAggregatedAlert(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      cropId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      detectionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}detection_count'],
      )!,
      radiusKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_km'],
      )!,
      windowStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}window_start'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $P2pAggregatedAlertsTable createAlias(String alias) {
    return $P2pAggregatedAlertsTable(attachedDatabase, alias);
  }
}

class P2pAggregatedAlert extends DataClass
    implements Insertable<P2pAggregatedAlert> {
  final String id;
  final String label;
  final String cropId;
  final double lat;
  final double lng;
  final int detectionCount;
  final double radiusKm;
  final DateTime windowStart;
  final DateTime fetchedAt;
  const P2pAggregatedAlert({
    required this.id,
    required this.label,
    required this.cropId,
    required this.lat,
    required this.lng,
    required this.detectionCount,
    required this.radiusKm,
    required this.windowStart,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['crop_id'] = Variable<String>(cropId);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['detection_count'] = Variable<int>(detectionCount);
    map['radius_km'] = Variable<double>(radiusKm);
    map['window_start'] = Variable<DateTime>(windowStart);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  P2pAggregatedAlertsCompanion toCompanion(bool nullToAbsent) {
    return P2pAggregatedAlertsCompanion(
      id: Value(id),
      label: Value(label),
      cropId: Value(cropId),
      lat: Value(lat),
      lng: Value(lng),
      detectionCount: Value(detectionCount),
      radiusKm: Value(radiusKm),
      windowStart: Value(windowStart),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory P2pAggregatedAlert.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return P2pAggregatedAlert(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      cropId: serializer.fromJson<String>(json['cropId']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      detectionCount: serializer.fromJson<int>(json['detectionCount']),
      radiusKm: serializer.fromJson<double>(json['radiusKm']),
      windowStart: serializer.fromJson<DateTime>(json['windowStart']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'cropId': serializer.toJson<String>(cropId),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'detectionCount': serializer.toJson<int>(detectionCount),
      'radiusKm': serializer.toJson<double>(radiusKm),
      'windowStart': serializer.toJson<DateTime>(windowStart),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  P2pAggregatedAlert copyWith({
    String? id,
    String? label,
    String? cropId,
    double? lat,
    double? lng,
    int? detectionCount,
    double? radiusKm,
    DateTime? windowStart,
    DateTime? fetchedAt,
  }) => P2pAggregatedAlert(
    id: id ?? this.id,
    label: label ?? this.label,
    cropId: cropId ?? this.cropId,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    detectionCount: detectionCount ?? this.detectionCount,
    radiusKm: radiusKm ?? this.radiusKm,
    windowStart: windowStart ?? this.windowStart,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  P2pAggregatedAlert copyWithCompanion(P2pAggregatedAlertsCompanion data) {
    return P2pAggregatedAlert(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      detectionCount: data.detectionCount.present
          ? data.detectionCount.value
          : this.detectionCount,
      radiusKm: data.radiusKm.present ? data.radiusKm.value : this.radiusKm,
      windowStart: data.windowStart.present
          ? data.windowStart.value
          : this.windowStart,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('P2pAggregatedAlert(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('cropId: $cropId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('detectionCount: $detectionCount, ')
          ..write('radiusKm: $radiusKm, ')
          ..write('windowStart: $windowStart, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    cropId,
    lat,
    lng,
    detectionCount,
    radiusKm,
    windowStart,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is P2pAggregatedAlert &&
          other.id == this.id &&
          other.label == this.label &&
          other.cropId == this.cropId &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.detectionCount == this.detectionCount &&
          other.radiusKm == this.radiusKm &&
          other.windowStart == this.windowStart &&
          other.fetchedAt == this.fetchedAt);
}

class P2pAggregatedAlertsCompanion extends UpdateCompanion<P2pAggregatedAlert> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> cropId;
  final Value<double> lat;
  final Value<double> lng;
  final Value<int> detectionCount;
  final Value<double> radiusKm;
  final Value<DateTime> windowStart;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const P2pAggregatedAlertsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.cropId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.detectionCount = const Value.absent(),
    this.radiusKm = const Value.absent(),
    this.windowStart = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  P2pAggregatedAlertsCompanion.insert({
    required String id,
    required String label,
    required String cropId,
    required double lat,
    required double lng,
    required int detectionCount,
    required double radiusKm,
    required DateTime windowStart,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       cropId = Value(cropId),
       lat = Value(lat),
       lng = Value(lng),
       detectionCount = Value(detectionCount),
       radiusKm = Value(radiusKm),
       windowStart = Value(windowStart),
       fetchedAt = Value(fetchedAt);
  static Insertable<P2pAggregatedAlert> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? cropId,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<int>? detectionCount,
    Expression<double>? radiusKm,
    Expression<DateTime>? windowStart,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (cropId != null) 'crop_id': cropId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (detectionCount != null) 'detection_count': detectionCount,
      if (radiusKm != null) 'radius_km': radiusKm,
      if (windowStart != null) 'window_start': windowStart,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  P2pAggregatedAlertsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? cropId,
    Value<double>? lat,
    Value<double>? lng,
    Value<int>? detectionCount,
    Value<double>? radiusKm,
    Value<DateTime>? windowStart,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return P2pAggregatedAlertsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      cropId: cropId ?? this.cropId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      detectionCount: detectionCount ?? this.detectionCount,
      radiusKm: radiusKm ?? this.radiusKm,
      windowStart: windowStart ?? this.windowStart,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (cropId.present) {
      map['crop_id'] = Variable<String>(cropId.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (detectionCount.present) {
      map['detection_count'] = Variable<int>(detectionCount.value);
    }
    if (radiusKm.present) {
      map['radius_km'] = Variable<double>(radiusKm.value);
    }
    if (windowStart.present) {
      map['window_start'] = Variable<DateTime>(windowStart.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('P2pAggregatedAlertsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('cropId: $cropId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('detectionCount: $detectionCount, ')
          ..write('radiusKm: $radiusKm, ')
          ..write('windowStart: $windowStart, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueItemsTable extends SyncQueueItems
    with TableInfo<$SyncQueueItemsTable, SyncQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    refId,
    createdAt,
    attempts,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    } else if (isInserting) {
      context.missing(_refIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $SyncQueueItemsTable createAlias(String alias) {
    return $SyncQueueItemsTable(attachedDatabase, alias);
  }
}

class SyncQueueItem extends DataClass implements Insertable<SyncQueueItem> {
  final int id;
  final String type;
  final String refId;
  final DateTime createdAt;
  final int attempts;
  final String status;
  const SyncQueueItem({
    required this.id,
    required this.type,
    required this.refId,
    required this.createdAt,
    required this.attempts,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['ref_id'] = Variable<String>(refId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    map['status'] = Variable<String>(status);
    return map;
  }

  SyncQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueItemsCompanion(
      id: Value(id),
      type: Value(type),
      refId: Value(refId),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      status: Value(status),
    );
  }

  factory SyncQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueItem(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      refId: serializer.fromJson<String>(json['refId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'refId': serializer.toJson<String>(refId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'status': serializer.toJson<String>(status),
    };
  }

  SyncQueueItem copyWith({
    int? id,
    String? type,
    String? refId,
    DateTime? createdAt,
    int? attempts,
    String? status,
  }) => SyncQueueItem(
    id: id ?? this.id,
    type: type ?? this.type,
    refId: refId ?? this.refId,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    status: status ?? this.status,
  );
  SyncQueueItem copyWithCompanion(SyncQueueItemsCompanion data) {
    return SyncQueueItem(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      refId: data.refId.present ? data.refId.value : this.refId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItem(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('refId: $refId, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, refId, createdAt, attempts, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueItem &&
          other.id == this.id &&
          other.type == this.type &&
          other.refId == this.refId &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.status == this.status);
}

class SyncQueueItemsCompanion extends UpdateCompanion<SyncQueueItem> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> refId;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<String> status;
  const SyncQueueItemsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.refId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.status = const Value.absent(),
  });
  SyncQueueItemsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String refId,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.status = const Value.absent(),
  }) : type = Value(type),
       refId = Value(refId),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueItem> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? refId,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (refId != null) 'ref_id': refId,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (status != null) 'status': status,
    });
  }

  SyncQueueItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? refId,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<String>? status,
  }) {
    return SyncQueueItemsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      refId: refId ?? this.refId,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItemsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('refId: $refId, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [domain, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {domain};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String domain;
  final DateTime? lastSyncedAt;
  const SyncMetaData({required this.domain, this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['domain'] = Variable<String>(domain);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      domain: Value(domain),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory SyncMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      domain: serializer.fromJson<String>(json['domain']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'domain': serializer.toJson<String>(domain),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  SyncMetaData copyWith({
    String? domain,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => SyncMetaData(
    domain: domain ?? this.domain,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      domain: data.domain.present ? data.domain.value : this.domain,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('domain: $domain, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(domain, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.domain == this.domain &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> domain;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.domain = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String domain,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : domain = Value(domain);
  static Insertable<SyncMetaData> custom({
    Expression<String>? domain,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (domain != null) 'domain': domain,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? domain,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      domain: domain ?? this.domain,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('domain: $domain, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MarketPricesTable marketPrices = $MarketPricesTable(this);
  late final $MspRatesTable mspRates = $MspRatesTable(this);
  late final $SoilReportsTable soilReports = $SoilReportsTable(this);
  late final $CropRecommendationsTable cropRecommendations =
      $CropRecommendationsTable(this);
  late final $DiseaseDetectionsTable diseaseDetections =
      $DiseaseDetectionsTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderItemsTable orderItems = $OrderItemsTable(this);
  late final $DiseaseAlertsTable diseaseAlerts = $DiseaseAlertsTable(this);
  late final $P2pPacketsTable p2pPackets = $P2pPacketsTable(this);
  late final $P2pAggregatedAlertsTable p2pAggregatedAlerts =
      $P2pAggregatedAlertsTable(this);
  late final $SyncQueueItemsTable syncQueueItems = $SyncQueueItemsTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    marketPrices,
    mspRates,
    soilReports,
    cropRecommendations,
    diseaseDetections,
    products,
    orders,
    orderItems,
    diseaseAlerts,
    p2pPackets,
    p2pAggregatedAlerts,
    syncQueueItems,
    syncMeta,
  ];
}

typedef $$MarketPricesTableCreateCompanionBuilder =
    MarketPricesCompanion Function({
      Value<int> id,
      required String commodity,
      required String mandi,
      required double pricePerQuintal,
      required DateTime priceDate,
      required DateTime fetchedAt,
    });
typedef $$MarketPricesTableUpdateCompanionBuilder =
    MarketPricesCompanion Function({
      Value<int> id,
      Value<String> commodity,
      Value<String> mandi,
      Value<double> pricePerQuintal,
      Value<DateTime> priceDate,
      Value<DateTime> fetchedAt,
    });

class $$MarketPricesTableFilterComposer
    extends Composer<_$AppDatabase, $MarketPricesTable> {
  $$MarketPricesTableFilterComposer({
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

  ColumnFilters<String> get commodity => $composableBuilder(
    column: $table.commodity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mandi => $composableBuilder(
    column: $table.mandi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerQuintal => $composableBuilder(
    column: $table.pricePerQuintal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get priceDate => $composableBuilder(
    column: $table.priceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MarketPricesTableOrderingComposer
    extends Composer<_$AppDatabase, $MarketPricesTable> {
  $$MarketPricesTableOrderingComposer({
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

  ColumnOrderings<String> get commodity => $composableBuilder(
    column: $table.commodity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mandi => $composableBuilder(
    column: $table.mandi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerQuintal => $composableBuilder(
    column: $table.pricePerQuintal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get priceDate => $composableBuilder(
    column: $table.priceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MarketPricesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MarketPricesTable> {
  $$MarketPricesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get commodity =>
      $composableBuilder(column: $table.commodity, builder: (column) => column);

  GeneratedColumn<String> get mandi =>
      $composableBuilder(column: $table.mandi, builder: (column) => column);

  GeneratedColumn<double> get pricePerQuintal => $composableBuilder(
    column: $table.pricePerQuintal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get priceDate =>
      $composableBuilder(column: $table.priceDate, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$MarketPricesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MarketPricesTable,
          MarketPrice,
          $$MarketPricesTableFilterComposer,
          $$MarketPricesTableOrderingComposer,
          $$MarketPricesTableAnnotationComposer,
          $$MarketPricesTableCreateCompanionBuilder,
          $$MarketPricesTableUpdateCompanionBuilder,
          (
            MarketPrice,
            BaseReferences<_$AppDatabase, $MarketPricesTable, MarketPrice>,
          ),
          MarketPrice,
          PrefetchHooks Function()
        > {
  $$MarketPricesTableTableManager(_$AppDatabase db, $MarketPricesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MarketPricesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MarketPricesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MarketPricesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> commodity = const Value.absent(),
                Value<String> mandi = const Value.absent(),
                Value<double> pricePerQuintal = const Value.absent(),
                Value<DateTime> priceDate = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => MarketPricesCompanion(
                id: id,
                commodity: commodity,
                mandi: mandi,
                pricePerQuintal: pricePerQuintal,
                priceDate: priceDate,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String commodity,
                required String mandi,
                required double pricePerQuintal,
                required DateTime priceDate,
                required DateTime fetchedAt,
              }) => MarketPricesCompanion.insert(
                id: id,
                commodity: commodity,
                mandi: mandi,
                pricePerQuintal: pricePerQuintal,
                priceDate: priceDate,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MarketPricesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MarketPricesTable,
      MarketPrice,
      $$MarketPricesTableFilterComposer,
      $$MarketPricesTableOrderingComposer,
      $$MarketPricesTableAnnotationComposer,
      $$MarketPricesTableCreateCompanionBuilder,
      $$MarketPricesTableUpdateCompanionBuilder,
      (
        MarketPrice,
        BaseReferences<_$AppDatabase, $MarketPricesTable, MarketPrice>,
      ),
      MarketPrice,
      PrefetchHooks Function()
    >;
typedef $$MspRatesTableCreateCompanionBuilder =
    MspRatesCompanion Function({
      Value<int> id,
      required String crop,
      required String season,
      required int year,
      required double pricePerQuintal,
      required DateTime fetchedAt,
    });
typedef $$MspRatesTableUpdateCompanionBuilder =
    MspRatesCompanion Function({
      Value<int> id,
      Value<String> crop,
      Value<String> season,
      Value<int> year,
      Value<double> pricePerQuintal,
      Value<DateTime> fetchedAt,
    });

class $$MspRatesTableFilterComposer
    extends Composer<_$AppDatabase, $MspRatesTable> {
  $$MspRatesTableFilterComposer({
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

  ColumnFilters<String> get crop => $composableBuilder(
    column: $table.crop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerQuintal => $composableBuilder(
    column: $table.pricePerQuintal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MspRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $MspRatesTable> {
  $$MspRatesTableOrderingComposer({
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

  ColumnOrderings<String> get crop => $composableBuilder(
    column: $table.crop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerQuintal => $composableBuilder(
    column: $table.pricePerQuintal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MspRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MspRatesTable> {
  $$MspRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get crop =>
      $composableBuilder(column: $table.crop, builder: (column) => column);

  GeneratedColumn<String> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<double> get pricePerQuintal => $composableBuilder(
    column: $table.pricePerQuintal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$MspRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MspRatesTable,
          MspRate,
          $$MspRatesTableFilterComposer,
          $$MspRatesTableOrderingComposer,
          $$MspRatesTableAnnotationComposer,
          $$MspRatesTableCreateCompanionBuilder,
          $$MspRatesTableUpdateCompanionBuilder,
          (MspRate, BaseReferences<_$AppDatabase, $MspRatesTable, MspRate>),
          MspRate,
          PrefetchHooks Function()
        > {
  $$MspRatesTableTableManager(_$AppDatabase db, $MspRatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MspRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MspRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MspRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> crop = const Value.absent(),
                Value<String> season = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<double> pricePerQuintal = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => MspRatesCompanion(
                id: id,
                crop: crop,
                season: season,
                year: year,
                pricePerQuintal: pricePerQuintal,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String crop,
                required String season,
                required int year,
                required double pricePerQuintal,
                required DateTime fetchedAt,
              }) => MspRatesCompanion.insert(
                id: id,
                crop: crop,
                season: season,
                year: year,
                pricePerQuintal: pricePerQuintal,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MspRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MspRatesTable,
      MspRate,
      $$MspRatesTableFilterComposer,
      $$MspRatesTableOrderingComposer,
      $$MspRatesTableAnnotationComposer,
      $$MspRatesTableCreateCompanionBuilder,
      $$MspRatesTableUpdateCompanionBuilder,
      (MspRate, BaseReferences<_$AppDatabase, $MspRatesTable, MspRate>),
      MspRate,
      PrefetchHooks Function()
    >;
typedef $$SoilReportsTableCreateCompanionBuilder =
    SoilReportsCompanion Function({
      required String id,
      required double nitrogen,
      required double phosphorus,
      required double potassium,
      required double ph,
      required double organicCarbon,
      Value<double> rainfallMm,
      Value<double> temperatureC,
      Value<double> humidityPct,
      required DateTime createdAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$SoilReportsTableUpdateCompanionBuilder =
    SoilReportsCompanion Function({
      Value<String> id,
      Value<double> nitrogen,
      Value<double> phosphorus,
      Value<double> potassium,
      Value<double> ph,
      Value<double> organicCarbon,
      Value<double> rainfallMm,
      Value<double> temperatureC,
      Value<double> humidityPct,
      Value<DateTime> createdAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$SoilReportsTableFilterComposer
    extends Composer<_$AppDatabase, $SoilReportsTable> {
  $$SoilReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get nitrogen => $composableBuilder(
    column: $table.nitrogen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get phosphorus => $composableBuilder(
    column: $table.phosphorus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potassium => $composableBuilder(
    column: $table.potassium,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get organicCarbon => $composableBuilder(
    column: $table.organicCarbon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rainfallMm => $composableBuilder(
    column: $table.rainfallMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get humidityPct => $composableBuilder(
    column: $table.humidityPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SoilReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $SoilReportsTable> {
  $$SoilReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get nitrogen => $composableBuilder(
    column: $table.nitrogen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get phosphorus => $composableBuilder(
    column: $table.phosphorus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potassium => $composableBuilder(
    column: $table.potassium,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get organicCarbon => $composableBuilder(
    column: $table.organicCarbon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rainfallMm => $composableBuilder(
    column: $table.rainfallMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get humidityPct => $composableBuilder(
    column: $table.humidityPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SoilReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SoilReportsTable> {
  $$SoilReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get nitrogen =>
      $composableBuilder(column: $table.nitrogen, builder: (column) => column);

  GeneratedColumn<double> get phosphorus => $composableBuilder(
    column: $table.phosphorus,
    builder: (column) => column,
  );

  GeneratedColumn<double> get potassium =>
      $composableBuilder(column: $table.potassium, builder: (column) => column);

  GeneratedColumn<double> get ph =>
      $composableBuilder(column: $table.ph, builder: (column) => column);

  GeneratedColumn<double> get organicCarbon => $composableBuilder(
    column: $table.organicCarbon,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rainfallMm => $composableBuilder(
    column: $table.rainfallMm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => column,
  );

  GeneratedColumn<double> get humidityPct => $composableBuilder(
    column: $table.humidityPct,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$SoilReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SoilReportsTable,
          SoilReport,
          $$SoilReportsTableFilterComposer,
          $$SoilReportsTableOrderingComposer,
          $$SoilReportsTableAnnotationComposer,
          $$SoilReportsTableCreateCompanionBuilder,
          $$SoilReportsTableUpdateCompanionBuilder,
          (
            SoilReport,
            BaseReferences<_$AppDatabase, $SoilReportsTable, SoilReport>,
          ),
          SoilReport,
          PrefetchHooks Function()
        > {
  $$SoilReportsTableTableManager(_$AppDatabase db, $SoilReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SoilReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SoilReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SoilReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double> nitrogen = const Value.absent(),
                Value<double> phosphorus = const Value.absent(),
                Value<double> potassium = const Value.absent(),
                Value<double> ph = const Value.absent(),
                Value<double> organicCarbon = const Value.absent(),
                Value<double> rainfallMm = const Value.absent(),
                Value<double> temperatureC = const Value.absent(),
                Value<double> humidityPct = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SoilReportsCompanion(
                id: id,
                nitrogen: nitrogen,
                phosphorus: phosphorus,
                potassium: potassium,
                ph: ph,
                organicCarbon: organicCarbon,
                rainfallMm: rainfallMm,
                temperatureC: temperatureC,
                humidityPct: humidityPct,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required double nitrogen,
                required double phosphorus,
                required double potassium,
                required double ph,
                required double organicCarbon,
                Value<double> rainfallMm = const Value.absent(),
                Value<double> temperatureC = const Value.absent(),
                Value<double> humidityPct = const Value.absent(),
                required DateTime createdAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SoilReportsCompanion.insert(
                id: id,
                nitrogen: nitrogen,
                phosphorus: phosphorus,
                potassium: potassium,
                ph: ph,
                organicCarbon: organicCarbon,
                rainfallMm: rainfallMm,
                temperatureC: temperatureC,
                humidityPct: humidityPct,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SoilReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SoilReportsTable,
      SoilReport,
      $$SoilReportsTableFilterComposer,
      $$SoilReportsTableOrderingComposer,
      $$SoilReportsTableAnnotationComposer,
      $$SoilReportsTableCreateCompanionBuilder,
      $$SoilReportsTableUpdateCompanionBuilder,
      (
        SoilReport,
        BaseReferences<_$AppDatabase, $SoilReportsTable, SoilReport>,
      ),
      SoilReport,
      PrefetchHooks Function()
    >;
typedef $$CropRecommendationsTableCreateCompanionBuilder =
    CropRecommendationsCompanion Function({
      Value<int> id,
      required String soilReportId,
      required String cropName,
      required int rankPosition,
      required double suitabilityScore,
      Value<String> nutrientAdviceJson,
      required DateTime cachedAt,
    });
typedef $$CropRecommendationsTableUpdateCompanionBuilder =
    CropRecommendationsCompanion Function({
      Value<int> id,
      Value<String> soilReportId,
      Value<String> cropName,
      Value<int> rankPosition,
      Value<double> suitabilityScore,
      Value<String> nutrientAdviceJson,
      Value<DateTime> cachedAt,
    });

class $$CropRecommendationsTableFilterComposer
    extends Composer<_$AppDatabase, $CropRecommendationsTable> {
  $$CropRecommendationsTableFilterComposer({
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

  ColumnFilters<String> get soilReportId => $composableBuilder(
    column: $table.soilReportId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropName => $composableBuilder(
    column: $table.cropName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rankPosition => $composableBuilder(
    column: $table.rankPosition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get suitabilityScore => $composableBuilder(
    column: $table.suitabilityScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nutrientAdviceJson => $composableBuilder(
    column: $table.nutrientAdviceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CropRecommendationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CropRecommendationsTable> {
  $$CropRecommendationsTableOrderingComposer({
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

  ColumnOrderings<String> get soilReportId => $composableBuilder(
    column: $table.soilReportId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropName => $composableBuilder(
    column: $table.cropName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rankPosition => $composableBuilder(
    column: $table.rankPosition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get suitabilityScore => $composableBuilder(
    column: $table.suitabilityScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nutrientAdviceJson => $composableBuilder(
    column: $table.nutrientAdviceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CropRecommendationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CropRecommendationsTable> {
  $$CropRecommendationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get soilReportId => $composableBuilder(
    column: $table.soilReportId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cropName =>
      $composableBuilder(column: $table.cropName, builder: (column) => column);

  GeneratedColumn<int> get rankPosition => $composableBuilder(
    column: $table.rankPosition,
    builder: (column) => column,
  );

  GeneratedColumn<double> get suitabilityScore => $composableBuilder(
    column: $table.suitabilityScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nutrientAdviceJson => $composableBuilder(
    column: $table.nutrientAdviceJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CropRecommendationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CropRecommendationsTable,
          CropRecommendation,
          $$CropRecommendationsTableFilterComposer,
          $$CropRecommendationsTableOrderingComposer,
          $$CropRecommendationsTableAnnotationComposer,
          $$CropRecommendationsTableCreateCompanionBuilder,
          $$CropRecommendationsTableUpdateCompanionBuilder,
          (
            CropRecommendation,
            BaseReferences<
              _$AppDatabase,
              $CropRecommendationsTable,
              CropRecommendation
            >,
          ),
          CropRecommendation,
          PrefetchHooks Function()
        > {
  $$CropRecommendationsTableTableManager(
    _$AppDatabase db,
    $CropRecommendationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CropRecommendationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CropRecommendationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CropRecommendationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> soilReportId = const Value.absent(),
                Value<String> cropName = const Value.absent(),
                Value<int> rankPosition = const Value.absent(),
                Value<double> suitabilityScore = const Value.absent(),
                Value<String> nutrientAdviceJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CropRecommendationsCompanion(
                id: id,
                soilReportId: soilReportId,
                cropName: cropName,
                rankPosition: rankPosition,
                suitabilityScore: suitabilityScore,
                nutrientAdviceJson: nutrientAdviceJson,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String soilReportId,
                required String cropName,
                required int rankPosition,
                required double suitabilityScore,
                Value<String> nutrientAdviceJson = const Value.absent(),
                required DateTime cachedAt,
              }) => CropRecommendationsCompanion.insert(
                id: id,
                soilReportId: soilReportId,
                cropName: cropName,
                rankPosition: rankPosition,
                suitabilityScore: suitabilityScore,
                nutrientAdviceJson: nutrientAdviceJson,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CropRecommendationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CropRecommendationsTable,
      CropRecommendation,
      $$CropRecommendationsTableFilterComposer,
      $$CropRecommendationsTableOrderingComposer,
      $$CropRecommendationsTableAnnotationComposer,
      $$CropRecommendationsTableCreateCompanionBuilder,
      $$CropRecommendationsTableUpdateCompanionBuilder,
      (
        CropRecommendation,
        BaseReferences<
          _$AppDatabase,
          $CropRecommendationsTable,
          CropRecommendation
        >,
      ),
      CropRecommendation,
      PrefetchHooks Function()
    >;
typedef $$DiseaseDetectionsTableCreateCompanionBuilder =
    DiseaseDetectionsCompanion Function({
      required String id,
      Value<String> cropId,
      required String label,
      required double confidence,
      Value<String?> imagePath,
      Value<double?> lat,
      Value<double?> lng,
      Value<bool> consentShared,
      Value<bool> isMock,
      required DateTime createdAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$DiseaseDetectionsTableUpdateCompanionBuilder =
    DiseaseDetectionsCompanion Function({
      Value<String> id,
      Value<String> cropId,
      Value<String> label,
      Value<double> confidence,
      Value<String?> imagePath,
      Value<double?> lat,
      Value<double?> lng,
      Value<bool> consentShared,
      Value<bool> isMock,
      Value<DateTime> createdAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$DiseaseDetectionsTableFilterComposer
    extends Composer<_$AppDatabase, $DiseaseDetectionsTable> {
  $$DiseaseDetectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropId => $composableBuilder(
    column: $table.cropId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consentShared => $composableBuilder(
    column: $table.consentShared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMock => $composableBuilder(
    column: $table.isMock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DiseaseDetectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DiseaseDetectionsTable> {
  $$DiseaseDetectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropId => $composableBuilder(
    column: $table.cropId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consentShared => $composableBuilder(
    column: $table.consentShared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMock => $composableBuilder(
    column: $table.isMock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiseaseDetectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiseaseDetectionsTable> {
  $$DiseaseDetectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cropId =>
      $composableBuilder(column: $table.cropId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<bool> get consentShared => $composableBuilder(
    column: $table.consentShared,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMock =>
      $composableBuilder(column: $table.isMock, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$DiseaseDetectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiseaseDetectionsTable,
          DiseaseDetection,
          $$DiseaseDetectionsTableFilterComposer,
          $$DiseaseDetectionsTableOrderingComposer,
          $$DiseaseDetectionsTableAnnotationComposer,
          $$DiseaseDetectionsTableCreateCompanionBuilder,
          $$DiseaseDetectionsTableUpdateCompanionBuilder,
          (
            DiseaseDetection,
            BaseReferences<
              _$AppDatabase,
              $DiseaseDetectionsTable,
              DiseaseDetection
            >,
          ),
          DiseaseDetection,
          PrefetchHooks Function()
        > {
  $$DiseaseDetectionsTableTableManager(
    _$AppDatabase db,
    $DiseaseDetectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiseaseDetectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiseaseDetectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiseaseDetectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cropId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<bool> consentShared = const Value.absent(),
                Value<bool> isMock = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiseaseDetectionsCompanion(
                id: id,
                cropId: cropId,
                label: label,
                confidence: confidence,
                imagePath: imagePath,
                lat: lat,
                lng: lng,
                consentShared: consentShared,
                isMock: isMock,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> cropId = const Value.absent(),
                required String label,
                required double confidence,
                Value<String?> imagePath = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<bool> consentShared = const Value.absent(),
                Value<bool> isMock = const Value.absent(),
                required DateTime createdAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiseaseDetectionsCompanion.insert(
                id: id,
                cropId: cropId,
                label: label,
                confidence: confidence,
                imagePath: imagePath,
                lat: lat,
                lng: lng,
                consentShared: consentShared,
                isMock: isMock,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiseaseDetectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiseaseDetectionsTable,
      DiseaseDetection,
      $$DiseaseDetectionsTableFilterComposer,
      $$DiseaseDetectionsTableOrderingComposer,
      $$DiseaseDetectionsTableAnnotationComposer,
      $$DiseaseDetectionsTableCreateCompanionBuilder,
      $$DiseaseDetectionsTableUpdateCompanionBuilder,
      (
        DiseaseDetection,
        BaseReferences<
          _$AppDatabase,
          $DiseaseDetectionsTable,
          DiseaseDetection
        >,
      ),
      DiseaseDetection,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      required String name,
      required String category,
      required double pricePerUnit,
      required String unit,
      Value<String?> imageUrl,
      Value<String?> description,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<double> pricePerUnit,
      Value<String> unit,
      Value<String?> imageUrl,
      Value<String?> description,
      Value<int> rowid,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerUnit => $composableBuilder(
    column: $table.pricePerUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerUnit => $composableBuilder(
    column: $table.pricePerUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get pricePerUnit => $composableBuilder(
    column: $table.pricePerUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> pricePerUnit = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                category: category,
                pricePerUnit: pricePerUnit,
                unit: unit,
                imageUrl: imageUrl,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                required double pricePerUnit,
                required String unit,
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                category: category,
                pricePerUnit: pricePerUnit,
                unit: unit,
                imageUrl: imageUrl,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$OrdersTableCreateCompanionBuilder =
    OrdersCompanion Function({
      required String id,
      required DateTime createdAt,
      Value<String> status,
      required double totalAmount,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$OrdersTableUpdateCompanionBuilder =
    OrdersCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<String> status,
      Value<double> totalAmount,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTable,
          Order,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (Order, BaseReferences<_$AppDatabase, $OrdersTable, Order>),
          Order,
          PrefetchHooks Function()
        > {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                createdAt: createdAt,
                status: status,
                totalAmount: totalAmount,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                Value<String> status = const Value.absent(),
                required double totalAmount,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                createdAt: createdAt,
                status: status,
                totalAmount: totalAmount,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTable,
      Order,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (Order, BaseReferences<_$AppDatabase, $OrdersTable, Order>),
      Order,
      PrefetchHooks Function()
    >;
typedef $$OrderItemsTableCreateCompanionBuilder =
    OrderItemsCompanion Function({
      Value<int> id,
      required String orderId,
      required String productId,
      required String productName,
      required int quantity,
      required double unitPrice,
    });
typedef $$OrderItemsTableUpdateCompanionBuilder =
    OrderItemsCompanion Function({
      Value<int> id,
      Value<String> orderId,
      Value<String> productId,
      Value<String> productName,
      Value<int> quantity,
      Value<double> unitPrice,
    });

class $$OrderItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableFilterComposer({
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

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrderItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableOrderingComposer({
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

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrderItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);
}

class $$OrderItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrderItemsTable,
          OrderItem,
          $$OrderItemsTableFilterComposer,
          $$OrderItemsTableOrderingComposer,
          $$OrderItemsTableAnnotationComposer,
          $$OrderItemsTableCreateCompanionBuilder,
          $$OrderItemsTableUpdateCompanionBuilder,
          (
            OrderItem,
            BaseReferences<_$AppDatabase, $OrderItemsTable, OrderItem>,
          ),
          OrderItem,
          PrefetchHooks Function()
        > {
  $$OrderItemsTableTableManager(_$AppDatabase db, $OrderItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
              }) => OrderItemsCompanion(
                id: id,
                orderId: orderId,
                productId: productId,
                productName: productName,
                quantity: quantity,
                unitPrice: unitPrice,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String orderId,
                required String productId,
                required String productName,
                required int quantity,
                required double unitPrice,
              }) => OrderItemsCompanion.insert(
                id: id,
                orderId: orderId,
                productId: productId,
                productName: productName,
                quantity: quantity,
                unitPrice: unitPrice,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrderItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrderItemsTable,
      OrderItem,
      $$OrderItemsTableFilterComposer,
      $$OrderItemsTableOrderingComposer,
      $$OrderItemsTableAnnotationComposer,
      $$OrderItemsTableCreateCompanionBuilder,
      $$OrderItemsTableUpdateCompanionBuilder,
      (OrderItem, BaseReferences<_$AppDatabase, $OrderItemsTable, OrderItem>),
      OrderItem,
      PrefetchHooks Function()
    >;
typedef $$DiseaseAlertsTableCreateCompanionBuilder =
    DiseaseAlertsCompanion Function({
      required String id,
      required String label,
      required double lat,
      required double lng,
      required int detectionCount,
      required double radiusKm,
      required DateTime windowStart,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$DiseaseAlertsTableUpdateCompanionBuilder =
    DiseaseAlertsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<double> lat,
      Value<double> lng,
      Value<int> detectionCount,
      Value<double> radiusKm,
      Value<DateTime> windowStart,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$DiseaseAlertsTableFilterComposer
    extends Composer<_$AppDatabase, $DiseaseAlertsTable> {
  $$DiseaseAlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get detectionCount => $composableBuilder(
    column: $table.detectionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radiusKm => $composableBuilder(
    column: $table.radiusKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DiseaseAlertsTableOrderingComposer
    extends Composer<_$AppDatabase, $DiseaseAlertsTable> {
  $$DiseaseAlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get detectionCount => $composableBuilder(
    column: $table.detectionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radiusKm => $composableBuilder(
    column: $table.radiusKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiseaseAlertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiseaseAlertsTable> {
  $$DiseaseAlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<int> get detectionCount => $composableBuilder(
    column: $table.detectionCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get radiusKm =>
      $composableBuilder(column: $table.radiusKm, builder: (column) => column);

  GeneratedColumn<DateTime> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$DiseaseAlertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiseaseAlertsTable,
          DiseaseAlert,
          $$DiseaseAlertsTableFilterComposer,
          $$DiseaseAlertsTableOrderingComposer,
          $$DiseaseAlertsTableAnnotationComposer,
          $$DiseaseAlertsTableCreateCompanionBuilder,
          $$DiseaseAlertsTableUpdateCompanionBuilder,
          (
            DiseaseAlert,
            BaseReferences<_$AppDatabase, $DiseaseAlertsTable, DiseaseAlert>,
          ),
          DiseaseAlert,
          PrefetchHooks Function()
        > {
  $$DiseaseAlertsTableTableManager(_$AppDatabase db, $DiseaseAlertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiseaseAlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiseaseAlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiseaseAlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<int> detectionCount = const Value.absent(),
                Value<double> radiusKm = const Value.absent(),
                Value<DateTime> windowStart = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiseaseAlertsCompanion(
                id: id,
                label: label,
                lat: lat,
                lng: lng,
                detectionCount: detectionCount,
                radiusKm: radiusKm,
                windowStart: windowStart,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required double lat,
                required double lng,
                required int detectionCount,
                required double radiusKm,
                required DateTime windowStart,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => DiseaseAlertsCompanion.insert(
                id: id,
                label: label,
                lat: lat,
                lng: lng,
                detectionCount: detectionCount,
                radiusKm: radiusKm,
                windowStart: windowStart,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiseaseAlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiseaseAlertsTable,
      DiseaseAlert,
      $$DiseaseAlertsTableFilterComposer,
      $$DiseaseAlertsTableOrderingComposer,
      $$DiseaseAlertsTableAnnotationComposer,
      $$DiseaseAlertsTableCreateCompanionBuilder,
      $$DiseaseAlertsTableUpdateCompanionBuilder,
      (
        DiseaseAlert,
        BaseReferences<_$AppDatabase, $DiseaseAlertsTable, DiseaseAlert>,
      ),
      DiseaseAlert,
      PrefetchHooks Function()
    >;
typedef $$P2pPacketsTableCreateCompanionBuilder =
    P2pPacketsCompanion Function({
      required String packetId,
      required Uint8List rawBytes,
      required int type,
      required String cropId,
      required String label,
      required double confidence,
      required String severity,
      required double lat,
      required double lng,
      required DateTime observedAt,
      required DateTime expiresAt,
      required String sourceDeviceId,
      Value<String?> receivedFromPeerId,
      Value<String> forwardedToPeerIdsJson,
      Value<String?> aggregationGroupId,
      Value<bool> verified,
      Value<bool> syncedToBackend,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$P2pPacketsTableUpdateCompanionBuilder =
    P2pPacketsCompanion Function({
      Value<String> packetId,
      Value<Uint8List> rawBytes,
      Value<int> type,
      Value<String> cropId,
      Value<String> label,
      Value<double> confidence,
      Value<String> severity,
      Value<double> lat,
      Value<double> lng,
      Value<DateTime> observedAt,
      Value<DateTime> expiresAt,
      Value<String> sourceDeviceId,
      Value<String?> receivedFromPeerId,
      Value<String> forwardedToPeerIdsJson,
      Value<String?> aggregationGroupId,
      Value<bool> verified,
      Value<bool> syncedToBackend,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$P2pPacketsTableFilterComposer
    extends Composer<_$AppDatabase, $P2pPacketsTable> {
  $$P2pPacketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packetId => $composableBuilder(
    column: $table.packetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get rawBytes => $composableBuilder(
    column: $table.rawBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropId => $composableBuilder(
    column: $table.cropId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receivedFromPeerId => $composableBuilder(
    column: $table.receivedFromPeerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forwardedToPeerIdsJson => $composableBuilder(
    column: $table.forwardedToPeerIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aggregationGroupId => $composableBuilder(
    column: $table.aggregationGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncedToBackend => $composableBuilder(
    column: $table.syncedToBackend,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$P2pPacketsTableOrderingComposer
    extends Composer<_$AppDatabase, $P2pPacketsTable> {
  $$P2pPacketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packetId => $composableBuilder(
    column: $table.packetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get rawBytes => $composableBuilder(
    column: $table.rawBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropId => $composableBuilder(
    column: $table.cropId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receivedFromPeerId => $composableBuilder(
    column: $table.receivedFromPeerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forwardedToPeerIdsJson => $composableBuilder(
    column: $table.forwardedToPeerIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aggregationGroupId => $composableBuilder(
    column: $table.aggregationGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncedToBackend => $composableBuilder(
    column: $table.syncedToBackend,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$P2pPacketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $P2pPacketsTable> {
  $$P2pPacketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packetId =>
      $composableBuilder(column: $table.packetId, builder: (column) => column);

  GeneratedColumn<Uint8List> get rawBytes =>
      $composableBuilder(column: $table.rawBytes, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get cropId =>
      $composableBuilder(column: $table.cropId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receivedFromPeerId => $composableBuilder(
    column: $table.receivedFromPeerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get forwardedToPeerIdsJson => $composableBuilder(
    column: $table.forwardedToPeerIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aggregationGroupId => $composableBuilder(
    column: $table.aggregationGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get verified =>
      $composableBuilder(column: $table.verified, builder: (column) => column);

  GeneratedColumn<bool> get syncedToBackend => $composableBuilder(
    column: $table.syncedToBackend,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$P2pPacketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $P2pPacketsTable,
          P2pPacket,
          $$P2pPacketsTableFilterComposer,
          $$P2pPacketsTableOrderingComposer,
          $$P2pPacketsTableAnnotationComposer,
          $$P2pPacketsTableCreateCompanionBuilder,
          $$P2pPacketsTableUpdateCompanionBuilder,
          (
            P2pPacket,
            BaseReferences<_$AppDatabase, $P2pPacketsTable, P2pPacket>,
          ),
          P2pPacket,
          PrefetchHooks Function()
        > {
  $$P2pPacketsTableTableManager(_$AppDatabase db, $P2pPacketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$P2pPacketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$P2pPacketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$P2pPacketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packetId = const Value.absent(),
                Value<Uint8List> rawBytes = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String> cropId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<DateTime> observedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<String> sourceDeviceId = const Value.absent(),
                Value<String?> receivedFromPeerId = const Value.absent(),
                Value<String> forwardedToPeerIdsJson = const Value.absent(),
                Value<String?> aggregationGroupId = const Value.absent(),
                Value<bool> verified = const Value.absent(),
                Value<bool> syncedToBackend = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => P2pPacketsCompanion(
                packetId: packetId,
                rawBytes: rawBytes,
                type: type,
                cropId: cropId,
                label: label,
                confidence: confidence,
                severity: severity,
                lat: lat,
                lng: lng,
                observedAt: observedAt,
                expiresAt: expiresAt,
                sourceDeviceId: sourceDeviceId,
                receivedFromPeerId: receivedFromPeerId,
                forwardedToPeerIdsJson: forwardedToPeerIdsJson,
                aggregationGroupId: aggregationGroupId,
                verified: verified,
                syncedToBackend: syncedToBackend,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packetId,
                required Uint8List rawBytes,
                required int type,
                required String cropId,
                required String label,
                required double confidence,
                required String severity,
                required double lat,
                required double lng,
                required DateTime observedAt,
                required DateTime expiresAt,
                required String sourceDeviceId,
                Value<String?> receivedFromPeerId = const Value.absent(),
                Value<String> forwardedToPeerIdsJson = const Value.absent(),
                Value<String?> aggregationGroupId = const Value.absent(),
                Value<bool> verified = const Value.absent(),
                Value<bool> syncedToBackend = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => P2pPacketsCompanion.insert(
                packetId: packetId,
                rawBytes: rawBytes,
                type: type,
                cropId: cropId,
                label: label,
                confidence: confidence,
                severity: severity,
                lat: lat,
                lng: lng,
                observedAt: observedAt,
                expiresAt: expiresAt,
                sourceDeviceId: sourceDeviceId,
                receivedFromPeerId: receivedFromPeerId,
                forwardedToPeerIdsJson: forwardedToPeerIdsJson,
                aggregationGroupId: aggregationGroupId,
                verified: verified,
                syncedToBackend: syncedToBackend,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$P2pPacketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $P2pPacketsTable,
      P2pPacket,
      $$P2pPacketsTableFilterComposer,
      $$P2pPacketsTableOrderingComposer,
      $$P2pPacketsTableAnnotationComposer,
      $$P2pPacketsTableCreateCompanionBuilder,
      $$P2pPacketsTableUpdateCompanionBuilder,
      (P2pPacket, BaseReferences<_$AppDatabase, $P2pPacketsTable, P2pPacket>),
      P2pPacket,
      PrefetchHooks Function()
    >;
typedef $$P2pAggregatedAlertsTableCreateCompanionBuilder =
    P2pAggregatedAlertsCompanion Function({
      required String id,
      required String label,
      required String cropId,
      required double lat,
      required double lng,
      required int detectionCount,
      required double radiusKm,
      required DateTime windowStart,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$P2pAggregatedAlertsTableUpdateCompanionBuilder =
    P2pAggregatedAlertsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<String> cropId,
      Value<double> lat,
      Value<double> lng,
      Value<int> detectionCount,
      Value<double> radiusKm,
      Value<DateTime> windowStart,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$P2pAggregatedAlertsTableFilterComposer
    extends Composer<_$AppDatabase, $P2pAggregatedAlertsTable> {
  $$P2pAggregatedAlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropId => $composableBuilder(
    column: $table.cropId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get detectionCount => $composableBuilder(
    column: $table.detectionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radiusKm => $composableBuilder(
    column: $table.radiusKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$P2pAggregatedAlertsTableOrderingComposer
    extends Composer<_$AppDatabase, $P2pAggregatedAlertsTable> {
  $$P2pAggregatedAlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropId => $composableBuilder(
    column: $table.cropId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get detectionCount => $composableBuilder(
    column: $table.detectionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radiusKm => $composableBuilder(
    column: $table.radiusKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$P2pAggregatedAlertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $P2pAggregatedAlertsTable> {
  $$P2pAggregatedAlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get cropId =>
      $composableBuilder(column: $table.cropId, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<int> get detectionCount => $composableBuilder(
    column: $table.detectionCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get radiusKm =>
      $composableBuilder(column: $table.radiusKm, builder: (column) => column);

  GeneratedColumn<DateTime> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$P2pAggregatedAlertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $P2pAggregatedAlertsTable,
          P2pAggregatedAlert,
          $$P2pAggregatedAlertsTableFilterComposer,
          $$P2pAggregatedAlertsTableOrderingComposer,
          $$P2pAggregatedAlertsTableAnnotationComposer,
          $$P2pAggregatedAlertsTableCreateCompanionBuilder,
          $$P2pAggregatedAlertsTableUpdateCompanionBuilder,
          (
            P2pAggregatedAlert,
            BaseReferences<
              _$AppDatabase,
              $P2pAggregatedAlertsTable,
              P2pAggregatedAlert
            >,
          ),
          P2pAggregatedAlert,
          PrefetchHooks Function()
        > {
  $$P2pAggregatedAlertsTableTableManager(
    _$AppDatabase db,
    $P2pAggregatedAlertsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$P2pAggregatedAlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$P2pAggregatedAlertsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$P2pAggregatedAlertsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> cropId = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<int> detectionCount = const Value.absent(),
                Value<double> radiusKm = const Value.absent(),
                Value<DateTime> windowStart = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => P2pAggregatedAlertsCompanion(
                id: id,
                label: label,
                cropId: cropId,
                lat: lat,
                lng: lng,
                detectionCount: detectionCount,
                radiusKm: radiusKm,
                windowStart: windowStart,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String cropId,
                required double lat,
                required double lng,
                required int detectionCount,
                required double radiusKm,
                required DateTime windowStart,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => P2pAggregatedAlertsCompanion.insert(
                id: id,
                label: label,
                cropId: cropId,
                lat: lat,
                lng: lng,
                detectionCount: detectionCount,
                radiusKm: radiusKm,
                windowStart: windowStart,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$P2pAggregatedAlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $P2pAggregatedAlertsTable,
      P2pAggregatedAlert,
      $$P2pAggregatedAlertsTableFilterComposer,
      $$P2pAggregatedAlertsTableOrderingComposer,
      $$P2pAggregatedAlertsTableAnnotationComposer,
      $$P2pAggregatedAlertsTableCreateCompanionBuilder,
      $$P2pAggregatedAlertsTableUpdateCompanionBuilder,
      (
        P2pAggregatedAlert,
        BaseReferences<
          _$AppDatabase,
          $P2pAggregatedAlertsTable,
          P2pAggregatedAlert
        >,
      ),
      P2pAggregatedAlert,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueItemsTableCreateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<int> id,
      required String type,
      required String refId,
      required DateTime createdAt,
      Value<int> attempts,
      Value<String> status,
    });
typedef $$SyncQueueItemsTableUpdateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> refId,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<String> status,
    });

class $$SyncQueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SyncQueueItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueItemsTable,
          SyncQueueItem,
          $$SyncQueueItemsTableFilterComposer,
          $$SyncQueueItemsTableOrderingComposer,
          $$SyncQueueItemsTableAnnotationComposer,
          $$SyncQueueItemsTableCreateCompanionBuilder,
          $$SyncQueueItemsTableUpdateCompanionBuilder,
          (
            SyncQueueItem,
            BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>,
          ),
          SyncQueueItem,
          PrefetchHooks Function()
        > {
  $$SyncQueueItemsTableTableManager(
    _$AppDatabase db,
    $SyncQueueItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> refId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => SyncQueueItemsCompanion(
                id: id,
                type: type,
                refId: refId,
                createdAt: createdAt,
                attempts: attempts,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String refId,
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => SyncQueueItemsCompanion.insert(
                id: id,
                type: type,
                refId: refId,
                createdAt: createdAt,
                attempts: attempts,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueItemsTable,
      SyncQueueItem,
      $$SyncQueueItemsTableFilterComposer,
      $$SyncQueueItemsTableOrderingComposer,
      $$SyncQueueItemsTableAnnotationComposer,
      $$SyncQueueItemsTableCreateCompanionBuilder,
      $$SyncQueueItemsTableUpdateCompanionBuilder,
      (
        SyncQueueItem,
        BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>,
      ),
      SyncQueueItem,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder =
    SyncMetaCompanion Function({
      required String domain,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$SyncMetaTableUpdateCompanionBuilder =
    SyncMetaCompanion Function({
      Value<String> domain,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaData,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaData,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
          ),
          SyncMetaData,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> domain = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion(
                domain: domain,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String domain,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                domain: domain,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaData,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (
        SyncMetaData,
        BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
      ),
      SyncMetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MarketPricesTableTableManager get marketPrices =>
      $$MarketPricesTableTableManager(_db, _db.marketPrices);
  $$MspRatesTableTableManager get mspRates =>
      $$MspRatesTableTableManager(_db, _db.mspRates);
  $$SoilReportsTableTableManager get soilReports =>
      $$SoilReportsTableTableManager(_db, _db.soilReports);
  $$CropRecommendationsTableTableManager get cropRecommendations =>
      $$CropRecommendationsTableTableManager(_db, _db.cropRecommendations);
  $$DiseaseDetectionsTableTableManager get diseaseDetections =>
      $$DiseaseDetectionsTableTableManager(_db, _db.diseaseDetections);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db, _db.orderItems);
  $$DiseaseAlertsTableTableManager get diseaseAlerts =>
      $$DiseaseAlertsTableTableManager(_db, _db.diseaseAlerts);
  $$P2pPacketsTableTableManager get p2pPackets =>
      $$P2pPacketsTableTableManager(_db, _db.p2pPackets);
  $$P2pAggregatedAlertsTableTableManager get p2pAggregatedAlerts =>
      $$P2pAggregatedAlertsTableTableManager(_db, _db.p2pAggregatedAlerts);
  $$SyncQueueItemsTableTableManager get syncQueueItems =>
      $$SyncQueueItemsTableTableManager(_db, _db.syncQueueItems);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}
