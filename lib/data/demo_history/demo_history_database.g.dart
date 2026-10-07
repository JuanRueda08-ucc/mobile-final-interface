// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demo_history_database.dart';

// ignore_for_file: type=lint
class $DemoSessionsTable extends DemoSessions
    with TableInfo<$DemoSessionsTable, DemoSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DemoSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    check: () => origin.equals('demo'),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('demo'),
  );
  static const VerificationMeta _sessionNumberMeta = const VerificationMeta(
    'sessionNumber',
  );
  @override
  late final GeneratedColumn<int> sessionNumber = GeneratedColumn<int>(
    'session_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _startedEpochMsMeta = const VerificationMeta(
    'startedEpochMs',
  );
  @override
  late final GeneratedColumn<int> startedEpochMs = GeneratedColumn<int>(
    'started_epoch_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startOffsetMinutesMeta =
      const VerificationMeta('startOffsetMinutes');
  @override
  late final GeneratedColumn<int> startOffsetMinutes = GeneratedColumn<int>(
    'start_offset_minutes',
    aliasedName,
    false,
    check: () => ComparableExpr(startOffsetMinutes).isBetweenValues(-840, 840),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lifecycleMeta = const VerificationMeta(
    'lifecycle',
  );
  @override
  late final GeneratedColumn<String> lifecycle = GeneratedColumn<String>(
    'lifecycle',
    aliasedName,
    false,
    check: () => lifecycle.isIn(const [
      'active',
      'paused',
      'stopping',
      'finalized',
      'interrupted',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedEpochMsMeta = const VerificationMeta(
    'endedEpochMs',
  );
  @override
  late final GeneratedColumn<int> endedEpochMs = GeneratedColumn<int>(
    'ended_epoch_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endOffsetMinutesMeta = const VerificationMeta(
    'endOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> endOffsetMinutes = GeneratedColumn<int>(
    'end_offset_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endOffsetMsMeta = const VerificationMeta(
    'endOffsetMs',
  );
  @override
  late final GeneratedColumn<int> endOffsetMs = GeneratedColumn<int>(
    'end_offset_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestDurableOffsetMsMeta =
      const VerificationMeta('latestDurableOffsetMs');
  @override
  late final GeneratedColumn<int> latestDurableOffsetMs = GeneratedColumn<int>(
    'latest_durable_offset_ms',
    aliasedName,
    false,
    check: () => ComparableExpr(latestDurableOffsetMs).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calibrationIdMeta = const VerificationMeta(
    'calibrationId',
  );
  @override
  late final GeneratedColumn<String> calibrationId = GeneratedColumn<String>(
    'calibration_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _integrityStatusMeta = const VerificationMeta(
    'integrityStatus',
  );
  @override
  late final GeneratedColumn<String> integrityStatus = GeneratedColumn<String>(
    'integrity_status',
    aliasedName,
    false,
    check: () => integrityStatus.isIn(const ['complete', 'incomplete']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evaluableMsMeta = const VerificationMeta(
    'evaluableMs',
  );
  @override
  late final GeneratedColumn<int> evaluableMs = GeneratedColumn<int>(
    'evaluable_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nonEvaluableMsMeta = const VerificationMeta(
    'nonEvaluableMs',
  );
  @override
  late final GeneratedColumn<int> nonEvaluableMs = GeneratedColumn<int>(
    'non_evaluable_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedMsMeta = const VerificationMeta(
    'pausedMs',
  );
  @override
  late final GeneratedColumn<int> pausedMs = GeneratedColumn<int>(
    'paused_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unknownMsMeta = const VerificationMeta(
    'unknownMs',
  );
  @override
  late final GeneratedColumn<int> unknownMs = GeneratedColumn<int>(
    'unknown_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monitoredMsMeta = const VerificationMeta(
    'monitoredMs',
  );
  @override
  late final GeneratedColumn<int> monitoredMs = GeneratedColumn<int>(
    'monitored_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeCountMeta = const VerificationMeta(
    'episodeCount',
  );
  @override
  late final GeneratedColumn<int> episodeCount = GeneratedColumn<int>(
    'episode_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warningCountMeta = const VerificationMeta(
    'warningCount',
  );
  @override
  late final GeneratedColumn<int> warningCount = GeneratedColumn<int>(
    'warning_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closureCountMeta = const VerificationMeta(
    'closureCount',
  );
  @override
  late final GeneratedColumn<int> closureCount = GeneratedColumn<int>(
    'closure_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soundsPlayedMeta = const VerificationMeta(
    'soundsPlayed',
  );
  @override
  late final GeneratedColumn<int> soundsPlayed = GeneratedColumn<int>(
    'sounds_played',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soundsFailedMeta = const VerificationMeta(
    'soundsFailed',
  );
  @override
  late final GeneratedColumn<int> soundsFailed = GeneratedColumn<int>(
    'sounds_failed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pauseCountMeta = const VerificationMeta(
    'pauseCount',
  );
  @override
  late final GeneratedColumn<int> pauseCount = GeneratedColumn<int>(
    'pause_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    origin,
    sessionNumber,
    startedEpochMs,
    startOffsetMinutes,
    lifecycle,
    endedEpochMs,
    endOffsetMinutes,
    endOffsetMs,
    latestDurableOffsetMs,
    calibrationId,
    integrityStatus,
    evaluableMs,
    nonEvaluableMs,
    pausedMs,
    unknownMs,
    monitoredMs,
    episodeCount,
    warningCount,
    closureCount,
    soundsPlayed,
    soundsFailed,
    pauseCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'demo_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DemoSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('session_number')) {
      context.handle(
        _sessionNumberMeta,
        sessionNumber.isAcceptableOrUnknown(
          data['session_number']!,
          _sessionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionNumberMeta);
    }
    if (data.containsKey('started_epoch_ms')) {
      context.handle(
        _startedEpochMsMeta,
        startedEpochMs.isAcceptableOrUnknown(
          data['started_epoch_ms']!,
          _startedEpochMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedEpochMsMeta);
    }
    if (data.containsKey('start_offset_minutes')) {
      context.handle(
        _startOffsetMinutesMeta,
        startOffsetMinutes.isAcceptableOrUnknown(
          data['start_offset_minutes']!,
          _startOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startOffsetMinutesMeta);
    }
    if (data.containsKey('lifecycle')) {
      context.handle(
        _lifecycleMeta,
        lifecycle.isAcceptableOrUnknown(data['lifecycle']!, _lifecycleMeta),
      );
    } else if (isInserting) {
      context.missing(_lifecycleMeta);
    }
    if (data.containsKey('ended_epoch_ms')) {
      context.handle(
        _endedEpochMsMeta,
        endedEpochMs.isAcceptableOrUnknown(
          data['ended_epoch_ms']!,
          _endedEpochMsMeta,
        ),
      );
    }
    if (data.containsKey('end_offset_minutes')) {
      context.handle(
        _endOffsetMinutesMeta,
        endOffsetMinutes.isAcceptableOrUnknown(
          data['end_offset_minutes']!,
          _endOffsetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('end_offset_ms')) {
      context.handle(
        _endOffsetMsMeta,
        endOffsetMs.isAcceptableOrUnknown(
          data['end_offset_ms']!,
          _endOffsetMsMeta,
        ),
      );
    }
    if (data.containsKey('latest_durable_offset_ms')) {
      context.handle(
        _latestDurableOffsetMsMeta,
        latestDurableOffsetMs.isAcceptableOrUnknown(
          data['latest_durable_offset_ms']!,
          _latestDurableOffsetMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_latestDurableOffsetMsMeta);
    }
    if (data.containsKey('calibration_id')) {
      context.handle(
        _calibrationIdMeta,
        calibrationId.isAcceptableOrUnknown(
          data['calibration_id']!,
          _calibrationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calibrationIdMeta);
    }
    if (data.containsKey('integrity_status')) {
      context.handle(
        _integrityStatusMeta,
        integrityStatus.isAcceptableOrUnknown(
          data['integrity_status']!,
          _integrityStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_integrityStatusMeta);
    }
    if (data.containsKey('evaluable_ms')) {
      context.handle(
        _evaluableMsMeta,
        evaluableMs.isAcceptableOrUnknown(
          data['evaluable_ms']!,
          _evaluableMsMeta,
        ),
      );
    }
    if (data.containsKey('non_evaluable_ms')) {
      context.handle(
        _nonEvaluableMsMeta,
        nonEvaluableMs.isAcceptableOrUnknown(
          data['non_evaluable_ms']!,
          _nonEvaluableMsMeta,
        ),
      );
    }
    if (data.containsKey('paused_ms')) {
      context.handle(
        _pausedMsMeta,
        pausedMs.isAcceptableOrUnknown(data['paused_ms']!, _pausedMsMeta),
      );
    }
    if (data.containsKey('unknown_ms')) {
      context.handle(
        _unknownMsMeta,
        unknownMs.isAcceptableOrUnknown(data['unknown_ms']!, _unknownMsMeta),
      );
    }
    if (data.containsKey('monitored_ms')) {
      context.handle(
        _monitoredMsMeta,
        monitoredMs.isAcceptableOrUnknown(
          data['monitored_ms']!,
          _monitoredMsMeta,
        ),
      );
    }
    if (data.containsKey('episode_count')) {
      context.handle(
        _episodeCountMeta,
        episodeCount.isAcceptableOrUnknown(
          data['episode_count']!,
          _episodeCountMeta,
        ),
      );
    }
    if (data.containsKey('warning_count')) {
      context.handle(
        _warningCountMeta,
        warningCount.isAcceptableOrUnknown(
          data['warning_count']!,
          _warningCountMeta,
        ),
      );
    }
    if (data.containsKey('closure_count')) {
      context.handle(
        _closureCountMeta,
        closureCount.isAcceptableOrUnknown(
          data['closure_count']!,
          _closureCountMeta,
        ),
      );
    }
    if (data.containsKey('sounds_played')) {
      context.handle(
        _soundsPlayedMeta,
        soundsPlayed.isAcceptableOrUnknown(
          data['sounds_played']!,
          _soundsPlayedMeta,
        ),
      );
    }
    if (data.containsKey('sounds_failed')) {
      context.handle(
        _soundsFailedMeta,
        soundsFailed.isAcceptableOrUnknown(
          data['sounds_failed']!,
          _soundsFailedMeta,
        ),
      );
    }
    if (data.containsKey('pause_count')) {
      context.handle(
        _pauseCountMeta,
        pauseCount.isAcceptableOrUnknown(data['pause_count']!, _pauseCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  DemoSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DemoSessionRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      sessionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_number'],
      )!,
      startedEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_epoch_ms'],
      )!,
      startOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_offset_minutes'],
      )!,
      lifecycle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lifecycle'],
      )!,
      endedEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_epoch_ms'],
      ),
      endOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_offset_minutes'],
      ),
      endOffsetMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_offset_ms'],
      ),
      latestDurableOffsetMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latest_durable_offset_ms'],
      )!,
      calibrationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calibration_id'],
      )!,
      integrityStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}integrity_status'],
      )!,
      evaluableMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}evaluable_ms'],
      ),
      nonEvaluableMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}non_evaluable_ms'],
      ),
      pausedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_ms'],
      ),
      unknownMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unknown_ms'],
      ),
      monitoredMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monitored_ms'],
      ),
      episodeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_count'],
      ),
      warningCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warning_count'],
      ),
      closureCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closure_count'],
      ),
      soundsPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sounds_played'],
      ),
      soundsFailed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sounds_failed'],
      ),
      pauseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pause_count'],
      ),
    );
  }

  @override
  $DemoSessionsTable createAlias(String alias) {
    return $DemoSessionsTable(attachedDatabase, alias);
  }
}

class DemoSessionRow extends DataClass implements Insertable<DemoSessionRow> {
  final String sessionId;

  /// Origen permanente: siempre `demo` en esta base (RF32.CA1).
  final String origin;

  /// Número de `S-DEMO-NNNN`: no se reutiliza entre ejecuciones.
  final int sessionNumber;
  final int startedEpochMs;
  final int startOffsetMinutes;

  /// active, paused, stopping, finalized o interrupted (Área 06 §6).
  final String lifecycle;

  /// Fin civil confirmado: nulo salvo en `finalized`.
  final int? endedEpochMs;
  final int? endOffsetMinutes;

  /// Desplazamiento monotónico del fin del tiempo representado (solicitud de
  /// cierre). Nulo si el final no se confirmó.
  final int? endOffsetMs;

  /// Desplazamiento del último hecho guardado (Área 06 §11: último límite
  /// confirmado, no «hasta ahora»).
  final int latestDurableOffsetMs;
  final String calibrationId;

  /// complete o incomplete (Área 06 §11).
  final String integrityStatus;
  final int? evaluableMs;
  final int? nonEvaluableMs;
  final int? pausedMs;
  final int? unknownMs;

  /// Tiempo realmente monitoreado: evaluable + no evaluable, sin pausas.
  final int? monitoredMs;
  final int? episodeCount;
  final int? warningCount;
  final int? closureCount;
  final int? soundsPlayed;
  final int? soundsFailed;
  final int? pauseCount;
  const DemoSessionRow({
    required this.sessionId,
    required this.origin,
    required this.sessionNumber,
    required this.startedEpochMs,
    required this.startOffsetMinutes,
    required this.lifecycle,
    this.endedEpochMs,
    this.endOffsetMinutes,
    this.endOffsetMs,
    required this.latestDurableOffsetMs,
    required this.calibrationId,
    required this.integrityStatus,
    this.evaluableMs,
    this.nonEvaluableMs,
    this.pausedMs,
    this.unknownMs,
    this.monitoredMs,
    this.episodeCount,
    this.warningCount,
    this.closureCount,
    this.soundsPlayed,
    this.soundsFailed,
    this.pauseCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['origin'] = Variable<String>(origin);
    map['session_number'] = Variable<int>(sessionNumber);
    map['started_epoch_ms'] = Variable<int>(startedEpochMs);
    map['start_offset_minutes'] = Variable<int>(startOffsetMinutes);
    map['lifecycle'] = Variable<String>(lifecycle);
    if (!nullToAbsent || endedEpochMs != null) {
      map['ended_epoch_ms'] = Variable<int>(endedEpochMs);
    }
    if (!nullToAbsent || endOffsetMinutes != null) {
      map['end_offset_minutes'] = Variable<int>(endOffsetMinutes);
    }
    if (!nullToAbsent || endOffsetMs != null) {
      map['end_offset_ms'] = Variable<int>(endOffsetMs);
    }
    map['latest_durable_offset_ms'] = Variable<int>(latestDurableOffsetMs);
    map['calibration_id'] = Variable<String>(calibrationId);
    map['integrity_status'] = Variable<String>(integrityStatus);
    if (!nullToAbsent || evaluableMs != null) {
      map['evaluable_ms'] = Variable<int>(evaluableMs);
    }
    if (!nullToAbsent || nonEvaluableMs != null) {
      map['non_evaluable_ms'] = Variable<int>(nonEvaluableMs);
    }
    if (!nullToAbsent || pausedMs != null) {
      map['paused_ms'] = Variable<int>(pausedMs);
    }
    if (!nullToAbsent || unknownMs != null) {
      map['unknown_ms'] = Variable<int>(unknownMs);
    }
    if (!nullToAbsent || monitoredMs != null) {
      map['monitored_ms'] = Variable<int>(monitoredMs);
    }
    if (!nullToAbsent || episodeCount != null) {
      map['episode_count'] = Variable<int>(episodeCount);
    }
    if (!nullToAbsent || warningCount != null) {
      map['warning_count'] = Variable<int>(warningCount);
    }
    if (!nullToAbsent || closureCount != null) {
      map['closure_count'] = Variable<int>(closureCount);
    }
    if (!nullToAbsent || soundsPlayed != null) {
      map['sounds_played'] = Variable<int>(soundsPlayed);
    }
    if (!nullToAbsent || soundsFailed != null) {
      map['sounds_failed'] = Variable<int>(soundsFailed);
    }
    if (!nullToAbsent || pauseCount != null) {
      map['pause_count'] = Variable<int>(pauseCount);
    }
    return map;
  }

  DemoSessionsCompanion toCompanion(bool nullToAbsent) {
    return DemoSessionsCompanion(
      sessionId: Value(sessionId),
      origin: Value(origin),
      sessionNumber: Value(sessionNumber),
      startedEpochMs: Value(startedEpochMs),
      startOffsetMinutes: Value(startOffsetMinutes),
      lifecycle: Value(lifecycle),
      endedEpochMs: endedEpochMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endedEpochMs),
      endOffsetMinutes: endOffsetMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(endOffsetMinutes),
      endOffsetMs: endOffsetMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endOffsetMs),
      latestDurableOffsetMs: Value(latestDurableOffsetMs),
      calibrationId: Value(calibrationId),
      integrityStatus: Value(integrityStatus),
      evaluableMs: evaluableMs == null && nullToAbsent
          ? const Value.absent()
          : Value(evaluableMs),
      nonEvaluableMs: nonEvaluableMs == null && nullToAbsent
          ? const Value.absent()
          : Value(nonEvaluableMs),
      pausedMs: pausedMs == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedMs),
      unknownMs: unknownMs == null && nullToAbsent
          ? const Value.absent()
          : Value(unknownMs),
      monitoredMs: monitoredMs == null && nullToAbsent
          ? const Value.absent()
          : Value(monitoredMs),
      episodeCount: episodeCount == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeCount),
      warningCount: warningCount == null && nullToAbsent
          ? const Value.absent()
          : Value(warningCount),
      closureCount: closureCount == null && nullToAbsent
          ? const Value.absent()
          : Value(closureCount),
      soundsPlayed: soundsPlayed == null && nullToAbsent
          ? const Value.absent()
          : Value(soundsPlayed),
      soundsFailed: soundsFailed == null && nullToAbsent
          ? const Value.absent()
          : Value(soundsFailed),
      pauseCount: pauseCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pauseCount),
    );
  }

  factory DemoSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DemoSessionRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      origin: serializer.fromJson<String>(json['origin']),
      sessionNumber: serializer.fromJson<int>(json['sessionNumber']),
      startedEpochMs: serializer.fromJson<int>(json['startedEpochMs']),
      startOffsetMinutes: serializer.fromJson<int>(json['startOffsetMinutes']),
      lifecycle: serializer.fromJson<String>(json['lifecycle']),
      endedEpochMs: serializer.fromJson<int?>(json['endedEpochMs']),
      endOffsetMinutes: serializer.fromJson<int?>(json['endOffsetMinutes']),
      endOffsetMs: serializer.fromJson<int?>(json['endOffsetMs']),
      latestDurableOffsetMs: serializer.fromJson<int>(
        json['latestDurableOffsetMs'],
      ),
      calibrationId: serializer.fromJson<String>(json['calibrationId']),
      integrityStatus: serializer.fromJson<String>(json['integrityStatus']),
      evaluableMs: serializer.fromJson<int?>(json['evaluableMs']),
      nonEvaluableMs: serializer.fromJson<int?>(json['nonEvaluableMs']),
      pausedMs: serializer.fromJson<int?>(json['pausedMs']),
      unknownMs: serializer.fromJson<int?>(json['unknownMs']),
      monitoredMs: serializer.fromJson<int?>(json['monitoredMs']),
      episodeCount: serializer.fromJson<int?>(json['episodeCount']),
      warningCount: serializer.fromJson<int?>(json['warningCount']),
      closureCount: serializer.fromJson<int?>(json['closureCount']),
      soundsPlayed: serializer.fromJson<int?>(json['soundsPlayed']),
      soundsFailed: serializer.fromJson<int?>(json['soundsFailed']),
      pauseCount: serializer.fromJson<int?>(json['pauseCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'origin': serializer.toJson<String>(origin),
      'sessionNumber': serializer.toJson<int>(sessionNumber),
      'startedEpochMs': serializer.toJson<int>(startedEpochMs),
      'startOffsetMinutes': serializer.toJson<int>(startOffsetMinutes),
      'lifecycle': serializer.toJson<String>(lifecycle),
      'endedEpochMs': serializer.toJson<int?>(endedEpochMs),
      'endOffsetMinutes': serializer.toJson<int?>(endOffsetMinutes),
      'endOffsetMs': serializer.toJson<int?>(endOffsetMs),
      'latestDurableOffsetMs': serializer.toJson<int>(latestDurableOffsetMs),
      'calibrationId': serializer.toJson<String>(calibrationId),
      'integrityStatus': serializer.toJson<String>(integrityStatus),
      'evaluableMs': serializer.toJson<int?>(evaluableMs),
      'nonEvaluableMs': serializer.toJson<int?>(nonEvaluableMs),
      'pausedMs': serializer.toJson<int?>(pausedMs),
      'unknownMs': serializer.toJson<int?>(unknownMs),
      'monitoredMs': serializer.toJson<int?>(monitoredMs),
      'episodeCount': serializer.toJson<int?>(episodeCount),
      'warningCount': serializer.toJson<int?>(warningCount),
      'closureCount': serializer.toJson<int?>(closureCount),
      'soundsPlayed': serializer.toJson<int?>(soundsPlayed),
      'soundsFailed': serializer.toJson<int?>(soundsFailed),
      'pauseCount': serializer.toJson<int?>(pauseCount),
    };
  }

  DemoSessionRow copyWith({
    String? sessionId,
    String? origin,
    int? sessionNumber,
    int? startedEpochMs,
    int? startOffsetMinutes,
    String? lifecycle,
    Value<int?> endedEpochMs = const Value.absent(),
    Value<int?> endOffsetMinutes = const Value.absent(),
    Value<int?> endOffsetMs = const Value.absent(),
    int? latestDurableOffsetMs,
    String? calibrationId,
    String? integrityStatus,
    Value<int?> evaluableMs = const Value.absent(),
    Value<int?> nonEvaluableMs = const Value.absent(),
    Value<int?> pausedMs = const Value.absent(),
    Value<int?> unknownMs = const Value.absent(),
    Value<int?> monitoredMs = const Value.absent(),
    Value<int?> episodeCount = const Value.absent(),
    Value<int?> warningCount = const Value.absent(),
    Value<int?> closureCount = const Value.absent(),
    Value<int?> soundsPlayed = const Value.absent(),
    Value<int?> soundsFailed = const Value.absent(),
    Value<int?> pauseCount = const Value.absent(),
  }) => DemoSessionRow(
    sessionId: sessionId ?? this.sessionId,
    origin: origin ?? this.origin,
    sessionNumber: sessionNumber ?? this.sessionNumber,
    startedEpochMs: startedEpochMs ?? this.startedEpochMs,
    startOffsetMinutes: startOffsetMinutes ?? this.startOffsetMinutes,
    lifecycle: lifecycle ?? this.lifecycle,
    endedEpochMs: endedEpochMs.present ? endedEpochMs.value : this.endedEpochMs,
    endOffsetMinutes: endOffsetMinutes.present
        ? endOffsetMinutes.value
        : this.endOffsetMinutes,
    endOffsetMs: endOffsetMs.present ? endOffsetMs.value : this.endOffsetMs,
    latestDurableOffsetMs: latestDurableOffsetMs ?? this.latestDurableOffsetMs,
    calibrationId: calibrationId ?? this.calibrationId,
    integrityStatus: integrityStatus ?? this.integrityStatus,
    evaluableMs: evaluableMs.present ? evaluableMs.value : this.evaluableMs,
    nonEvaluableMs: nonEvaluableMs.present
        ? nonEvaluableMs.value
        : this.nonEvaluableMs,
    pausedMs: pausedMs.present ? pausedMs.value : this.pausedMs,
    unknownMs: unknownMs.present ? unknownMs.value : this.unknownMs,
    monitoredMs: monitoredMs.present ? monitoredMs.value : this.monitoredMs,
    episodeCount: episodeCount.present ? episodeCount.value : this.episodeCount,
    warningCount: warningCount.present ? warningCount.value : this.warningCount,
    closureCount: closureCount.present ? closureCount.value : this.closureCount,
    soundsPlayed: soundsPlayed.present ? soundsPlayed.value : this.soundsPlayed,
    soundsFailed: soundsFailed.present ? soundsFailed.value : this.soundsFailed,
    pauseCount: pauseCount.present ? pauseCount.value : this.pauseCount,
  );
  DemoSessionRow copyWithCompanion(DemoSessionsCompanion data) {
    return DemoSessionRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      origin: data.origin.present ? data.origin.value : this.origin,
      sessionNumber: data.sessionNumber.present
          ? data.sessionNumber.value
          : this.sessionNumber,
      startedEpochMs: data.startedEpochMs.present
          ? data.startedEpochMs.value
          : this.startedEpochMs,
      startOffsetMinutes: data.startOffsetMinutes.present
          ? data.startOffsetMinutes.value
          : this.startOffsetMinutes,
      lifecycle: data.lifecycle.present ? data.lifecycle.value : this.lifecycle,
      endedEpochMs: data.endedEpochMs.present
          ? data.endedEpochMs.value
          : this.endedEpochMs,
      endOffsetMinutes: data.endOffsetMinutes.present
          ? data.endOffsetMinutes.value
          : this.endOffsetMinutes,
      endOffsetMs: data.endOffsetMs.present
          ? data.endOffsetMs.value
          : this.endOffsetMs,
      latestDurableOffsetMs: data.latestDurableOffsetMs.present
          ? data.latestDurableOffsetMs.value
          : this.latestDurableOffsetMs,
      calibrationId: data.calibrationId.present
          ? data.calibrationId.value
          : this.calibrationId,
      integrityStatus: data.integrityStatus.present
          ? data.integrityStatus.value
          : this.integrityStatus,
      evaluableMs: data.evaluableMs.present
          ? data.evaluableMs.value
          : this.evaluableMs,
      nonEvaluableMs: data.nonEvaluableMs.present
          ? data.nonEvaluableMs.value
          : this.nonEvaluableMs,
      pausedMs: data.pausedMs.present ? data.pausedMs.value : this.pausedMs,
      unknownMs: data.unknownMs.present ? data.unknownMs.value : this.unknownMs,
      monitoredMs: data.monitoredMs.present
          ? data.monitoredMs.value
          : this.monitoredMs,
      episodeCount: data.episodeCount.present
          ? data.episodeCount.value
          : this.episodeCount,
      warningCount: data.warningCount.present
          ? data.warningCount.value
          : this.warningCount,
      closureCount: data.closureCount.present
          ? data.closureCount.value
          : this.closureCount,
      soundsPlayed: data.soundsPlayed.present
          ? data.soundsPlayed.value
          : this.soundsPlayed,
      soundsFailed: data.soundsFailed.present
          ? data.soundsFailed.value
          : this.soundsFailed,
      pauseCount: data.pauseCount.present
          ? data.pauseCount.value
          : this.pauseCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DemoSessionRow(')
          ..write('sessionId: $sessionId, ')
          ..write('origin: $origin, ')
          ..write('sessionNumber: $sessionNumber, ')
          ..write('startedEpochMs: $startedEpochMs, ')
          ..write('startOffsetMinutes: $startOffsetMinutes, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('endedEpochMs: $endedEpochMs, ')
          ..write('endOffsetMinutes: $endOffsetMinutes, ')
          ..write('endOffsetMs: $endOffsetMs, ')
          ..write('latestDurableOffsetMs: $latestDurableOffsetMs, ')
          ..write('calibrationId: $calibrationId, ')
          ..write('integrityStatus: $integrityStatus, ')
          ..write('evaluableMs: $evaluableMs, ')
          ..write('nonEvaluableMs: $nonEvaluableMs, ')
          ..write('pausedMs: $pausedMs, ')
          ..write('unknownMs: $unknownMs, ')
          ..write('monitoredMs: $monitoredMs, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('warningCount: $warningCount, ')
          ..write('closureCount: $closureCount, ')
          ..write('soundsPlayed: $soundsPlayed, ')
          ..write('soundsFailed: $soundsFailed, ')
          ..write('pauseCount: $pauseCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    sessionId,
    origin,
    sessionNumber,
    startedEpochMs,
    startOffsetMinutes,
    lifecycle,
    endedEpochMs,
    endOffsetMinutes,
    endOffsetMs,
    latestDurableOffsetMs,
    calibrationId,
    integrityStatus,
    evaluableMs,
    nonEvaluableMs,
    pausedMs,
    unknownMs,
    monitoredMs,
    episodeCount,
    warningCount,
    closureCount,
    soundsPlayed,
    soundsFailed,
    pauseCount,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DemoSessionRow &&
          other.sessionId == this.sessionId &&
          other.origin == this.origin &&
          other.sessionNumber == this.sessionNumber &&
          other.startedEpochMs == this.startedEpochMs &&
          other.startOffsetMinutes == this.startOffsetMinutes &&
          other.lifecycle == this.lifecycle &&
          other.endedEpochMs == this.endedEpochMs &&
          other.endOffsetMinutes == this.endOffsetMinutes &&
          other.endOffsetMs == this.endOffsetMs &&
          other.latestDurableOffsetMs == this.latestDurableOffsetMs &&
          other.calibrationId == this.calibrationId &&
          other.integrityStatus == this.integrityStatus &&
          other.evaluableMs == this.evaluableMs &&
          other.nonEvaluableMs == this.nonEvaluableMs &&
          other.pausedMs == this.pausedMs &&
          other.unknownMs == this.unknownMs &&
          other.monitoredMs == this.monitoredMs &&
          other.episodeCount == this.episodeCount &&
          other.warningCount == this.warningCount &&
          other.closureCount == this.closureCount &&
          other.soundsPlayed == this.soundsPlayed &&
          other.soundsFailed == this.soundsFailed &&
          other.pauseCount == this.pauseCount);
}

class DemoSessionsCompanion extends UpdateCompanion<DemoSessionRow> {
  final Value<String> sessionId;
  final Value<String> origin;
  final Value<int> sessionNumber;
  final Value<int> startedEpochMs;
  final Value<int> startOffsetMinutes;
  final Value<String> lifecycle;
  final Value<int?> endedEpochMs;
  final Value<int?> endOffsetMinutes;
  final Value<int?> endOffsetMs;
  final Value<int> latestDurableOffsetMs;
  final Value<String> calibrationId;
  final Value<String> integrityStatus;
  final Value<int?> evaluableMs;
  final Value<int?> nonEvaluableMs;
  final Value<int?> pausedMs;
  final Value<int?> unknownMs;
  final Value<int?> monitoredMs;
  final Value<int?> episodeCount;
  final Value<int?> warningCount;
  final Value<int?> closureCount;
  final Value<int?> soundsPlayed;
  final Value<int?> soundsFailed;
  final Value<int?> pauseCount;
  final Value<int> rowid;
  const DemoSessionsCompanion({
    this.sessionId = const Value.absent(),
    this.origin = const Value.absent(),
    this.sessionNumber = const Value.absent(),
    this.startedEpochMs = const Value.absent(),
    this.startOffsetMinutes = const Value.absent(),
    this.lifecycle = const Value.absent(),
    this.endedEpochMs = const Value.absent(),
    this.endOffsetMinutes = const Value.absent(),
    this.endOffsetMs = const Value.absent(),
    this.latestDurableOffsetMs = const Value.absent(),
    this.calibrationId = const Value.absent(),
    this.integrityStatus = const Value.absent(),
    this.evaluableMs = const Value.absent(),
    this.nonEvaluableMs = const Value.absent(),
    this.pausedMs = const Value.absent(),
    this.unknownMs = const Value.absent(),
    this.monitoredMs = const Value.absent(),
    this.episodeCount = const Value.absent(),
    this.warningCount = const Value.absent(),
    this.closureCount = const Value.absent(),
    this.soundsPlayed = const Value.absent(),
    this.soundsFailed = const Value.absent(),
    this.pauseCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DemoSessionsCompanion.insert({
    required String sessionId,
    this.origin = const Value.absent(),
    required int sessionNumber,
    required int startedEpochMs,
    required int startOffsetMinutes,
    required String lifecycle,
    this.endedEpochMs = const Value.absent(),
    this.endOffsetMinutes = const Value.absent(),
    this.endOffsetMs = const Value.absent(),
    required int latestDurableOffsetMs,
    required String calibrationId,
    required String integrityStatus,
    this.evaluableMs = const Value.absent(),
    this.nonEvaluableMs = const Value.absent(),
    this.pausedMs = const Value.absent(),
    this.unknownMs = const Value.absent(),
    this.monitoredMs = const Value.absent(),
    this.episodeCount = const Value.absent(),
    this.warningCount = const Value.absent(),
    this.closureCount = const Value.absent(),
    this.soundsPlayed = const Value.absent(),
    this.soundsFailed = const Value.absent(),
    this.pauseCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       sessionNumber = Value(sessionNumber),
       startedEpochMs = Value(startedEpochMs),
       startOffsetMinutes = Value(startOffsetMinutes),
       lifecycle = Value(lifecycle),
       latestDurableOffsetMs = Value(latestDurableOffsetMs),
       calibrationId = Value(calibrationId),
       integrityStatus = Value(integrityStatus);
  static Insertable<DemoSessionRow> custom({
    Expression<String>? sessionId,
    Expression<String>? origin,
    Expression<int>? sessionNumber,
    Expression<int>? startedEpochMs,
    Expression<int>? startOffsetMinutes,
    Expression<String>? lifecycle,
    Expression<int>? endedEpochMs,
    Expression<int>? endOffsetMinutes,
    Expression<int>? endOffsetMs,
    Expression<int>? latestDurableOffsetMs,
    Expression<String>? calibrationId,
    Expression<String>? integrityStatus,
    Expression<int>? evaluableMs,
    Expression<int>? nonEvaluableMs,
    Expression<int>? pausedMs,
    Expression<int>? unknownMs,
    Expression<int>? monitoredMs,
    Expression<int>? episodeCount,
    Expression<int>? warningCount,
    Expression<int>? closureCount,
    Expression<int>? soundsPlayed,
    Expression<int>? soundsFailed,
    Expression<int>? pauseCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (origin != null) 'origin': origin,
      if (sessionNumber != null) 'session_number': sessionNumber,
      if (startedEpochMs != null) 'started_epoch_ms': startedEpochMs,
      if (startOffsetMinutes != null)
        'start_offset_minutes': startOffsetMinutes,
      if (lifecycle != null) 'lifecycle': lifecycle,
      if (endedEpochMs != null) 'ended_epoch_ms': endedEpochMs,
      if (endOffsetMinutes != null) 'end_offset_minutes': endOffsetMinutes,
      if (endOffsetMs != null) 'end_offset_ms': endOffsetMs,
      if (latestDurableOffsetMs != null)
        'latest_durable_offset_ms': latestDurableOffsetMs,
      if (calibrationId != null) 'calibration_id': calibrationId,
      if (integrityStatus != null) 'integrity_status': integrityStatus,
      if (evaluableMs != null) 'evaluable_ms': evaluableMs,
      if (nonEvaluableMs != null) 'non_evaluable_ms': nonEvaluableMs,
      if (pausedMs != null) 'paused_ms': pausedMs,
      if (unknownMs != null) 'unknown_ms': unknownMs,
      if (monitoredMs != null) 'monitored_ms': monitoredMs,
      if (episodeCount != null) 'episode_count': episodeCount,
      if (warningCount != null) 'warning_count': warningCount,
      if (closureCount != null) 'closure_count': closureCount,
      if (soundsPlayed != null) 'sounds_played': soundsPlayed,
      if (soundsFailed != null) 'sounds_failed': soundsFailed,
      if (pauseCount != null) 'pause_count': pauseCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DemoSessionsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? origin,
    Value<int>? sessionNumber,
    Value<int>? startedEpochMs,
    Value<int>? startOffsetMinutes,
    Value<String>? lifecycle,
    Value<int?>? endedEpochMs,
    Value<int?>? endOffsetMinutes,
    Value<int?>? endOffsetMs,
    Value<int>? latestDurableOffsetMs,
    Value<String>? calibrationId,
    Value<String>? integrityStatus,
    Value<int?>? evaluableMs,
    Value<int?>? nonEvaluableMs,
    Value<int?>? pausedMs,
    Value<int?>? unknownMs,
    Value<int?>? monitoredMs,
    Value<int?>? episodeCount,
    Value<int?>? warningCount,
    Value<int?>? closureCount,
    Value<int?>? soundsPlayed,
    Value<int?>? soundsFailed,
    Value<int?>? pauseCount,
    Value<int>? rowid,
  }) {
    return DemoSessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      origin: origin ?? this.origin,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      startedEpochMs: startedEpochMs ?? this.startedEpochMs,
      startOffsetMinutes: startOffsetMinutes ?? this.startOffsetMinutes,
      lifecycle: lifecycle ?? this.lifecycle,
      endedEpochMs: endedEpochMs ?? this.endedEpochMs,
      endOffsetMinutes: endOffsetMinutes ?? this.endOffsetMinutes,
      endOffsetMs: endOffsetMs ?? this.endOffsetMs,
      latestDurableOffsetMs:
          latestDurableOffsetMs ?? this.latestDurableOffsetMs,
      calibrationId: calibrationId ?? this.calibrationId,
      integrityStatus: integrityStatus ?? this.integrityStatus,
      evaluableMs: evaluableMs ?? this.evaluableMs,
      nonEvaluableMs: nonEvaluableMs ?? this.nonEvaluableMs,
      pausedMs: pausedMs ?? this.pausedMs,
      unknownMs: unknownMs ?? this.unknownMs,
      monitoredMs: monitoredMs ?? this.monitoredMs,
      episodeCount: episodeCount ?? this.episodeCount,
      warningCount: warningCount ?? this.warningCount,
      closureCount: closureCount ?? this.closureCount,
      soundsPlayed: soundsPlayed ?? this.soundsPlayed,
      soundsFailed: soundsFailed ?? this.soundsFailed,
      pauseCount: pauseCount ?? this.pauseCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (sessionNumber.present) {
      map['session_number'] = Variable<int>(sessionNumber.value);
    }
    if (startedEpochMs.present) {
      map['started_epoch_ms'] = Variable<int>(startedEpochMs.value);
    }
    if (startOffsetMinutes.present) {
      map['start_offset_minutes'] = Variable<int>(startOffsetMinutes.value);
    }
    if (lifecycle.present) {
      map['lifecycle'] = Variable<String>(lifecycle.value);
    }
    if (endedEpochMs.present) {
      map['ended_epoch_ms'] = Variable<int>(endedEpochMs.value);
    }
    if (endOffsetMinutes.present) {
      map['end_offset_minutes'] = Variable<int>(endOffsetMinutes.value);
    }
    if (endOffsetMs.present) {
      map['end_offset_ms'] = Variable<int>(endOffsetMs.value);
    }
    if (latestDurableOffsetMs.present) {
      map['latest_durable_offset_ms'] = Variable<int>(
        latestDurableOffsetMs.value,
      );
    }
    if (calibrationId.present) {
      map['calibration_id'] = Variable<String>(calibrationId.value);
    }
    if (integrityStatus.present) {
      map['integrity_status'] = Variable<String>(integrityStatus.value);
    }
    if (evaluableMs.present) {
      map['evaluable_ms'] = Variable<int>(evaluableMs.value);
    }
    if (nonEvaluableMs.present) {
      map['non_evaluable_ms'] = Variable<int>(nonEvaluableMs.value);
    }
    if (pausedMs.present) {
      map['paused_ms'] = Variable<int>(pausedMs.value);
    }
    if (unknownMs.present) {
      map['unknown_ms'] = Variable<int>(unknownMs.value);
    }
    if (monitoredMs.present) {
      map['monitored_ms'] = Variable<int>(monitoredMs.value);
    }
    if (episodeCount.present) {
      map['episode_count'] = Variable<int>(episodeCount.value);
    }
    if (warningCount.present) {
      map['warning_count'] = Variable<int>(warningCount.value);
    }
    if (closureCount.present) {
      map['closure_count'] = Variable<int>(closureCount.value);
    }
    if (soundsPlayed.present) {
      map['sounds_played'] = Variable<int>(soundsPlayed.value);
    }
    if (soundsFailed.present) {
      map['sounds_failed'] = Variable<int>(soundsFailed.value);
    }
    if (pauseCount.present) {
      map['pause_count'] = Variable<int>(pauseCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DemoSessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('origin: $origin, ')
          ..write('sessionNumber: $sessionNumber, ')
          ..write('startedEpochMs: $startedEpochMs, ')
          ..write('startOffsetMinutes: $startOffsetMinutes, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('endedEpochMs: $endedEpochMs, ')
          ..write('endOffsetMinutes: $endOffsetMinutes, ')
          ..write('endOffsetMs: $endOffsetMs, ')
          ..write('latestDurableOffsetMs: $latestDurableOffsetMs, ')
          ..write('calibrationId: $calibrationId, ')
          ..write('integrityStatus: $integrityStatus, ')
          ..write('evaluableMs: $evaluableMs, ')
          ..write('nonEvaluableMs: $nonEvaluableMs, ')
          ..write('pausedMs: $pausedMs, ')
          ..write('unknownMs: $unknownMs, ')
          ..write('monitoredMs: $monitoredMs, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('warningCount: $warningCount, ')
          ..write('closureCount: $closureCount, ')
          ..write('soundsPlayed: $soundsPlayed, ')
          ..write('soundsFailed: $soundsFailed, ')
          ..write('pauseCount: $pauseCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DemoSessionEventsTable extends DemoSessionEvents
    with TableInfo<$DemoSessionEventsTable, DemoEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DemoSessionEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES demo_sessions (session_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    check: () => ComparableExpr(sequence).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _offsetMsMeta = const VerificationMeta(
    'offsetMs',
  );
  @override
  late final GeneratedColumn<int> offsetMs = GeneratedColumn<int>(
    'offset_ms',
    aliasedName,
    false,
    check: () => ComparableExpr(offsetMs).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measurementMeta = const VerificationMeta(
    'measurement',
  );
  @override
  late final GeneratedColumn<String> measurement = GeneratedColumn<String>(
    'measurement',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signalMeta = const VerificationMeta('signal');
  @override
  late final GeneratedColumn<String> signal = GeneratedColumn<String>(
    'signal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
    'episode_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeKindMeta = const VerificationMeta(
    'episodeKind',
  );
  @override
  late final GeneratedColumn<String> episodeKind = GeneratedColumn<String>(
    'episode_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    sequence,
    type,
    offsetMs,
    measurement,
    signal,
    episodeId,
    episodeKind,
    detail,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'demo_session_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<DemoEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('offset_ms')) {
      context.handle(
        _offsetMsMeta,
        offsetMs.isAcceptableOrUnknown(data['offset_ms']!, _offsetMsMeta),
      );
    } else if (isInserting) {
      context.missing(_offsetMsMeta);
    }
    if (data.containsKey('measurement')) {
      context.handle(
        _measurementMeta,
        measurement.isAcceptableOrUnknown(
          data['measurement']!,
          _measurementMeta,
        ),
      );
    }
    if (data.containsKey('signal')) {
      context.handle(
        _signalMeta,
        signal.isAcceptableOrUnknown(data['signal']!, _signalMeta),
      );
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    }
    if (data.containsKey('episode_kind')) {
      context.handle(
        _episodeKindMeta,
        episodeKind.isAcceptableOrUnknown(
          data['episode_kind']!,
          _episodeKindMeta,
        ),
      );
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, sequence};
  @override
  DemoEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DemoEventRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      offsetMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_ms'],
      )!,
      measurement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement'],
      ),
      signal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signal'],
      ),
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_id'],
      ),
      episodeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_kind'],
      ),
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
    );
  }

  @override
  $DemoSessionEventsTable createAlias(String alias) {
    return $DemoSessionEventsTable(attachedDatabase, alias);
  }
}

class DemoEventRow extends DataClass implements Insertable<DemoEventRow> {
  final String sessionId;
  final int sequence;
  final String type;
  final int offsetMs;
  final String? measurement;
  final String? signal;
  final String? episodeId;
  final String? episodeKind;
  final String? detail;
  const DemoEventRow({
    required this.sessionId,
    required this.sequence,
    required this.type,
    required this.offsetMs,
    this.measurement,
    this.signal,
    this.episodeId,
    this.episodeKind,
    this.detail,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['sequence'] = Variable<int>(sequence);
    map['type'] = Variable<String>(type);
    map['offset_ms'] = Variable<int>(offsetMs);
    if (!nullToAbsent || measurement != null) {
      map['measurement'] = Variable<String>(measurement);
    }
    if (!nullToAbsent || signal != null) {
      map['signal'] = Variable<String>(signal);
    }
    if (!nullToAbsent || episodeId != null) {
      map['episode_id'] = Variable<String>(episodeId);
    }
    if (!nullToAbsent || episodeKind != null) {
      map['episode_kind'] = Variable<String>(episodeKind);
    }
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    return map;
  }

  DemoSessionEventsCompanion toCompanion(bool nullToAbsent) {
    return DemoSessionEventsCompanion(
      sessionId: Value(sessionId),
      sequence: Value(sequence),
      type: Value(type),
      offsetMs: Value(offsetMs),
      measurement: measurement == null && nullToAbsent
          ? const Value.absent()
          : Value(measurement),
      signal: signal == null && nullToAbsent
          ? const Value.absent()
          : Value(signal),
      episodeId: episodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeId),
      episodeKind: episodeKind == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeKind),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
    );
  }

  factory DemoEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DemoEventRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      type: serializer.fromJson<String>(json['type']),
      offsetMs: serializer.fromJson<int>(json['offsetMs']),
      measurement: serializer.fromJson<String?>(json['measurement']),
      signal: serializer.fromJson<String?>(json['signal']),
      episodeId: serializer.fromJson<String?>(json['episodeId']),
      episodeKind: serializer.fromJson<String?>(json['episodeKind']),
      detail: serializer.fromJson<String?>(json['detail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'sequence': serializer.toJson<int>(sequence),
      'type': serializer.toJson<String>(type),
      'offsetMs': serializer.toJson<int>(offsetMs),
      'measurement': serializer.toJson<String?>(measurement),
      'signal': serializer.toJson<String?>(signal),
      'episodeId': serializer.toJson<String?>(episodeId),
      'episodeKind': serializer.toJson<String?>(episodeKind),
      'detail': serializer.toJson<String?>(detail),
    };
  }

  DemoEventRow copyWith({
    String? sessionId,
    int? sequence,
    String? type,
    int? offsetMs,
    Value<String?> measurement = const Value.absent(),
    Value<String?> signal = const Value.absent(),
    Value<String?> episodeId = const Value.absent(),
    Value<String?> episodeKind = const Value.absent(),
    Value<String?> detail = const Value.absent(),
  }) => DemoEventRow(
    sessionId: sessionId ?? this.sessionId,
    sequence: sequence ?? this.sequence,
    type: type ?? this.type,
    offsetMs: offsetMs ?? this.offsetMs,
    measurement: measurement.present ? measurement.value : this.measurement,
    signal: signal.present ? signal.value : this.signal,
    episodeId: episodeId.present ? episodeId.value : this.episodeId,
    episodeKind: episodeKind.present ? episodeKind.value : this.episodeKind,
    detail: detail.present ? detail.value : this.detail,
  );
  DemoEventRow copyWithCompanion(DemoSessionEventsCompanion data) {
    return DemoEventRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      type: data.type.present ? data.type.value : this.type,
      offsetMs: data.offsetMs.present ? data.offsetMs.value : this.offsetMs,
      measurement: data.measurement.present
          ? data.measurement.value
          : this.measurement,
      signal: data.signal.present ? data.signal.value : this.signal,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      episodeKind: data.episodeKind.present
          ? data.episodeKind.value
          : this.episodeKind,
      detail: data.detail.present ? data.detail.value : this.detail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DemoEventRow(')
          ..write('sessionId: $sessionId, ')
          ..write('sequence: $sequence, ')
          ..write('type: $type, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('measurement: $measurement, ')
          ..write('signal: $signal, ')
          ..write('episodeId: $episodeId, ')
          ..write('episodeKind: $episodeKind, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    sequence,
    type,
    offsetMs,
    measurement,
    signal,
    episodeId,
    episodeKind,
    detail,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DemoEventRow &&
          other.sessionId == this.sessionId &&
          other.sequence == this.sequence &&
          other.type == this.type &&
          other.offsetMs == this.offsetMs &&
          other.measurement == this.measurement &&
          other.signal == this.signal &&
          other.episodeId == this.episodeId &&
          other.episodeKind == this.episodeKind &&
          other.detail == this.detail);
}

class DemoSessionEventsCompanion extends UpdateCompanion<DemoEventRow> {
  final Value<String> sessionId;
  final Value<int> sequence;
  final Value<String> type;
  final Value<int> offsetMs;
  final Value<String?> measurement;
  final Value<String?> signal;
  final Value<String?> episodeId;
  final Value<String?> episodeKind;
  final Value<String?> detail;
  final Value<int> rowid;
  const DemoSessionEventsCompanion({
    this.sessionId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.type = const Value.absent(),
    this.offsetMs = const Value.absent(),
    this.measurement = const Value.absent(),
    this.signal = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.episodeKind = const Value.absent(),
    this.detail = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DemoSessionEventsCompanion.insert({
    required String sessionId,
    required int sequence,
    required String type,
    required int offsetMs,
    this.measurement = const Value.absent(),
    this.signal = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.episodeKind = const Value.absent(),
    this.detail = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       sequence = Value(sequence),
       type = Value(type),
       offsetMs = Value(offsetMs);
  static Insertable<DemoEventRow> custom({
    Expression<String>? sessionId,
    Expression<int>? sequence,
    Expression<String>? type,
    Expression<int>? offsetMs,
    Expression<String>? measurement,
    Expression<String>? signal,
    Expression<String>? episodeId,
    Expression<String>? episodeKind,
    Expression<String>? detail,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (sequence != null) 'sequence': sequence,
      if (type != null) 'type': type,
      if (offsetMs != null) 'offset_ms': offsetMs,
      if (measurement != null) 'measurement': measurement,
      if (signal != null) 'signal': signal,
      if (episodeId != null) 'episode_id': episodeId,
      if (episodeKind != null) 'episode_kind': episodeKind,
      if (detail != null) 'detail': detail,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DemoSessionEventsCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? sequence,
    Value<String>? type,
    Value<int>? offsetMs,
    Value<String?>? measurement,
    Value<String?>? signal,
    Value<String?>? episodeId,
    Value<String?>? episodeKind,
    Value<String?>? detail,
    Value<int>? rowid,
  }) {
    return DemoSessionEventsCompanion(
      sessionId: sessionId ?? this.sessionId,
      sequence: sequence ?? this.sequence,
      type: type ?? this.type,
      offsetMs: offsetMs ?? this.offsetMs,
      measurement: measurement ?? this.measurement,
      signal: signal ?? this.signal,
      episodeId: episodeId ?? this.episodeId,
      episodeKind: episodeKind ?? this.episodeKind,
      detail: detail ?? this.detail,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (offsetMs.present) {
      map['offset_ms'] = Variable<int>(offsetMs.value);
    }
    if (measurement.present) {
      map['measurement'] = Variable<String>(measurement.value);
    }
    if (signal.present) {
      map['signal'] = Variable<String>(signal.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (episodeKind.present) {
      map['episode_kind'] = Variable<String>(episodeKind.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DemoSessionEventsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('sequence: $sequence, ')
          ..write('type: $type, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('measurement: $measurement, ')
          ..write('signal: $signal, ')
          ..write('episodeId: $episodeId, ')
          ..write('episodeKind: $episodeKind, ')
          ..write('detail: $detail, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, PreferencesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonMeta = const VerificationMeta(
    'singleton',
  );
  @override
  late final GeneratedColumn<int> singleton = GeneratedColumn<int>(
    'singleton',
    aliasedName,
    false,
    check: () => singleton.equals(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    check: () => theme.isIn(const ['system', 'light', 'dark']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _soundPatternIdMeta = const VerificationMeta(
    'soundPatternId',
  );
  @override
  late final GeneratedColumn<String> soundPatternId = GeneratedColumn<String>(
    'sound_pattern_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reducedMotionMeta = const VerificationMeta(
    'reducedMotion',
  );
  @override
  late final GeneratedColumn<bool> reducedMotion = GeneratedColumn<bool>(
    'reduced_motion',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reduced_motion" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedEpochMsMeta = const VerificationMeta(
    'updatedEpochMs',
  );
  @override
  late final GeneratedColumn<int> updatedEpochMs = GeneratedColumn<int>(
    'updated_epoch_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    singleton,
    theme,
    soundPatternId,
    reducedMotion,
    updatedEpochMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferencesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton')) {
      context.handle(
        _singletonMeta,
        singleton.isAcceptableOrUnknown(data['singleton']!, _singletonMeta),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeMeta);
    }
    if (data.containsKey('sound_pattern_id')) {
      context.handle(
        _soundPatternIdMeta,
        soundPatternId.isAcceptableOrUnknown(
          data['sound_pattern_id']!,
          _soundPatternIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_soundPatternIdMeta);
    }
    if (data.containsKey('reduced_motion')) {
      context.handle(
        _reducedMotionMeta,
        reducedMotion.isAcceptableOrUnknown(
          data['reduced_motion']!,
          _reducedMotionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reducedMotionMeta);
    }
    if (data.containsKey('updated_epoch_ms')) {
      context.handle(
        _updatedEpochMsMeta,
        updatedEpochMs.isAcceptableOrUnknown(
          data['updated_epoch_ms']!,
          _updatedEpochMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedEpochMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singleton};
  @override
  PreferencesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferencesRow(
      singleton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      soundPatternId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_pattern_id'],
      )!,
      reducedMotion: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reduced_motion'],
      )!,
      updatedEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_epoch_ms'],
      )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class PreferencesRow extends DataClass implements Insertable<PreferencesRow> {
  final int singleton;
  final String theme;
  final String soundPatternId;
  final bool reducedMotion;
  final int updatedEpochMs;
  const PreferencesRow({
    required this.singleton,
    required this.theme,
    required this.soundPatternId,
    required this.reducedMotion,
    required this.updatedEpochMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton'] = Variable<int>(singleton);
    map['theme'] = Variable<String>(theme);
    map['sound_pattern_id'] = Variable<String>(soundPatternId);
    map['reduced_motion'] = Variable<bool>(reducedMotion);
    map['updated_epoch_ms'] = Variable<int>(updatedEpochMs);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(
      singleton: Value(singleton),
      theme: Value(theme),
      soundPatternId: Value(soundPatternId),
      reducedMotion: Value(reducedMotion),
      updatedEpochMs: Value(updatedEpochMs),
    );
  }

  factory PreferencesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferencesRow(
      singleton: serializer.fromJson<int>(json['singleton']),
      theme: serializer.fromJson<String>(json['theme']),
      soundPatternId: serializer.fromJson<String>(json['soundPatternId']),
      reducedMotion: serializer.fromJson<bool>(json['reducedMotion']),
      updatedEpochMs: serializer.fromJson<int>(json['updatedEpochMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singleton': serializer.toJson<int>(singleton),
      'theme': serializer.toJson<String>(theme),
      'soundPatternId': serializer.toJson<String>(soundPatternId),
      'reducedMotion': serializer.toJson<bool>(reducedMotion),
      'updatedEpochMs': serializer.toJson<int>(updatedEpochMs),
    };
  }

  PreferencesRow copyWith({
    int? singleton,
    String? theme,
    String? soundPatternId,
    bool? reducedMotion,
    int? updatedEpochMs,
  }) => PreferencesRow(
    singleton: singleton ?? this.singleton,
    theme: theme ?? this.theme,
    soundPatternId: soundPatternId ?? this.soundPatternId,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    updatedEpochMs: updatedEpochMs ?? this.updatedEpochMs,
  );
  PreferencesRow copyWithCompanion(PreferencesCompanion data) {
    return PreferencesRow(
      singleton: data.singleton.present ? data.singleton.value : this.singleton,
      theme: data.theme.present ? data.theme.value : this.theme,
      soundPatternId: data.soundPatternId.present
          ? data.soundPatternId.value
          : this.soundPatternId,
      reducedMotion: data.reducedMotion.present
          ? data.reducedMotion.value
          : this.reducedMotion,
      updatedEpochMs: data.updatedEpochMs.present
          ? data.updatedEpochMs.value
          : this.updatedEpochMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesRow(')
          ..write('singleton: $singleton, ')
          ..write('theme: $theme, ')
          ..write('soundPatternId: $soundPatternId, ')
          ..write('reducedMotion: $reducedMotion, ')
          ..write('updatedEpochMs: $updatedEpochMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    singleton,
    theme,
    soundPatternId,
    reducedMotion,
    updatedEpochMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferencesRow &&
          other.singleton == this.singleton &&
          other.theme == this.theme &&
          other.soundPatternId == this.soundPatternId &&
          other.reducedMotion == this.reducedMotion &&
          other.updatedEpochMs == this.updatedEpochMs);
}

class PreferencesCompanion extends UpdateCompanion<PreferencesRow> {
  final Value<int> singleton;
  final Value<String> theme;
  final Value<String> soundPatternId;
  final Value<bool> reducedMotion;
  final Value<int> updatedEpochMs;
  const PreferencesCompanion({
    this.singleton = const Value.absent(),
    this.theme = const Value.absent(),
    this.soundPatternId = const Value.absent(),
    this.reducedMotion = const Value.absent(),
    this.updatedEpochMs = const Value.absent(),
  });
  PreferencesCompanion.insert({
    this.singleton = const Value.absent(),
    required String theme,
    required String soundPatternId,
    required bool reducedMotion,
    required int updatedEpochMs,
  }) : theme = Value(theme),
       soundPatternId = Value(soundPatternId),
       reducedMotion = Value(reducedMotion),
       updatedEpochMs = Value(updatedEpochMs);
  static Insertable<PreferencesRow> custom({
    Expression<int>? singleton,
    Expression<String>? theme,
    Expression<String>? soundPatternId,
    Expression<bool>? reducedMotion,
    Expression<int>? updatedEpochMs,
  }) {
    return RawValuesInsertable({
      if (singleton != null) 'singleton': singleton,
      if (theme != null) 'theme': theme,
      if (soundPatternId != null) 'sound_pattern_id': soundPatternId,
      if (reducedMotion != null) 'reduced_motion': reducedMotion,
      if (updatedEpochMs != null) 'updated_epoch_ms': updatedEpochMs,
    });
  }

  PreferencesCompanion copyWith({
    Value<int>? singleton,
    Value<String>? theme,
    Value<String>? soundPatternId,
    Value<bool>? reducedMotion,
    Value<int>? updatedEpochMs,
  }) {
    return PreferencesCompanion(
      singleton: singleton ?? this.singleton,
      theme: theme ?? this.theme,
      soundPatternId: soundPatternId ?? this.soundPatternId,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      updatedEpochMs: updatedEpochMs ?? this.updatedEpochMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singleton.present) {
      map['singleton'] = Variable<int>(singleton.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (soundPatternId.present) {
      map['sound_pattern_id'] = Variable<String>(soundPatternId.value);
    }
    if (reducedMotion.present) {
      map['reduced_motion'] = Variable<bool>(reducedMotion.value);
    }
    if (updatedEpochMs.present) {
      map['updated_epoch_ms'] = Variable<int>(updatedEpochMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('singleton: $singleton, ')
          ..write('theme: $theme, ')
          ..write('soundPatternId: $soundPatternId, ')
          ..write('reducedMotion: $reducedMotion, ')
          ..write('updatedEpochMs: $updatedEpochMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$DemoHistoryDatabase extends GeneratedDatabase {
  _$DemoHistoryDatabase(QueryExecutor e) : super(e);
  $DemoHistoryDatabaseManager get managers => $DemoHistoryDatabaseManager(this);
  late final $DemoSessionsTable demoSessions = $DemoSessionsTable(this);
  late final $DemoSessionEventsTable demoSessionEvents =
      $DemoSessionEventsTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    demoSessions,
    demoSessionEvents,
    preferences,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'demo_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('demo_session_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DemoSessionsTableCreateCompanionBuilder =
    DemoSessionsCompanion Function({
      required String sessionId,
      Value<String> origin,
      required int sessionNumber,
      required int startedEpochMs,
      required int startOffsetMinutes,
      required String lifecycle,
      Value<int?> endedEpochMs,
      Value<int?> endOffsetMinutes,
      Value<int?> endOffsetMs,
      required int latestDurableOffsetMs,
      required String calibrationId,
      required String integrityStatus,
      Value<int?> evaluableMs,
      Value<int?> nonEvaluableMs,
      Value<int?> pausedMs,
      Value<int?> unknownMs,
      Value<int?> monitoredMs,
      Value<int?> episodeCount,
      Value<int?> warningCount,
      Value<int?> closureCount,
      Value<int?> soundsPlayed,
      Value<int?> soundsFailed,
      Value<int?> pauseCount,
      Value<int> rowid,
    });
typedef $$DemoSessionsTableUpdateCompanionBuilder =
    DemoSessionsCompanion Function({
      Value<String> sessionId,
      Value<String> origin,
      Value<int> sessionNumber,
      Value<int> startedEpochMs,
      Value<int> startOffsetMinutes,
      Value<String> lifecycle,
      Value<int?> endedEpochMs,
      Value<int?> endOffsetMinutes,
      Value<int?> endOffsetMs,
      Value<int> latestDurableOffsetMs,
      Value<String> calibrationId,
      Value<String> integrityStatus,
      Value<int?> evaluableMs,
      Value<int?> nonEvaluableMs,
      Value<int?> pausedMs,
      Value<int?> unknownMs,
      Value<int?> monitoredMs,
      Value<int?> episodeCount,
      Value<int?> warningCount,
      Value<int?> closureCount,
      Value<int?> soundsPlayed,
      Value<int?> soundsFailed,
      Value<int?> pauseCount,
      Value<int> rowid,
    });

final class $$DemoSessionsTableReferences
    extends
        BaseReferences<
          _$DemoHistoryDatabase,
          $DemoSessionsTable,
          DemoSessionRow
        > {
  $$DemoSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DemoSessionEventsTable, List<DemoEventRow>>
  _demoSessionEventsRefsTable(_$DemoHistoryDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.demoSessionEvents,
        aliasName: 'demo_sessions__session_id__demo_session_events__session_id',
      );

  $$DemoSessionEventsTableProcessedTableManager get demoSessionEventsRefs {
    final manager =
        $$DemoSessionEventsTableTableManager(
          $_db,
          $_db.demoSessionEvents,
        ).filter(
          (f) => f.sessionId.sessionId.sqlEquals(
            $_itemColumn<String>('session_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _demoSessionEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DemoSessionsTableFilterComposer
    extends Composer<_$DemoHistoryDatabase, $DemoSessionsTable> {
  $$DemoSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionNumber => $composableBuilder(
    column: $table.sessionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedEpochMs => $composableBuilder(
    column: $table.startedEpochMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startOffsetMinutes => $composableBuilder(
    column: $table.startOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lifecycle => $composableBuilder(
    column: $table.lifecycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedEpochMs => $composableBuilder(
    column: $table.endedEpochMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endOffsetMinutes => $composableBuilder(
    column: $table.endOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endOffsetMs => $composableBuilder(
    column: $table.endOffsetMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latestDurableOffsetMs => $composableBuilder(
    column: $table.latestDurableOffsetMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calibrationId => $composableBuilder(
    column: $table.calibrationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get integrityStatus => $composableBuilder(
    column: $table.integrityStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get evaluableMs => $composableBuilder(
    column: $table.evaluableMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nonEvaluableMs => $composableBuilder(
    column: $table.nonEvaluableMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedMs => $composableBuilder(
    column: $table.pausedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unknownMs => $composableBuilder(
    column: $table.unknownMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monitoredMs => $composableBuilder(
    column: $table.monitoredMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeCount => $composableBuilder(
    column: $table.episodeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warningCount => $composableBuilder(
    column: $table.warningCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closureCount => $composableBuilder(
    column: $table.closureCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get soundsPlayed => $composableBuilder(
    column: $table.soundsPlayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get soundsFailed => $composableBuilder(
    column: $table.soundsFailed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> demoSessionEventsRefs(
    Expression<bool> Function($$DemoSessionEventsTableFilterComposer f) f,
  ) {
    final $$DemoSessionEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.demoSessionEvents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DemoSessionEventsTableFilterComposer(
            $db: $db,
            $table: $db.demoSessionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DemoSessionsTableOrderingComposer
    extends Composer<_$DemoHistoryDatabase, $DemoSessionsTable> {
  $$DemoSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionNumber => $composableBuilder(
    column: $table.sessionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedEpochMs => $composableBuilder(
    column: $table.startedEpochMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startOffsetMinutes => $composableBuilder(
    column: $table.startOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lifecycle => $composableBuilder(
    column: $table.lifecycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedEpochMs => $composableBuilder(
    column: $table.endedEpochMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endOffsetMinutes => $composableBuilder(
    column: $table.endOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endOffsetMs => $composableBuilder(
    column: $table.endOffsetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latestDurableOffsetMs => $composableBuilder(
    column: $table.latestDurableOffsetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calibrationId => $composableBuilder(
    column: $table.calibrationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get integrityStatus => $composableBuilder(
    column: $table.integrityStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get evaluableMs => $composableBuilder(
    column: $table.evaluableMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nonEvaluableMs => $composableBuilder(
    column: $table.nonEvaluableMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedMs => $composableBuilder(
    column: $table.pausedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unknownMs => $composableBuilder(
    column: $table.unknownMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monitoredMs => $composableBuilder(
    column: $table.monitoredMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeCount => $composableBuilder(
    column: $table.episodeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warningCount => $composableBuilder(
    column: $table.warningCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closureCount => $composableBuilder(
    column: $table.closureCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get soundsPlayed => $composableBuilder(
    column: $table.soundsPlayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get soundsFailed => $composableBuilder(
    column: $table.soundsFailed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DemoSessionsTableAnnotationComposer
    extends Composer<_$DemoHistoryDatabase, $DemoSessionsTable> {
  $$DemoSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<int> get sessionNumber => $composableBuilder(
    column: $table.sessionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedEpochMs => $composableBuilder(
    column: $table.startedEpochMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startOffsetMinutes => $composableBuilder(
    column: $table.startOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lifecycle =>
      $composableBuilder(column: $table.lifecycle, builder: (column) => column);

  GeneratedColumn<int> get endedEpochMs => $composableBuilder(
    column: $table.endedEpochMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endOffsetMinutes => $composableBuilder(
    column: $table.endOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endOffsetMs => $composableBuilder(
    column: $table.endOffsetMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latestDurableOffsetMs => $composableBuilder(
    column: $table.latestDurableOffsetMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calibrationId => $composableBuilder(
    column: $table.calibrationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get integrityStatus => $composableBuilder(
    column: $table.integrityStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get evaluableMs => $composableBuilder(
    column: $table.evaluableMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nonEvaluableMs => $composableBuilder(
    column: $table.nonEvaluableMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pausedMs =>
      $composableBuilder(column: $table.pausedMs, builder: (column) => column);

  GeneratedColumn<int> get unknownMs =>
      $composableBuilder(column: $table.unknownMs, builder: (column) => column);

  GeneratedColumn<int> get monitoredMs => $composableBuilder(
    column: $table.monitoredMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeCount => $composableBuilder(
    column: $table.episodeCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warningCount => $composableBuilder(
    column: $table.warningCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get closureCount => $composableBuilder(
    column: $table.closureCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get soundsPlayed => $composableBuilder(
    column: $table.soundsPlayed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get soundsFailed => $composableBuilder(
    column: $table.soundsFailed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => column,
  );

  Expression<T> demoSessionEventsRefs<T extends Object>(
    Expression<T> Function($$DemoSessionEventsTableAnnotationComposer a) f,
  ) {
    final $$DemoSessionEventsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionId,
          referencedTable: $db.demoSessionEvents,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DemoSessionEventsTableAnnotationComposer(
                $db: $db,
                $table: $db.demoSessionEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DemoSessionsTableTableManager
    extends
        RootTableManager<
          _$DemoHistoryDatabase,
          $DemoSessionsTable,
          DemoSessionRow,
          $$DemoSessionsTableFilterComposer,
          $$DemoSessionsTableOrderingComposer,
          $$DemoSessionsTableAnnotationComposer,
          $$DemoSessionsTableCreateCompanionBuilder,
          $$DemoSessionsTableUpdateCompanionBuilder,
          (DemoSessionRow, $$DemoSessionsTableReferences),
          DemoSessionRow,
          PrefetchHooks Function({bool demoSessionEventsRefs})
        > {
  $$DemoSessionsTableTableManager(
    _$DemoHistoryDatabase db,
    $DemoSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DemoSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DemoSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DemoSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<int> sessionNumber = const Value.absent(),
                Value<int> startedEpochMs = const Value.absent(),
                Value<int> startOffsetMinutes = const Value.absent(),
                Value<String> lifecycle = const Value.absent(),
                Value<int?> endedEpochMs = const Value.absent(),
                Value<int?> endOffsetMinutes = const Value.absent(),
                Value<int?> endOffsetMs = const Value.absent(),
                Value<int> latestDurableOffsetMs = const Value.absent(),
                Value<String> calibrationId = const Value.absent(),
                Value<String> integrityStatus = const Value.absent(),
                Value<int?> evaluableMs = const Value.absent(),
                Value<int?> nonEvaluableMs = const Value.absent(),
                Value<int?> pausedMs = const Value.absent(),
                Value<int?> unknownMs = const Value.absent(),
                Value<int?> monitoredMs = const Value.absent(),
                Value<int?> episodeCount = const Value.absent(),
                Value<int?> warningCount = const Value.absent(),
                Value<int?> closureCount = const Value.absent(),
                Value<int?> soundsPlayed = const Value.absent(),
                Value<int?> soundsFailed = const Value.absent(),
                Value<int?> pauseCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DemoSessionsCompanion(
                sessionId: sessionId,
                origin: origin,
                sessionNumber: sessionNumber,
                startedEpochMs: startedEpochMs,
                startOffsetMinutes: startOffsetMinutes,
                lifecycle: lifecycle,
                endedEpochMs: endedEpochMs,
                endOffsetMinutes: endOffsetMinutes,
                endOffsetMs: endOffsetMs,
                latestDurableOffsetMs: latestDurableOffsetMs,
                calibrationId: calibrationId,
                integrityStatus: integrityStatus,
                evaluableMs: evaluableMs,
                nonEvaluableMs: nonEvaluableMs,
                pausedMs: pausedMs,
                unknownMs: unknownMs,
                monitoredMs: monitoredMs,
                episodeCount: episodeCount,
                warningCount: warningCount,
                closureCount: closureCount,
                soundsPlayed: soundsPlayed,
                soundsFailed: soundsFailed,
                pauseCount: pauseCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                Value<String> origin = const Value.absent(),
                required int sessionNumber,
                required int startedEpochMs,
                required int startOffsetMinutes,
                required String lifecycle,
                Value<int?> endedEpochMs = const Value.absent(),
                Value<int?> endOffsetMinutes = const Value.absent(),
                Value<int?> endOffsetMs = const Value.absent(),
                required int latestDurableOffsetMs,
                required String calibrationId,
                required String integrityStatus,
                Value<int?> evaluableMs = const Value.absent(),
                Value<int?> nonEvaluableMs = const Value.absent(),
                Value<int?> pausedMs = const Value.absent(),
                Value<int?> unknownMs = const Value.absent(),
                Value<int?> monitoredMs = const Value.absent(),
                Value<int?> episodeCount = const Value.absent(),
                Value<int?> warningCount = const Value.absent(),
                Value<int?> closureCount = const Value.absent(),
                Value<int?> soundsPlayed = const Value.absent(),
                Value<int?> soundsFailed = const Value.absent(),
                Value<int?> pauseCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DemoSessionsCompanion.insert(
                sessionId: sessionId,
                origin: origin,
                sessionNumber: sessionNumber,
                startedEpochMs: startedEpochMs,
                startOffsetMinutes: startOffsetMinutes,
                lifecycle: lifecycle,
                endedEpochMs: endedEpochMs,
                endOffsetMinutes: endOffsetMinutes,
                endOffsetMs: endOffsetMs,
                latestDurableOffsetMs: latestDurableOffsetMs,
                calibrationId: calibrationId,
                integrityStatus: integrityStatus,
                evaluableMs: evaluableMs,
                nonEvaluableMs: nonEvaluableMs,
                pausedMs: pausedMs,
                unknownMs: unknownMs,
                monitoredMs: monitoredMs,
                episodeCount: episodeCount,
                warningCount: warningCount,
                closureCount: closureCount,
                soundsPlayed: soundsPlayed,
                soundsFailed: soundsFailed,
                pauseCount: pauseCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DemoSessionsTable, DemoSessionRow>(table),
                  $$DemoSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({demoSessionEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (demoSessionEventsRefs) db.demoSessionEvents,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (demoSessionEventsRefs)
                    await $_getPrefetchedData<
                      DemoSessionRow,
                      $DemoSessionsTable,
                      DemoEventRow
                    >(
                      currentTable: table,
                      referencedTable: $$DemoSessionsTableReferences
                          ._demoSessionEventsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DemoSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).demoSessionEventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.sessionId == item.sessionId,
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

typedef $$DemoSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$DemoHistoryDatabase,
      $DemoSessionsTable,
      DemoSessionRow,
      $$DemoSessionsTableFilterComposer,
      $$DemoSessionsTableOrderingComposer,
      $$DemoSessionsTableAnnotationComposer,
      $$DemoSessionsTableCreateCompanionBuilder,
      $$DemoSessionsTableUpdateCompanionBuilder,
      (DemoSessionRow, $$DemoSessionsTableReferences),
      DemoSessionRow,
      PrefetchHooks Function({bool demoSessionEventsRefs})
    >;
typedef $$DemoSessionEventsTableCreateCompanionBuilder =
    DemoSessionEventsCompanion Function({
      required String sessionId,
      required int sequence,
      required String type,
      required int offsetMs,
      Value<String?> measurement,
      Value<String?> signal,
      Value<String?> episodeId,
      Value<String?> episodeKind,
      Value<String?> detail,
      Value<int> rowid,
    });
typedef $$DemoSessionEventsTableUpdateCompanionBuilder =
    DemoSessionEventsCompanion Function({
      Value<String> sessionId,
      Value<int> sequence,
      Value<String> type,
      Value<int> offsetMs,
      Value<String?> measurement,
      Value<String?> signal,
      Value<String?> episodeId,
      Value<String?> episodeKind,
      Value<String?> detail,
      Value<int> rowid,
    });

final class $$DemoSessionEventsTableReferences
    extends
        BaseReferences<
          _$DemoHistoryDatabase,
          $DemoSessionEventsTable,
          DemoEventRow
        > {
  $$DemoSessionEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DemoSessionsTable _sessionIdTable(_$DemoHistoryDatabase db) =>
      db.demoSessions.createAlias(
        'demo_session_events__session_id__demo_sessions__session_id',
      );

  $$DemoSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$DemoSessionsTableTableManager(
      $_db,
      $_db.demoSessions,
    ).filter((f) => f.sessionId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DemoSessionEventsTableFilterComposer
    extends Composer<_$DemoHistoryDatabase, $DemoSessionEventsTable> {
  $$DemoSessionEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMs => $composableBuilder(
    column: $table.offsetMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurement => $composableBuilder(
    column: $table.measurement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signal => $composableBuilder(
    column: $table.signal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeKind => $composableBuilder(
    column: $table.episodeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  $$DemoSessionsTableFilterComposer get sessionId {
    final $$DemoSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.demoSessions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DemoSessionsTableFilterComposer(
            $db: $db,
            $table: $db.demoSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DemoSessionEventsTableOrderingComposer
    extends Composer<_$DemoHistoryDatabase, $DemoSessionEventsTable> {
  $$DemoSessionEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMs => $composableBuilder(
    column: $table.offsetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurement => $composableBuilder(
    column: $table.measurement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signal => $composableBuilder(
    column: $table.signal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeKind => $composableBuilder(
    column: $table.episodeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  $$DemoSessionsTableOrderingComposer get sessionId {
    final $$DemoSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.demoSessions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DemoSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.demoSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DemoSessionEventsTableAnnotationComposer
    extends Composer<_$DemoHistoryDatabase, $DemoSessionEventsTable> {
  $$DemoSessionEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get offsetMs =>
      $composableBuilder(column: $table.offsetMs, builder: (column) => column);

  GeneratedColumn<String> get measurement => $composableBuilder(
    column: $table.measurement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signal =>
      $composableBuilder(column: $table.signal, builder: (column) => column);

  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<String> get episodeKind => $composableBuilder(
    column: $table.episodeKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  $$DemoSessionsTableAnnotationComposer get sessionId {
    final $$DemoSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.demoSessions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DemoSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.demoSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DemoSessionEventsTableTableManager
    extends
        RootTableManager<
          _$DemoHistoryDatabase,
          $DemoSessionEventsTable,
          DemoEventRow,
          $$DemoSessionEventsTableFilterComposer,
          $$DemoSessionEventsTableOrderingComposer,
          $$DemoSessionEventsTableAnnotationComposer,
          $$DemoSessionEventsTableCreateCompanionBuilder,
          $$DemoSessionEventsTableUpdateCompanionBuilder,
          (DemoEventRow, $$DemoSessionEventsTableReferences),
          DemoEventRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$DemoSessionEventsTableTableManager(
    _$DemoHistoryDatabase db,
    $DemoSessionEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DemoSessionEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DemoSessionEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DemoSessionEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> offsetMs = const Value.absent(),
                Value<String?> measurement = const Value.absent(),
                Value<String?> signal = const Value.absent(),
                Value<String?> episodeId = const Value.absent(),
                Value<String?> episodeKind = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DemoSessionEventsCompanion(
                sessionId: sessionId,
                sequence: sequence,
                type: type,
                offsetMs: offsetMs,
                measurement: measurement,
                signal: signal,
                episodeId: episodeId,
                episodeKind: episodeKind,
                detail: detail,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required int sequence,
                required String type,
                required int offsetMs,
                Value<String?> measurement = const Value.absent(),
                Value<String?> signal = const Value.absent(),
                Value<String?> episodeId = const Value.absent(),
                Value<String?> episodeKind = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DemoSessionEventsCompanion.insert(
                sessionId: sessionId,
                sequence: sequence,
                type: type,
                offsetMs: offsetMs,
                measurement: measurement,
                signal: signal,
                episodeId: episodeId,
                episodeKind: episodeKind,
                detail: detail,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DemoSessionEventsTable, DemoEventRow>(table),
                  $$DemoSessionEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$DemoSessionEventsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$DemoSessionEventsTableReferences
                            ._sessionIdTable(db)
                            .sessionId,
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

typedef $$DemoSessionEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$DemoHistoryDatabase,
      $DemoSessionEventsTable,
      DemoEventRow,
      $$DemoSessionEventsTableFilterComposer,
      $$DemoSessionEventsTableOrderingComposer,
      $$DemoSessionEventsTableAnnotationComposer,
      $$DemoSessionEventsTableCreateCompanionBuilder,
      $$DemoSessionEventsTableUpdateCompanionBuilder,
      (DemoEventRow, $$DemoSessionEventsTableReferences),
      DemoEventRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      Value<int> singleton,
      required String theme,
      required String soundPatternId,
      required bool reducedMotion,
      required int updatedEpochMs,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<int> singleton,
      Value<String> theme,
      Value<String> soundPatternId,
      Value<bool> reducedMotion,
      Value<int> updatedEpochMs,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$DemoHistoryDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundPatternId => $composableBuilder(
    column: $table.soundPatternId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reducedMotion => $composableBuilder(
    column: $table.reducedMotion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedEpochMs => $composableBuilder(
    column: $table.updatedEpochMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$DemoHistoryDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundPatternId => $composableBuilder(
    column: $table.soundPatternId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reducedMotion => $composableBuilder(
    column: $table.reducedMotion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedEpochMs => $composableBuilder(
    column: $table.updatedEpochMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$DemoHistoryDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singleton =>
      $composableBuilder(column: $table.singleton, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get soundPatternId => $composableBuilder(
    column: $table.soundPatternId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reducedMotion => $composableBuilder(
    column: $table.reducedMotion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedEpochMs => $composableBuilder(
    column: $table.updatedEpochMs,
    builder: (column) => column,
  );
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$DemoHistoryDatabase,
          $PreferencesTable,
          PreferencesRow,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            PreferencesRow,
            BaseReferences<
              _$DemoHistoryDatabase,
              $PreferencesTable,
              PreferencesRow
            >,
          ),
          PreferencesRow,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(
    _$DemoHistoryDatabase db,
    $PreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> singleton = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> soundPatternId = const Value.absent(),
                Value<bool> reducedMotion = const Value.absent(),
                Value<int> updatedEpochMs = const Value.absent(),
              }) => PreferencesCompanion(
                singleton: singleton,
                theme: theme,
                soundPatternId: soundPatternId,
                reducedMotion: reducedMotion,
                updatedEpochMs: updatedEpochMs,
              ),
          createCompanionCallback:
              ({
                Value<int> singleton = const Value.absent(),
                required String theme,
                required String soundPatternId,
                required bool reducedMotion,
                required int updatedEpochMs,
              }) => PreferencesCompanion.insert(
                singleton: singleton,
                theme: theme,
                soundPatternId: soundPatternId,
                reducedMotion: reducedMotion,
                updatedEpochMs: updatedEpochMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferencesTable, PreferencesRow>(table),
                  BaseReferences<
                    _$DemoHistoryDatabase,
                    $PreferencesTable,
                    PreferencesRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$DemoHistoryDatabase,
      $PreferencesTable,
      PreferencesRow,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        PreferencesRow,
        BaseReferences<
          _$DemoHistoryDatabase,
          $PreferencesTable,
          PreferencesRow
        >,
      ),
      PreferencesRow,
      PrefetchHooks Function()
    >;

class $DemoHistoryDatabaseManager {
  final _$DemoHistoryDatabase _db;
  $DemoHistoryDatabaseManager(this._db);
  $$DemoSessionsTableTableManager get demoSessions =>
      $$DemoSessionsTableTableManager(_db, _db.demoSessions);
  $$DemoSessionEventsTableTableManager get demoSessionEvents =>
      $$DemoSessionEventsTableTableManager(_db, _db.demoSessionEvents);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
}
