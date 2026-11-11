// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experimental_history_database.dart';

// ignore_for_file: type=lint
class $ExperimentalSessionsTable extends ExperimentalSessions
    with TableInfo<$ExperimentalSessionsTable, ExperimentalSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExperimentalSessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudSyncedMeta = const VerificationMeta(
    'cloudSynced',
  );
  @override
  late final GeneratedColumn<bool> cloudSynced = GeneratedColumn<bool>(
    'cloud_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cloud_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    check: () => origin.equals('realExperimental'),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('realExperimental'),
  );
  static const VerificationMeta _qualificationStatusMeta =
      const VerificationMeta('qualificationStatus');
  @override
  late final GeneratedColumn<String> qualificationStatus =
      GeneratedColumn<String>(
        'qualification_status',
        aliasedName,
        false,
        check: () => qualificationStatus.equals('experimental'),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('experimental'),
      );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _landmarkSchemaMeta = const VerificationMeta(
    'landmarkSchema',
  );
  @override
  late final GeneratedColumn<String> landmarkSchema = GeneratedColumn<String>(
    'landmark_schema',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelSha256Meta = const VerificationMeta(
    'modelSha256',
  );
  @override
  late final GeneratedColumn<String> modelSha256 = GeneratedColumn<String>(
    'model_sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _engineInstanceIdMeta = const VerificationMeta(
    'engineInstanceId',
  );
  @override
  late final GeneratedColumn<String> engineInstanceId = GeneratedColumn<String>(
    'engine_instance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _openEarRightE6Meta = const VerificationMeta(
    'openEarRightE6',
  );
  @override
  late final GeneratedColumn<int> openEarRightE6 = GeneratedColumn<int>(
    'open_ear_right_e6',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openEarLeftE6Meta = const VerificationMeta(
    'openEarLeftE6',
  );
  @override
  late final GeneratedColumn<int> openEarLeftE6 = GeneratedColumn<int>(
    'open_ear_left_e6',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calibrationSamplesMeta =
      const VerificationMeta('calibrationSamples');
  @override
  late final GeneratedColumn<int> calibrationSamples = GeneratedColumn<int>(
    'calibration_samples',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calibrationCoverageE6Meta =
      const VerificationMeta('calibrationCoverageE6');
  @override
  late final GeneratedColumn<int> calibrationCoverageE6 = GeneratedColumn<int>(
    'calibration_coverage_e6',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    check: () =>
        lifecycle.isIn(const ['active', 'paused', 'finalized', 'interrupted']),
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
  static const VerificationMeta _recoveredEpochMsMeta = const VerificationMeta(
    'recoveredEpochMs',
  );
  @override
  late final GeneratedColumn<int> recoveredEpochMs = GeneratedColumn<int>(
    'recovered_epoch_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _recordsLostMeta = const VerificationMeta(
    'recordsLost',
  );
  @override
  late final GeneratedColumn<int> recordsLost = GeneratedColumn<int>(
    'records_lost',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activeMsMeta = const VerificationMeta(
    'activeMs',
  );
  @override
  late final GeneratedColumn<int> activeMs = GeneratedColumn<int>(
    'active_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _closureActivationsMeta =
      const VerificationMeta('closureActivations');
  @override
  late final GeneratedColumn<int> closureActivations = GeneratedColumn<int>(
    'closure_activations',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tonesPlayedMeta = const VerificationMeta(
    'tonesPlayed',
  );
  @override
  late final GeneratedColumn<int> tonesPlayed = GeneratedColumn<int>(
    'tones_played',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tonesFailedMeta = const VerificationMeta(
    'tonesFailed',
  );
  @override
  late final GeneratedColumn<int> tonesFailed = GeneratedColumn<int>(
    'tones_failed',
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
  static const VerificationMeta _knownThroughMsMeta = const VerificationMeta(
    'knownThroughMs',
  );
  @override
  late final GeneratedColumn<int> knownThroughMs = GeneratedColumn<int>(
    'known_through_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _knownActiveMsMeta = const VerificationMeta(
    'knownActiveMs',
  );
  @override
  late final GeneratedColumn<int> knownActiveMs = GeneratedColumn<int>(
    'known_active_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _knownEvaluableMsMeta = const VerificationMeta(
    'knownEvaluableMs',
  );
  @override
  late final GeneratedColumn<int> knownEvaluableMs = GeneratedColumn<int>(
    'known_evaluable_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _knownPausedMsMeta = const VerificationMeta(
    'knownPausedMs',
  );
  @override
  late final GeneratedColumn<int> knownPausedMs = GeneratedColumn<int>(
    'known_paused_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    accountId,
    cloudSynced,
    origin,
    qualificationStatus,
    profileId,
    landmarkSchema,
    modelId,
    modelSha256,
    engineInstanceId,
    calibrationId,
    openEarRightE6,
    openEarLeftE6,
    calibrationSamples,
    calibrationCoverageE6,
    startedEpochMs,
    startOffsetMinutes,
    lifecycle,
    endedEpochMs,
    endOffsetMinutes,
    endOffsetMs,
    latestDurableOffsetMs,
    recoveredEpochMs,
    integrityStatus,
    recordsLost,
    activeMs,
    evaluableMs,
    nonEvaluableMs,
    pausedMs,
    closureActivations,
    tonesPlayed,
    tonesFailed,
    pauseCount,
    knownThroughMs,
    knownActiveMs,
    knownEvaluableMs,
    knownPausedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'experimental_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExperimentalSessionRow> instance, {
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
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('cloud_synced')) {
      context.handle(
        _cloudSyncedMeta,
        cloudSynced.isAcceptableOrUnknown(
          data['cloud_synced']!,
          _cloudSyncedMeta,
        ),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('qualification_status')) {
      context.handle(
        _qualificationStatusMeta,
        qualificationStatus.isAcceptableOrUnknown(
          data['qualification_status']!,
          _qualificationStatusMeta,
        ),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('landmark_schema')) {
      context.handle(
        _landmarkSchemaMeta,
        landmarkSchema.isAcceptableOrUnknown(
          data['landmark_schema']!,
          _landmarkSchemaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_landmarkSchemaMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('model_sha256')) {
      context.handle(
        _modelSha256Meta,
        modelSha256.isAcceptableOrUnknown(
          data['model_sha256']!,
          _modelSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelSha256Meta);
    }
    if (data.containsKey('engine_instance_id')) {
      context.handle(
        _engineInstanceIdMeta,
        engineInstanceId.isAcceptableOrUnknown(
          data['engine_instance_id']!,
          _engineInstanceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_engineInstanceIdMeta);
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
    if (data.containsKey('open_ear_right_e6')) {
      context.handle(
        _openEarRightE6Meta,
        openEarRightE6.isAcceptableOrUnknown(
          data['open_ear_right_e6']!,
          _openEarRightE6Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openEarRightE6Meta);
    }
    if (data.containsKey('open_ear_left_e6')) {
      context.handle(
        _openEarLeftE6Meta,
        openEarLeftE6.isAcceptableOrUnknown(
          data['open_ear_left_e6']!,
          _openEarLeftE6Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openEarLeftE6Meta);
    }
    if (data.containsKey('calibration_samples')) {
      context.handle(
        _calibrationSamplesMeta,
        calibrationSamples.isAcceptableOrUnknown(
          data['calibration_samples']!,
          _calibrationSamplesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calibrationSamplesMeta);
    }
    if (data.containsKey('calibration_coverage_e6')) {
      context.handle(
        _calibrationCoverageE6Meta,
        calibrationCoverageE6.isAcceptableOrUnknown(
          data['calibration_coverage_e6']!,
          _calibrationCoverageE6Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calibrationCoverageE6Meta);
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
    if (data.containsKey('recovered_epoch_ms')) {
      context.handle(
        _recoveredEpochMsMeta,
        recoveredEpochMs.isAcceptableOrUnknown(
          data['recovered_epoch_ms']!,
          _recoveredEpochMsMeta,
        ),
      );
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
    if (data.containsKey('records_lost')) {
      context.handle(
        _recordsLostMeta,
        recordsLost.isAcceptableOrUnknown(
          data['records_lost']!,
          _recordsLostMeta,
        ),
      );
    }
    if (data.containsKey('active_ms')) {
      context.handle(
        _activeMsMeta,
        activeMs.isAcceptableOrUnknown(data['active_ms']!, _activeMsMeta),
      );
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
    if (data.containsKey('closure_activations')) {
      context.handle(
        _closureActivationsMeta,
        closureActivations.isAcceptableOrUnknown(
          data['closure_activations']!,
          _closureActivationsMeta,
        ),
      );
    }
    if (data.containsKey('tones_played')) {
      context.handle(
        _tonesPlayedMeta,
        tonesPlayed.isAcceptableOrUnknown(
          data['tones_played']!,
          _tonesPlayedMeta,
        ),
      );
    }
    if (data.containsKey('tones_failed')) {
      context.handle(
        _tonesFailedMeta,
        tonesFailed.isAcceptableOrUnknown(
          data['tones_failed']!,
          _tonesFailedMeta,
        ),
      );
    }
    if (data.containsKey('pause_count')) {
      context.handle(
        _pauseCountMeta,
        pauseCount.isAcceptableOrUnknown(data['pause_count']!, _pauseCountMeta),
      );
    }
    if (data.containsKey('known_through_ms')) {
      context.handle(
        _knownThroughMsMeta,
        knownThroughMs.isAcceptableOrUnknown(
          data['known_through_ms']!,
          _knownThroughMsMeta,
        ),
      );
    }
    if (data.containsKey('known_active_ms')) {
      context.handle(
        _knownActiveMsMeta,
        knownActiveMs.isAcceptableOrUnknown(
          data['known_active_ms']!,
          _knownActiveMsMeta,
        ),
      );
    }
    if (data.containsKey('known_evaluable_ms')) {
      context.handle(
        _knownEvaluableMsMeta,
        knownEvaluableMs.isAcceptableOrUnknown(
          data['known_evaluable_ms']!,
          _knownEvaluableMsMeta,
        ),
      );
    }
    if (data.containsKey('known_paused_ms')) {
      context.handle(
        _knownPausedMsMeta,
        knownPausedMs.isAcceptableOrUnknown(
          data['known_paused_ms']!,
          _knownPausedMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  ExperimentalSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExperimentalSessionRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      cloudSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cloud_synced'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      qualificationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qualification_status'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      landmarkSchema: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}landmark_schema'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      modelSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_sha256'],
      )!,
      engineInstanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine_instance_id'],
      )!,
      calibrationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calibration_id'],
      )!,
      openEarRightE6: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}open_ear_right_e6'],
      )!,
      openEarLeftE6: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}open_ear_left_e6'],
      )!,
      calibrationSamples: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calibration_samples'],
      )!,
      calibrationCoverageE6: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calibration_coverage_e6'],
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
      recoveredEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recovered_epoch_ms'],
      ),
      integrityStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}integrity_status'],
      )!,
      recordsLost: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}records_lost'],
      )!,
      activeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_ms'],
      ),
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
      closureActivations: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closure_activations'],
      ),
      tonesPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tones_played'],
      ),
      tonesFailed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tones_failed'],
      ),
      pauseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pause_count'],
      ),
      knownThroughMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}known_through_ms'],
      ),
      knownActiveMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}known_active_ms'],
      ),
      knownEvaluableMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}known_evaluable_ms'],
      ),
      knownPausedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}known_paused_ms'],
      ),
    );
  }

  @override
  $ExperimentalSessionsTable createAlias(String alias) {
    return $ExperimentalSessionsTable(attachedDatabase, alias);
  }
}

class ExperimentalSessionRow extends DataClass
    implements Insertable<ExperimentalSessionRow> {
  final String sessionId;
  final String? accountId;
  final bool cloudSynced;

  /// Origen permanente: datos reales experimentales (nunca DEMO).
  final String origin;

  /// Calificación permanente del perfil: experimental.
  final String qualificationStatus;
  final String profileId;
  final String landmarkSchema;
  final String modelId;
  final String modelSha256;
  final String engineInstanceId;
  final String calibrationId;
  final int openEarRightE6;
  final int openEarLeftE6;
  final int calibrationSamples;
  final int calibrationCoverageE6;
  final int startedEpochMs;
  final int startOffsetMinutes;

  /// active, paused, finalized o interrupted.
  final String lifecycle;

  /// Cierre confirmado: solo en `finalized`.
  final int? endedEpochMs;
  final int? endOffsetMinutes;
  final int? endOffsetMs;

  /// Último límite confirmado en el journal (ms desde el inicio).
  final int latestDurableOffsetMs;

  /// Recuperación tras la muerte del proceso: no es el final de la sesión.
  final int? recoveredEpochMs;

  /// complete o incomplete (Área 06 §11).
  final String integrityStatus;

  /// Hechos que el motor declaró perdidos (escrituras fallidas).
  final int recordsLost;
  final int? activeMs;
  final int? evaluableMs;
  final int? nonEvaluableMs;
  final int? pausedMs;
  final int? closureActivations;
  final int? tonesPlayed;
  final int? tonesFailed;
  final int? pauseCount;
  final int? knownThroughMs;
  final int? knownActiveMs;
  final int? knownEvaluableMs;
  final int? knownPausedMs;
  const ExperimentalSessionRow({
    required this.sessionId,
    this.accountId,
    required this.cloudSynced,
    required this.origin,
    required this.qualificationStatus,
    required this.profileId,
    required this.landmarkSchema,
    required this.modelId,
    required this.modelSha256,
    required this.engineInstanceId,
    required this.calibrationId,
    required this.openEarRightE6,
    required this.openEarLeftE6,
    required this.calibrationSamples,
    required this.calibrationCoverageE6,
    required this.startedEpochMs,
    required this.startOffsetMinutes,
    required this.lifecycle,
    this.endedEpochMs,
    this.endOffsetMinutes,
    this.endOffsetMs,
    required this.latestDurableOffsetMs,
    this.recoveredEpochMs,
    required this.integrityStatus,
    required this.recordsLost,
    this.activeMs,
    this.evaluableMs,
    this.nonEvaluableMs,
    this.pausedMs,
    this.closureActivations,
    this.tonesPlayed,
    this.tonesFailed,
    this.pauseCount,
    this.knownThroughMs,
    this.knownActiveMs,
    this.knownEvaluableMs,
    this.knownPausedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['cloud_synced'] = Variable<bool>(cloudSynced);
    map['origin'] = Variable<String>(origin);
    map['qualification_status'] = Variable<String>(qualificationStatus);
    map['profile_id'] = Variable<String>(profileId);
    map['landmark_schema'] = Variable<String>(landmarkSchema);
    map['model_id'] = Variable<String>(modelId);
    map['model_sha256'] = Variable<String>(modelSha256);
    map['engine_instance_id'] = Variable<String>(engineInstanceId);
    map['calibration_id'] = Variable<String>(calibrationId);
    map['open_ear_right_e6'] = Variable<int>(openEarRightE6);
    map['open_ear_left_e6'] = Variable<int>(openEarLeftE6);
    map['calibration_samples'] = Variable<int>(calibrationSamples);
    map['calibration_coverage_e6'] = Variable<int>(calibrationCoverageE6);
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
    if (!nullToAbsent || recoveredEpochMs != null) {
      map['recovered_epoch_ms'] = Variable<int>(recoveredEpochMs);
    }
    map['integrity_status'] = Variable<String>(integrityStatus);
    map['records_lost'] = Variable<int>(recordsLost);
    if (!nullToAbsent || activeMs != null) {
      map['active_ms'] = Variable<int>(activeMs);
    }
    if (!nullToAbsent || evaluableMs != null) {
      map['evaluable_ms'] = Variable<int>(evaluableMs);
    }
    if (!nullToAbsent || nonEvaluableMs != null) {
      map['non_evaluable_ms'] = Variable<int>(nonEvaluableMs);
    }
    if (!nullToAbsent || pausedMs != null) {
      map['paused_ms'] = Variable<int>(pausedMs);
    }
    if (!nullToAbsent || closureActivations != null) {
      map['closure_activations'] = Variable<int>(closureActivations);
    }
    if (!nullToAbsent || tonesPlayed != null) {
      map['tones_played'] = Variable<int>(tonesPlayed);
    }
    if (!nullToAbsent || tonesFailed != null) {
      map['tones_failed'] = Variable<int>(tonesFailed);
    }
    if (!nullToAbsent || pauseCount != null) {
      map['pause_count'] = Variable<int>(pauseCount);
    }
    if (!nullToAbsent || knownThroughMs != null) {
      map['known_through_ms'] = Variable<int>(knownThroughMs);
    }
    if (!nullToAbsent || knownActiveMs != null) {
      map['known_active_ms'] = Variable<int>(knownActiveMs);
    }
    if (!nullToAbsent || knownEvaluableMs != null) {
      map['known_evaluable_ms'] = Variable<int>(knownEvaluableMs);
    }
    if (!nullToAbsent || knownPausedMs != null) {
      map['known_paused_ms'] = Variable<int>(knownPausedMs);
    }
    return map;
  }

  ExperimentalSessionsCompanion toCompanion(bool nullToAbsent) {
    return ExperimentalSessionsCompanion(
      sessionId: Value(sessionId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      cloudSynced: Value(cloudSynced),
      origin: Value(origin),
      qualificationStatus: Value(qualificationStatus),
      profileId: Value(profileId),
      landmarkSchema: Value(landmarkSchema),
      modelId: Value(modelId),
      modelSha256: Value(modelSha256),
      engineInstanceId: Value(engineInstanceId),
      calibrationId: Value(calibrationId),
      openEarRightE6: Value(openEarRightE6),
      openEarLeftE6: Value(openEarLeftE6),
      calibrationSamples: Value(calibrationSamples),
      calibrationCoverageE6: Value(calibrationCoverageE6),
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
      recoveredEpochMs: recoveredEpochMs == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveredEpochMs),
      integrityStatus: Value(integrityStatus),
      recordsLost: Value(recordsLost),
      activeMs: activeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(activeMs),
      evaluableMs: evaluableMs == null && nullToAbsent
          ? const Value.absent()
          : Value(evaluableMs),
      nonEvaluableMs: nonEvaluableMs == null && nullToAbsent
          ? const Value.absent()
          : Value(nonEvaluableMs),
      pausedMs: pausedMs == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedMs),
      closureActivations: closureActivations == null && nullToAbsent
          ? const Value.absent()
          : Value(closureActivations),
      tonesPlayed: tonesPlayed == null && nullToAbsent
          ? const Value.absent()
          : Value(tonesPlayed),
      tonesFailed: tonesFailed == null && nullToAbsent
          ? const Value.absent()
          : Value(tonesFailed),
      pauseCount: pauseCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pauseCount),
      knownThroughMs: knownThroughMs == null && nullToAbsent
          ? const Value.absent()
          : Value(knownThroughMs),
      knownActiveMs: knownActiveMs == null && nullToAbsent
          ? const Value.absent()
          : Value(knownActiveMs),
      knownEvaluableMs: knownEvaluableMs == null && nullToAbsent
          ? const Value.absent()
          : Value(knownEvaluableMs),
      knownPausedMs: knownPausedMs == null && nullToAbsent
          ? const Value.absent()
          : Value(knownPausedMs),
    );
  }

  factory ExperimentalSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExperimentalSessionRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      cloudSynced: serializer.fromJson<bool>(json['cloudSynced']),
      origin: serializer.fromJson<String>(json['origin']),
      qualificationStatus: serializer.fromJson<String>(
        json['qualificationStatus'],
      ),
      profileId: serializer.fromJson<String>(json['profileId']),
      landmarkSchema: serializer.fromJson<String>(json['landmarkSchema']),
      modelId: serializer.fromJson<String>(json['modelId']),
      modelSha256: serializer.fromJson<String>(json['modelSha256']),
      engineInstanceId: serializer.fromJson<String>(json['engineInstanceId']),
      calibrationId: serializer.fromJson<String>(json['calibrationId']),
      openEarRightE6: serializer.fromJson<int>(json['openEarRightE6']),
      openEarLeftE6: serializer.fromJson<int>(json['openEarLeftE6']),
      calibrationSamples: serializer.fromJson<int>(json['calibrationSamples']),
      calibrationCoverageE6: serializer.fromJson<int>(
        json['calibrationCoverageE6'],
      ),
      startedEpochMs: serializer.fromJson<int>(json['startedEpochMs']),
      startOffsetMinutes: serializer.fromJson<int>(json['startOffsetMinutes']),
      lifecycle: serializer.fromJson<String>(json['lifecycle']),
      endedEpochMs: serializer.fromJson<int?>(json['endedEpochMs']),
      endOffsetMinutes: serializer.fromJson<int?>(json['endOffsetMinutes']),
      endOffsetMs: serializer.fromJson<int?>(json['endOffsetMs']),
      latestDurableOffsetMs: serializer.fromJson<int>(
        json['latestDurableOffsetMs'],
      ),
      recoveredEpochMs: serializer.fromJson<int?>(json['recoveredEpochMs']),
      integrityStatus: serializer.fromJson<String>(json['integrityStatus']),
      recordsLost: serializer.fromJson<int>(json['recordsLost']),
      activeMs: serializer.fromJson<int?>(json['activeMs']),
      evaluableMs: serializer.fromJson<int?>(json['evaluableMs']),
      nonEvaluableMs: serializer.fromJson<int?>(json['nonEvaluableMs']),
      pausedMs: serializer.fromJson<int?>(json['pausedMs']),
      closureActivations: serializer.fromJson<int?>(json['closureActivations']),
      tonesPlayed: serializer.fromJson<int?>(json['tonesPlayed']),
      tonesFailed: serializer.fromJson<int?>(json['tonesFailed']),
      pauseCount: serializer.fromJson<int?>(json['pauseCount']),
      knownThroughMs: serializer.fromJson<int?>(json['knownThroughMs']),
      knownActiveMs: serializer.fromJson<int?>(json['knownActiveMs']),
      knownEvaluableMs: serializer.fromJson<int?>(json['knownEvaluableMs']),
      knownPausedMs: serializer.fromJson<int?>(json['knownPausedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'accountId': serializer.toJson<String?>(accountId),
      'cloudSynced': serializer.toJson<bool>(cloudSynced),
      'origin': serializer.toJson<String>(origin),
      'qualificationStatus': serializer.toJson<String>(qualificationStatus),
      'profileId': serializer.toJson<String>(profileId),
      'landmarkSchema': serializer.toJson<String>(landmarkSchema),
      'modelId': serializer.toJson<String>(modelId),
      'modelSha256': serializer.toJson<String>(modelSha256),
      'engineInstanceId': serializer.toJson<String>(engineInstanceId),
      'calibrationId': serializer.toJson<String>(calibrationId),
      'openEarRightE6': serializer.toJson<int>(openEarRightE6),
      'openEarLeftE6': serializer.toJson<int>(openEarLeftE6),
      'calibrationSamples': serializer.toJson<int>(calibrationSamples),
      'calibrationCoverageE6': serializer.toJson<int>(calibrationCoverageE6),
      'startedEpochMs': serializer.toJson<int>(startedEpochMs),
      'startOffsetMinutes': serializer.toJson<int>(startOffsetMinutes),
      'lifecycle': serializer.toJson<String>(lifecycle),
      'endedEpochMs': serializer.toJson<int?>(endedEpochMs),
      'endOffsetMinutes': serializer.toJson<int?>(endOffsetMinutes),
      'endOffsetMs': serializer.toJson<int?>(endOffsetMs),
      'latestDurableOffsetMs': serializer.toJson<int>(latestDurableOffsetMs),
      'recoveredEpochMs': serializer.toJson<int?>(recoveredEpochMs),
      'integrityStatus': serializer.toJson<String>(integrityStatus),
      'recordsLost': serializer.toJson<int>(recordsLost),
      'activeMs': serializer.toJson<int?>(activeMs),
      'evaluableMs': serializer.toJson<int?>(evaluableMs),
      'nonEvaluableMs': serializer.toJson<int?>(nonEvaluableMs),
      'pausedMs': serializer.toJson<int?>(pausedMs),
      'closureActivations': serializer.toJson<int?>(closureActivations),
      'tonesPlayed': serializer.toJson<int?>(tonesPlayed),
      'tonesFailed': serializer.toJson<int?>(tonesFailed),
      'pauseCount': serializer.toJson<int?>(pauseCount),
      'knownThroughMs': serializer.toJson<int?>(knownThroughMs),
      'knownActiveMs': serializer.toJson<int?>(knownActiveMs),
      'knownEvaluableMs': serializer.toJson<int?>(knownEvaluableMs),
      'knownPausedMs': serializer.toJson<int?>(knownPausedMs),
    };
  }

  ExperimentalSessionRow copyWith({
    String? sessionId,
    Value<String?> accountId = const Value.absent(),
    bool? cloudSynced,
    String? origin,
    String? qualificationStatus,
    String? profileId,
    String? landmarkSchema,
    String? modelId,
    String? modelSha256,
    String? engineInstanceId,
    String? calibrationId,
    int? openEarRightE6,
    int? openEarLeftE6,
    int? calibrationSamples,
    int? calibrationCoverageE6,
    int? startedEpochMs,
    int? startOffsetMinutes,
    String? lifecycle,
    Value<int?> endedEpochMs = const Value.absent(),
    Value<int?> endOffsetMinutes = const Value.absent(),
    Value<int?> endOffsetMs = const Value.absent(),
    int? latestDurableOffsetMs,
    Value<int?> recoveredEpochMs = const Value.absent(),
    String? integrityStatus,
    int? recordsLost,
    Value<int?> activeMs = const Value.absent(),
    Value<int?> evaluableMs = const Value.absent(),
    Value<int?> nonEvaluableMs = const Value.absent(),
    Value<int?> pausedMs = const Value.absent(),
    Value<int?> closureActivations = const Value.absent(),
    Value<int?> tonesPlayed = const Value.absent(),
    Value<int?> tonesFailed = const Value.absent(),
    Value<int?> pauseCount = const Value.absent(),
    Value<int?> knownThroughMs = const Value.absent(),
    Value<int?> knownActiveMs = const Value.absent(),
    Value<int?> knownEvaluableMs = const Value.absent(),
    Value<int?> knownPausedMs = const Value.absent(),
  }) => ExperimentalSessionRow(
    sessionId: sessionId ?? this.sessionId,
    accountId: accountId.present ? accountId.value : this.accountId,
    cloudSynced: cloudSynced ?? this.cloudSynced,
    origin: origin ?? this.origin,
    qualificationStatus: qualificationStatus ?? this.qualificationStatus,
    profileId: profileId ?? this.profileId,
    landmarkSchema: landmarkSchema ?? this.landmarkSchema,
    modelId: modelId ?? this.modelId,
    modelSha256: modelSha256 ?? this.modelSha256,
    engineInstanceId: engineInstanceId ?? this.engineInstanceId,
    calibrationId: calibrationId ?? this.calibrationId,
    openEarRightE6: openEarRightE6 ?? this.openEarRightE6,
    openEarLeftE6: openEarLeftE6 ?? this.openEarLeftE6,
    calibrationSamples: calibrationSamples ?? this.calibrationSamples,
    calibrationCoverageE6: calibrationCoverageE6 ?? this.calibrationCoverageE6,
    startedEpochMs: startedEpochMs ?? this.startedEpochMs,
    startOffsetMinutes: startOffsetMinutes ?? this.startOffsetMinutes,
    lifecycle: lifecycle ?? this.lifecycle,
    endedEpochMs: endedEpochMs.present ? endedEpochMs.value : this.endedEpochMs,
    endOffsetMinutes: endOffsetMinutes.present
        ? endOffsetMinutes.value
        : this.endOffsetMinutes,
    endOffsetMs: endOffsetMs.present ? endOffsetMs.value : this.endOffsetMs,
    latestDurableOffsetMs: latestDurableOffsetMs ?? this.latestDurableOffsetMs,
    recoveredEpochMs: recoveredEpochMs.present
        ? recoveredEpochMs.value
        : this.recoveredEpochMs,
    integrityStatus: integrityStatus ?? this.integrityStatus,
    recordsLost: recordsLost ?? this.recordsLost,
    activeMs: activeMs.present ? activeMs.value : this.activeMs,
    evaluableMs: evaluableMs.present ? evaluableMs.value : this.evaluableMs,
    nonEvaluableMs: nonEvaluableMs.present
        ? nonEvaluableMs.value
        : this.nonEvaluableMs,
    pausedMs: pausedMs.present ? pausedMs.value : this.pausedMs,
    closureActivations: closureActivations.present
        ? closureActivations.value
        : this.closureActivations,
    tonesPlayed: tonesPlayed.present ? tonesPlayed.value : this.tonesPlayed,
    tonesFailed: tonesFailed.present ? tonesFailed.value : this.tonesFailed,
    pauseCount: pauseCount.present ? pauseCount.value : this.pauseCount,
    knownThroughMs: knownThroughMs.present
        ? knownThroughMs.value
        : this.knownThroughMs,
    knownActiveMs: knownActiveMs.present
        ? knownActiveMs.value
        : this.knownActiveMs,
    knownEvaluableMs: knownEvaluableMs.present
        ? knownEvaluableMs.value
        : this.knownEvaluableMs,
    knownPausedMs: knownPausedMs.present
        ? knownPausedMs.value
        : this.knownPausedMs,
  );
  ExperimentalSessionRow copyWithCompanion(ExperimentalSessionsCompanion data) {
    return ExperimentalSessionRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      cloudSynced: data.cloudSynced.present
          ? data.cloudSynced.value
          : this.cloudSynced,
      origin: data.origin.present ? data.origin.value : this.origin,
      qualificationStatus: data.qualificationStatus.present
          ? data.qualificationStatus.value
          : this.qualificationStatus,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      landmarkSchema: data.landmarkSchema.present
          ? data.landmarkSchema.value
          : this.landmarkSchema,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      modelSha256: data.modelSha256.present
          ? data.modelSha256.value
          : this.modelSha256,
      engineInstanceId: data.engineInstanceId.present
          ? data.engineInstanceId.value
          : this.engineInstanceId,
      calibrationId: data.calibrationId.present
          ? data.calibrationId.value
          : this.calibrationId,
      openEarRightE6: data.openEarRightE6.present
          ? data.openEarRightE6.value
          : this.openEarRightE6,
      openEarLeftE6: data.openEarLeftE6.present
          ? data.openEarLeftE6.value
          : this.openEarLeftE6,
      calibrationSamples: data.calibrationSamples.present
          ? data.calibrationSamples.value
          : this.calibrationSamples,
      calibrationCoverageE6: data.calibrationCoverageE6.present
          ? data.calibrationCoverageE6.value
          : this.calibrationCoverageE6,
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
      recoveredEpochMs: data.recoveredEpochMs.present
          ? data.recoveredEpochMs.value
          : this.recoveredEpochMs,
      integrityStatus: data.integrityStatus.present
          ? data.integrityStatus.value
          : this.integrityStatus,
      recordsLost: data.recordsLost.present
          ? data.recordsLost.value
          : this.recordsLost,
      activeMs: data.activeMs.present ? data.activeMs.value : this.activeMs,
      evaluableMs: data.evaluableMs.present
          ? data.evaluableMs.value
          : this.evaluableMs,
      nonEvaluableMs: data.nonEvaluableMs.present
          ? data.nonEvaluableMs.value
          : this.nonEvaluableMs,
      pausedMs: data.pausedMs.present ? data.pausedMs.value : this.pausedMs,
      closureActivations: data.closureActivations.present
          ? data.closureActivations.value
          : this.closureActivations,
      tonesPlayed: data.tonesPlayed.present
          ? data.tonesPlayed.value
          : this.tonesPlayed,
      tonesFailed: data.tonesFailed.present
          ? data.tonesFailed.value
          : this.tonesFailed,
      pauseCount: data.pauseCount.present
          ? data.pauseCount.value
          : this.pauseCount,
      knownThroughMs: data.knownThroughMs.present
          ? data.knownThroughMs.value
          : this.knownThroughMs,
      knownActiveMs: data.knownActiveMs.present
          ? data.knownActiveMs.value
          : this.knownActiveMs,
      knownEvaluableMs: data.knownEvaluableMs.present
          ? data.knownEvaluableMs.value
          : this.knownEvaluableMs,
      knownPausedMs: data.knownPausedMs.present
          ? data.knownPausedMs.value
          : this.knownPausedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentalSessionRow(')
          ..write('sessionId: $sessionId, ')
          ..write('accountId: $accountId, ')
          ..write('cloudSynced: $cloudSynced, ')
          ..write('origin: $origin, ')
          ..write('qualificationStatus: $qualificationStatus, ')
          ..write('profileId: $profileId, ')
          ..write('landmarkSchema: $landmarkSchema, ')
          ..write('modelId: $modelId, ')
          ..write('modelSha256: $modelSha256, ')
          ..write('engineInstanceId: $engineInstanceId, ')
          ..write('calibrationId: $calibrationId, ')
          ..write('openEarRightE6: $openEarRightE6, ')
          ..write('openEarLeftE6: $openEarLeftE6, ')
          ..write('calibrationSamples: $calibrationSamples, ')
          ..write('calibrationCoverageE6: $calibrationCoverageE6, ')
          ..write('startedEpochMs: $startedEpochMs, ')
          ..write('startOffsetMinutes: $startOffsetMinutes, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('endedEpochMs: $endedEpochMs, ')
          ..write('endOffsetMinutes: $endOffsetMinutes, ')
          ..write('endOffsetMs: $endOffsetMs, ')
          ..write('latestDurableOffsetMs: $latestDurableOffsetMs, ')
          ..write('recoveredEpochMs: $recoveredEpochMs, ')
          ..write('integrityStatus: $integrityStatus, ')
          ..write('recordsLost: $recordsLost, ')
          ..write('activeMs: $activeMs, ')
          ..write('evaluableMs: $evaluableMs, ')
          ..write('nonEvaluableMs: $nonEvaluableMs, ')
          ..write('pausedMs: $pausedMs, ')
          ..write('closureActivations: $closureActivations, ')
          ..write('tonesPlayed: $tonesPlayed, ')
          ..write('tonesFailed: $tonesFailed, ')
          ..write('pauseCount: $pauseCount, ')
          ..write('knownThroughMs: $knownThroughMs, ')
          ..write('knownActiveMs: $knownActiveMs, ')
          ..write('knownEvaluableMs: $knownEvaluableMs, ')
          ..write('knownPausedMs: $knownPausedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    sessionId,
    accountId,
    cloudSynced,
    origin,
    qualificationStatus,
    profileId,
    landmarkSchema,
    modelId,
    modelSha256,
    engineInstanceId,
    calibrationId,
    openEarRightE6,
    openEarLeftE6,
    calibrationSamples,
    calibrationCoverageE6,
    startedEpochMs,
    startOffsetMinutes,
    lifecycle,
    endedEpochMs,
    endOffsetMinutes,
    endOffsetMs,
    latestDurableOffsetMs,
    recoveredEpochMs,
    integrityStatus,
    recordsLost,
    activeMs,
    evaluableMs,
    nonEvaluableMs,
    pausedMs,
    closureActivations,
    tonesPlayed,
    tonesFailed,
    pauseCount,
    knownThroughMs,
    knownActiveMs,
    knownEvaluableMs,
    knownPausedMs,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExperimentalSessionRow &&
          other.sessionId == this.sessionId &&
          other.accountId == this.accountId &&
          other.cloudSynced == this.cloudSynced &&
          other.origin == this.origin &&
          other.qualificationStatus == this.qualificationStatus &&
          other.profileId == this.profileId &&
          other.landmarkSchema == this.landmarkSchema &&
          other.modelId == this.modelId &&
          other.modelSha256 == this.modelSha256 &&
          other.engineInstanceId == this.engineInstanceId &&
          other.calibrationId == this.calibrationId &&
          other.openEarRightE6 == this.openEarRightE6 &&
          other.openEarLeftE6 == this.openEarLeftE6 &&
          other.calibrationSamples == this.calibrationSamples &&
          other.calibrationCoverageE6 == this.calibrationCoverageE6 &&
          other.startedEpochMs == this.startedEpochMs &&
          other.startOffsetMinutes == this.startOffsetMinutes &&
          other.lifecycle == this.lifecycle &&
          other.endedEpochMs == this.endedEpochMs &&
          other.endOffsetMinutes == this.endOffsetMinutes &&
          other.endOffsetMs == this.endOffsetMs &&
          other.latestDurableOffsetMs == this.latestDurableOffsetMs &&
          other.recoveredEpochMs == this.recoveredEpochMs &&
          other.integrityStatus == this.integrityStatus &&
          other.recordsLost == this.recordsLost &&
          other.activeMs == this.activeMs &&
          other.evaluableMs == this.evaluableMs &&
          other.nonEvaluableMs == this.nonEvaluableMs &&
          other.pausedMs == this.pausedMs &&
          other.closureActivations == this.closureActivations &&
          other.tonesPlayed == this.tonesPlayed &&
          other.tonesFailed == this.tonesFailed &&
          other.pauseCount == this.pauseCount &&
          other.knownThroughMs == this.knownThroughMs &&
          other.knownActiveMs == this.knownActiveMs &&
          other.knownEvaluableMs == this.knownEvaluableMs &&
          other.knownPausedMs == this.knownPausedMs);
}

class ExperimentalSessionsCompanion
    extends UpdateCompanion<ExperimentalSessionRow> {
  final Value<String> sessionId;
  final Value<String?> accountId;
  final Value<bool> cloudSynced;
  final Value<String> origin;
  final Value<String> qualificationStatus;
  final Value<String> profileId;
  final Value<String> landmarkSchema;
  final Value<String> modelId;
  final Value<String> modelSha256;
  final Value<String> engineInstanceId;
  final Value<String> calibrationId;
  final Value<int> openEarRightE6;
  final Value<int> openEarLeftE6;
  final Value<int> calibrationSamples;
  final Value<int> calibrationCoverageE6;
  final Value<int> startedEpochMs;
  final Value<int> startOffsetMinutes;
  final Value<String> lifecycle;
  final Value<int?> endedEpochMs;
  final Value<int?> endOffsetMinutes;
  final Value<int?> endOffsetMs;
  final Value<int> latestDurableOffsetMs;
  final Value<int?> recoveredEpochMs;
  final Value<String> integrityStatus;
  final Value<int> recordsLost;
  final Value<int?> activeMs;
  final Value<int?> evaluableMs;
  final Value<int?> nonEvaluableMs;
  final Value<int?> pausedMs;
  final Value<int?> closureActivations;
  final Value<int?> tonesPlayed;
  final Value<int?> tonesFailed;
  final Value<int?> pauseCount;
  final Value<int?> knownThroughMs;
  final Value<int?> knownActiveMs;
  final Value<int?> knownEvaluableMs;
  final Value<int?> knownPausedMs;
  final Value<int> rowid;
  const ExperimentalSessionsCompanion({
    this.sessionId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.cloudSynced = const Value.absent(),
    this.origin = const Value.absent(),
    this.qualificationStatus = const Value.absent(),
    this.profileId = const Value.absent(),
    this.landmarkSchema = const Value.absent(),
    this.modelId = const Value.absent(),
    this.modelSha256 = const Value.absent(),
    this.engineInstanceId = const Value.absent(),
    this.calibrationId = const Value.absent(),
    this.openEarRightE6 = const Value.absent(),
    this.openEarLeftE6 = const Value.absent(),
    this.calibrationSamples = const Value.absent(),
    this.calibrationCoverageE6 = const Value.absent(),
    this.startedEpochMs = const Value.absent(),
    this.startOffsetMinutes = const Value.absent(),
    this.lifecycle = const Value.absent(),
    this.endedEpochMs = const Value.absent(),
    this.endOffsetMinutes = const Value.absent(),
    this.endOffsetMs = const Value.absent(),
    this.latestDurableOffsetMs = const Value.absent(),
    this.recoveredEpochMs = const Value.absent(),
    this.integrityStatus = const Value.absent(),
    this.recordsLost = const Value.absent(),
    this.activeMs = const Value.absent(),
    this.evaluableMs = const Value.absent(),
    this.nonEvaluableMs = const Value.absent(),
    this.pausedMs = const Value.absent(),
    this.closureActivations = const Value.absent(),
    this.tonesPlayed = const Value.absent(),
    this.tonesFailed = const Value.absent(),
    this.pauseCount = const Value.absent(),
    this.knownThroughMs = const Value.absent(),
    this.knownActiveMs = const Value.absent(),
    this.knownEvaluableMs = const Value.absent(),
    this.knownPausedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExperimentalSessionsCompanion.insert({
    required String sessionId,
    this.accountId = const Value.absent(),
    this.cloudSynced = const Value.absent(),
    this.origin = const Value.absent(),
    this.qualificationStatus = const Value.absent(),
    required String profileId,
    required String landmarkSchema,
    required String modelId,
    required String modelSha256,
    required String engineInstanceId,
    required String calibrationId,
    required int openEarRightE6,
    required int openEarLeftE6,
    required int calibrationSamples,
    required int calibrationCoverageE6,
    required int startedEpochMs,
    required int startOffsetMinutes,
    required String lifecycle,
    this.endedEpochMs = const Value.absent(),
    this.endOffsetMinutes = const Value.absent(),
    this.endOffsetMs = const Value.absent(),
    required int latestDurableOffsetMs,
    this.recoveredEpochMs = const Value.absent(),
    required String integrityStatus,
    this.recordsLost = const Value.absent(),
    this.activeMs = const Value.absent(),
    this.evaluableMs = const Value.absent(),
    this.nonEvaluableMs = const Value.absent(),
    this.pausedMs = const Value.absent(),
    this.closureActivations = const Value.absent(),
    this.tonesPlayed = const Value.absent(),
    this.tonesFailed = const Value.absent(),
    this.pauseCount = const Value.absent(),
    this.knownThroughMs = const Value.absent(),
    this.knownActiveMs = const Value.absent(),
    this.knownEvaluableMs = const Value.absent(),
    this.knownPausedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       profileId = Value(profileId),
       landmarkSchema = Value(landmarkSchema),
       modelId = Value(modelId),
       modelSha256 = Value(modelSha256),
       engineInstanceId = Value(engineInstanceId),
       calibrationId = Value(calibrationId),
       openEarRightE6 = Value(openEarRightE6),
       openEarLeftE6 = Value(openEarLeftE6),
       calibrationSamples = Value(calibrationSamples),
       calibrationCoverageE6 = Value(calibrationCoverageE6),
       startedEpochMs = Value(startedEpochMs),
       startOffsetMinutes = Value(startOffsetMinutes),
       lifecycle = Value(lifecycle),
       latestDurableOffsetMs = Value(latestDurableOffsetMs),
       integrityStatus = Value(integrityStatus);
  static Insertable<ExperimentalSessionRow> custom({
    Expression<String>? sessionId,
    Expression<String>? accountId,
    Expression<bool>? cloudSynced,
    Expression<String>? origin,
    Expression<String>? qualificationStatus,
    Expression<String>? profileId,
    Expression<String>? landmarkSchema,
    Expression<String>? modelId,
    Expression<String>? modelSha256,
    Expression<String>? engineInstanceId,
    Expression<String>? calibrationId,
    Expression<int>? openEarRightE6,
    Expression<int>? openEarLeftE6,
    Expression<int>? calibrationSamples,
    Expression<int>? calibrationCoverageE6,
    Expression<int>? startedEpochMs,
    Expression<int>? startOffsetMinutes,
    Expression<String>? lifecycle,
    Expression<int>? endedEpochMs,
    Expression<int>? endOffsetMinutes,
    Expression<int>? endOffsetMs,
    Expression<int>? latestDurableOffsetMs,
    Expression<int>? recoveredEpochMs,
    Expression<String>? integrityStatus,
    Expression<int>? recordsLost,
    Expression<int>? activeMs,
    Expression<int>? evaluableMs,
    Expression<int>? nonEvaluableMs,
    Expression<int>? pausedMs,
    Expression<int>? closureActivations,
    Expression<int>? tonesPlayed,
    Expression<int>? tonesFailed,
    Expression<int>? pauseCount,
    Expression<int>? knownThroughMs,
    Expression<int>? knownActiveMs,
    Expression<int>? knownEvaluableMs,
    Expression<int>? knownPausedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (accountId != null) 'account_id': accountId,
      if (cloudSynced != null) 'cloud_synced': cloudSynced,
      if (origin != null) 'origin': origin,
      if (qualificationStatus != null)
        'qualification_status': qualificationStatus,
      if (profileId != null) 'profile_id': profileId,
      if (landmarkSchema != null) 'landmark_schema': landmarkSchema,
      if (modelId != null) 'model_id': modelId,
      if (modelSha256 != null) 'model_sha256': modelSha256,
      if (engineInstanceId != null) 'engine_instance_id': engineInstanceId,
      if (calibrationId != null) 'calibration_id': calibrationId,
      if (openEarRightE6 != null) 'open_ear_right_e6': openEarRightE6,
      if (openEarLeftE6 != null) 'open_ear_left_e6': openEarLeftE6,
      if (calibrationSamples != null) 'calibration_samples': calibrationSamples,
      if (calibrationCoverageE6 != null)
        'calibration_coverage_e6': calibrationCoverageE6,
      if (startedEpochMs != null) 'started_epoch_ms': startedEpochMs,
      if (startOffsetMinutes != null)
        'start_offset_minutes': startOffsetMinutes,
      if (lifecycle != null) 'lifecycle': lifecycle,
      if (endedEpochMs != null) 'ended_epoch_ms': endedEpochMs,
      if (endOffsetMinutes != null) 'end_offset_minutes': endOffsetMinutes,
      if (endOffsetMs != null) 'end_offset_ms': endOffsetMs,
      if (latestDurableOffsetMs != null)
        'latest_durable_offset_ms': latestDurableOffsetMs,
      if (recoveredEpochMs != null) 'recovered_epoch_ms': recoveredEpochMs,
      if (integrityStatus != null) 'integrity_status': integrityStatus,
      if (recordsLost != null) 'records_lost': recordsLost,
      if (activeMs != null) 'active_ms': activeMs,
      if (evaluableMs != null) 'evaluable_ms': evaluableMs,
      if (nonEvaluableMs != null) 'non_evaluable_ms': nonEvaluableMs,
      if (pausedMs != null) 'paused_ms': pausedMs,
      if (closureActivations != null) 'closure_activations': closureActivations,
      if (tonesPlayed != null) 'tones_played': tonesPlayed,
      if (tonesFailed != null) 'tones_failed': tonesFailed,
      if (pauseCount != null) 'pause_count': pauseCount,
      if (knownThroughMs != null) 'known_through_ms': knownThroughMs,
      if (knownActiveMs != null) 'known_active_ms': knownActiveMs,
      if (knownEvaluableMs != null) 'known_evaluable_ms': knownEvaluableMs,
      if (knownPausedMs != null) 'known_paused_ms': knownPausedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExperimentalSessionsCompanion copyWith({
    Value<String>? sessionId,
    Value<String?>? accountId,
    Value<bool>? cloudSynced,
    Value<String>? origin,
    Value<String>? qualificationStatus,
    Value<String>? profileId,
    Value<String>? landmarkSchema,
    Value<String>? modelId,
    Value<String>? modelSha256,
    Value<String>? engineInstanceId,
    Value<String>? calibrationId,
    Value<int>? openEarRightE6,
    Value<int>? openEarLeftE6,
    Value<int>? calibrationSamples,
    Value<int>? calibrationCoverageE6,
    Value<int>? startedEpochMs,
    Value<int>? startOffsetMinutes,
    Value<String>? lifecycle,
    Value<int?>? endedEpochMs,
    Value<int?>? endOffsetMinutes,
    Value<int?>? endOffsetMs,
    Value<int>? latestDurableOffsetMs,
    Value<int?>? recoveredEpochMs,
    Value<String>? integrityStatus,
    Value<int>? recordsLost,
    Value<int?>? activeMs,
    Value<int?>? evaluableMs,
    Value<int?>? nonEvaluableMs,
    Value<int?>? pausedMs,
    Value<int?>? closureActivations,
    Value<int?>? tonesPlayed,
    Value<int?>? tonesFailed,
    Value<int?>? pauseCount,
    Value<int?>? knownThroughMs,
    Value<int?>? knownActiveMs,
    Value<int?>? knownEvaluableMs,
    Value<int?>? knownPausedMs,
    Value<int>? rowid,
  }) {
    return ExperimentalSessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      accountId: accountId ?? this.accountId,
      cloudSynced: cloudSynced ?? this.cloudSynced,
      origin: origin ?? this.origin,
      qualificationStatus: qualificationStatus ?? this.qualificationStatus,
      profileId: profileId ?? this.profileId,
      landmarkSchema: landmarkSchema ?? this.landmarkSchema,
      modelId: modelId ?? this.modelId,
      modelSha256: modelSha256 ?? this.modelSha256,
      engineInstanceId: engineInstanceId ?? this.engineInstanceId,
      calibrationId: calibrationId ?? this.calibrationId,
      openEarRightE6: openEarRightE6 ?? this.openEarRightE6,
      openEarLeftE6: openEarLeftE6 ?? this.openEarLeftE6,
      calibrationSamples: calibrationSamples ?? this.calibrationSamples,
      calibrationCoverageE6:
          calibrationCoverageE6 ?? this.calibrationCoverageE6,
      startedEpochMs: startedEpochMs ?? this.startedEpochMs,
      startOffsetMinutes: startOffsetMinutes ?? this.startOffsetMinutes,
      lifecycle: lifecycle ?? this.lifecycle,
      endedEpochMs: endedEpochMs ?? this.endedEpochMs,
      endOffsetMinutes: endOffsetMinutes ?? this.endOffsetMinutes,
      endOffsetMs: endOffsetMs ?? this.endOffsetMs,
      latestDurableOffsetMs:
          latestDurableOffsetMs ?? this.latestDurableOffsetMs,
      recoveredEpochMs: recoveredEpochMs ?? this.recoveredEpochMs,
      integrityStatus: integrityStatus ?? this.integrityStatus,
      recordsLost: recordsLost ?? this.recordsLost,
      activeMs: activeMs ?? this.activeMs,
      evaluableMs: evaluableMs ?? this.evaluableMs,
      nonEvaluableMs: nonEvaluableMs ?? this.nonEvaluableMs,
      pausedMs: pausedMs ?? this.pausedMs,
      closureActivations: closureActivations ?? this.closureActivations,
      tonesPlayed: tonesPlayed ?? this.tonesPlayed,
      tonesFailed: tonesFailed ?? this.tonesFailed,
      pauseCount: pauseCount ?? this.pauseCount,
      knownThroughMs: knownThroughMs ?? this.knownThroughMs,
      knownActiveMs: knownActiveMs ?? this.knownActiveMs,
      knownEvaluableMs: knownEvaluableMs ?? this.knownEvaluableMs,
      knownPausedMs: knownPausedMs ?? this.knownPausedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (cloudSynced.present) {
      map['cloud_synced'] = Variable<bool>(cloudSynced.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (qualificationStatus.present) {
      map['qualification_status'] = Variable<String>(qualificationStatus.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (landmarkSchema.present) {
      map['landmark_schema'] = Variable<String>(landmarkSchema.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (modelSha256.present) {
      map['model_sha256'] = Variable<String>(modelSha256.value);
    }
    if (engineInstanceId.present) {
      map['engine_instance_id'] = Variable<String>(engineInstanceId.value);
    }
    if (calibrationId.present) {
      map['calibration_id'] = Variable<String>(calibrationId.value);
    }
    if (openEarRightE6.present) {
      map['open_ear_right_e6'] = Variable<int>(openEarRightE6.value);
    }
    if (openEarLeftE6.present) {
      map['open_ear_left_e6'] = Variable<int>(openEarLeftE6.value);
    }
    if (calibrationSamples.present) {
      map['calibration_samples'] = Variable<int>(calibrationSamples.value);
    }
    if (calibrationCoverageE6.present) {
      map['calibration_coverage_e6'] = Variable<int>(
        calibrationCoverageE6.value,
      );
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
    if (recoveredEpochMs.present) {
      map['recovered_epoch_ms'] = Variable<int>(recoveredEpochMs.value);
    }
    if (integrityStatus.present) {
      map['integrity_status'] = Variable<String>(integrityStatus.value);
    }
    if (recordsLost.present) {
      map['records_lost'] = Variable<int>(recordsLost.value);
    }
    if (activeMs.present) {
      map['active_ms'] = Variable<int>(activeMs.value);
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
    if (closureActivations.present) {
      map['closure_activations'] = Variable<int>(closureActivations.value);
    }
    if (tonesPlayed.present) {
      map['tones_played'] = Variable<int>(tonesPlayed.value);
    }
    if (tonesFailed.present) {
      map['tones_failed'] = Variable<int>(tonesFailed.value);
    }
    if (pauseCount.present) {
      map['pause_count'] = Variable<int>(pauseCount.value);
    }
    if (knownThroughMs.present) {
      map['known_through_ms'] = Variable<int>(knownThroughMs.value);
    }
    if (knownActiveMs.present) {
      map['known_active_ms'] = Variable<int>(knownActiveMs.value);
    }
    if (knownEvaluableMs.present) {
      map['known_evaluable_ms'] = Variable<int>(knownEvaluableMs.value);
    }
    if (knownPausedMs.present) {
      map['known_paused_ms'] = Variable<int>(knownPausedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentalSessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('accountId: $accountId, ')
          ..write('cloudSynced: $cloudSynced, ')
          ..write('origin: $origin, ')
          ..write('qualificationStatus: $qualificationStatus, ')
          ..write('profileId: $profileId, ')
          ..write('landmarkSchema: $landmarkSchema, ')
          ..write('modelId: $modelId, ')
          ..write('modelSha256: $modelSha256, ')
          ..write('engineInstanceId: $engineInstanceId, ')
          ..write('calibrationId: $calibrationId, ')
          ..write('openEarRightE6: $openEarRightE6, ')
          ..write('openEarLeftE6: $openEarLeftE6, ')
          ..write('calibrationSamples: $calibrationSamples, ')
          ..write('calibrationCoverageE6: $calibrationCoverageE6, ')
          ..write('startedEpochMs: $startedEpochMs, ')
          ..write('startOffsetMinutes: $startOffsetMinutes, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('endedEpochMs: $endedEpochMs, ')
          ..write('endOffsetMinutes: $endOffsetMinutes, ')
          ..write('endOffsetMs: $endOffsetMs, ')
          ..write('latestDurableOffsetMs: $latestDurableOffsetMs, ')
          ..write('recoveredEpochMs: $recoveredEpochMs, ')
          ..write('integrityStatus: $integrityStatus, ')
          ..write('recordsLost: $recordsLost, ')
          ..write('activeMs: $activeMs, ')
          ..write('evaluableMs: $evaluableMs, ')
          ..write('nonEvaluableMs: $nonEvaluableMs, ')
          ..write('pausedMs: $pausedMs, ')
          ..write('closureActivations: $closureActivations, ')
          ..write('tonesPlayed: $tonesPlayed, ')
          ..write('tonesFailed: $tonesFailed, ')
          ..write('pauseCount: $pauseCount, ')
          ..write('knownThroughMs: $knownThroughMs, ')
          ..write('knownActiveMs: $knownActiveMs, ')
          ..write('knownEvaluableMs: $knownEvaluableMs, ')
          ..write('knownPausedMs: $knownPausedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExperimentalSessionMarksTable extends ExperimentalSessionMarks
    with TableInfo<$ExperimentalSessionMarksTable, ExperimentalMarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExperimentalSessionMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
      'REFERENCES experimental_sessions (session_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _journalSequenceMeta = const VerificationMeta(
    'journalSequence',
  );
  @override
  late final GeneratedColumn<int> journalSequence = GeneratedColumn<int>(
    'journal_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () =>
        kind.isIn(const ['closure', 'playback', 'pauseStarted', 'pauseEnded']),
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
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    check: () => ComparableExpr(ordinal).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playbackOrdinalMeta = const VerificationMeta(
    'playbackOrdinal',
  );
  @override
  late final GeneratedColumn<int> playbackOrdinal = GeneratedColumn<int>(
    'playback_ordinal',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recordId,
    sessionId,
    journalSequence,
    kind,
    offsetMs,
    ordinal,
    playbackOrdinal,
    status,
    errorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'experimental_session_marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExperimentalMarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('journal_sequence')) {
      context.handle(
        _journalSequenceMeta,
        journalSequence.isAcceptableOrUnknown(
          data['journal_sequence']!,
          _journalSequenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_journalSequenceMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('offset_ms')) {
      context.handle(
        _offsetMsMeta,
        offsetMs.isAcceptableOrUnknown(data['offset_ms']!, _offsetMsMeta),
      );
    } else if (isInserting) {
      context.missing(_offsetMsMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('playback_ordinal')) {
      context.handle(
        _playbackOrdinalMeta,
        playbackOrdinal.isAcceptableOrUnknown(
          data['playback_ordinal']!,
          _playbackOrdinalMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordId};
  @override
  ExperimentalMarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExperimentalMarkRow(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      journalSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}journal_sequence'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      offsetMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_ms'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      playbackOrdinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playback_ordinal'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
    );
  }

  @override
  $ExperimentalSessionMarksTable createAlias(String alias) {
    return $ExperimentalSessionMarksTable(attachedDatabase, alias);
  }
}

class ExperimentalMarkRow extends DataClass
    implements Insertable<ExperimentalMarkRow> {
  final String recordId;
  final String sessionId;
  final int journalSequence;

  /// closure, playback, pauseStarted o pauseEnded.
  final String kind;
  final int offsetMs;
  final int ordinal;

  /// Intento de tono dentro de la activación.
  final int? playbackOrdinal;

  /// Resultado técnico del tono: started o failed (no acredita audición).
  final String? status;
  final String? errorCode;
  const ExperimentalMarkRow({
    required this.recordId,
    required this.sessionId,
    required this.journalSequence,
    required this.kind,
    required this.offsetMs,
    required this.ordinal,
    this.playbackOrdinal,
    this.status,
    this.errorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    map['session_id'] = Variable<String>(sessionId);
    map['journal_sequence'] = Variable<int>(journalSequence);
    map['kind'] = Variable<String>(kind);
    map['offset_ms'] = Variable<int>(offsetMs);
    map['ordinal'] = Variable<int>(ordinal);
    if (!nullToAbsent || playbackOrdinal != null) {
      map['playback_ordinal'] = Variable<int>(playbackOrdinal);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    return map;
  }

  ExperimentalSessionMarksCompanion toCompanion(bool nullToAbsent) {
    return ExperimentalSessionMarksCompanion(
      recordId: Value(recordId),
      sessionId: Value(sessionId),
      journalSequence: Value(journalSequence),
      kind: Value(kind),
      offsetMs: Value(offsetMs),
      ordinal: Value(ordinal),
      playbackOrdinal: playbackOrdinal == null && nullToAbsent
          ? const Value.absent()
          : Value(playbackOrdinal),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
    );
  }

  factory ExperimentalMarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExperimentalMarkRow(
      recordId: serializer.fromJson<String>(json['recordId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      journalSequence: serializer.fromJson<int>(json['journalSequence']),
      kind: serializer.fromJson<String>(json['kind']),
      offsetMs: serializer.fromJson<int>(json['offsetMs']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      playbackOrdinal: serializer.fromJson<int?>(json['playbackOrdinal']),
      status: serializer.fromJson<String?>(json['status']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'sessionId': serializer.toJson<String>(sessionId),
      'journalSequence': serializer.toJson<int>(journalSequence),
      'kind': serializer.toJson<String>(kind),
      'offsetMs': serializer.toJson<int>(offsetMs),
      'ordinal': serializer.toJson<int>(ordinal),
      'playbackOrdinal': serializer.toJson<int?>(playbackOrdinal),
      'status': serializer.toJson<String?>(status),
      'errorCode': serializer.toJson<String?>(errorCode),
    };
  }

  ExperimentalMarkRow copyWith({
    String? recordId,
    String? sessionId,
    int? journalSequence,
    String? kind,
    int? offsetMs,
    int? ordinal,
    Value<int?> playbackOrdinal = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> errorCode = const Value.absent(),
  }) => ExperimentalMarkRow(
    recordId: recordId ?? this.recordId,
    sessionId: sessionId ?? this.sessionId,
    journalSequence: journalSequence ?? this.journalSequence,
    kind: kind ?? this.kind,
    offsetMs: offsetMs ?? this.offsetMs,
    ordinal: ordinal ?? this.ordinal,
    playbackOrdinal: playbackOrdinal.present
        ? playbackOrdinal.value
        : this.playbackOrdinal,
    status: status.present ? status.value : this.status,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
  );
  ExperimentalMarkRow copyWithCompanion(
    ExperimentalSessionMarksCompanion data,
  ) {
    return ExperimentalMarkRow(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      journalSequence: data.journalSequence.present
          ? data.journalSequence.value
          : this.journalSequence,
      kind: data.kind.present ? data.kind.value : this.kind,
      offsetMs: data.offsetMs.present ? data.offsetMs.value : this.offsetMs,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      playbackOrdinal: data.playbackOrdinal.present
          ? data.playbackOrdinal.value
          : this.playbackOrdinal,
      status: data.status.present ? data.status.value : this.status,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentalMarkRow(')
          ..write('recordId: $recordId, ')
          ..write('sessionId: $sessionId, ')
          ..write('journalSequence: $journalSequence, ')
          ..write('kind: $kind, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('ordinal: $ordinal, ')
          ..write('playbackOrdinal: $playbackOrdinal, ')
          ..write('status: $status, ')
          ..write('errorCode: $errorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    recordId,
    sessionId,
    journalSequence,
    kind,
    offsetMs,
    ordinal,
    playbackOrdinal,
    status,
    errorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExperimentalMarkRow &&
          other.recordId == this.recordId &&
          other.sessionId == this.sessionId &&
          other.journalSequence == this.journalSequence &&
          other.kind == this.kind &&
          other.offsetMs == this.offsetMs &&
          other.ordinal == this.ordinal &&
          other.playbackOrdinal == this.playbackOrdinal &&
          other.status == this.status &&
          other.errorCode == this.errorCode);
}

class ExperimentalSessionMarksCompanion
    extends UpdateCompanion<ExperimentalMarkRow> {
  final Value<String> recordId;
  final Value<String> sessionId;
  final Value<int> journalSequence;
  final Value<String> kind;
  final Value<int> offsetMs;
  final Value<int> ordinal;
  final Value<int?> playbackOrdinal;
  final Value<String?> status;
  final Value<String?> errorCode;
  final Value<int> rowid;
  const ExperimentalSessionMarksCompanion({
    this.recordId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.journalSequence = const Value.absent(),
    this.kind = const Value.absent(),
    this.offsetMs = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.playbackOrdinal = const Value.absent(),
    this.status = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExperimentalSessionMarksCompanion.insert({
    required String recordId,
    required String sessionId,
    required int journalSequence,
    required String kind,
    required int offsetMs,
    required int ordinal,
    this.playbackOrdinal = const Value.absent(),
    this.status = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : recordId = Value(recordId),
       sessionId = Value(sessionId),
       journalSequence = Value(journalSequence),
       kind = Value(kind),
       offsetMs = Value(offsetMs),
       ordinal = Value(ordinal);
  static Insertable<ExperimentalMarkRow> custom({
    Expression<String>? recordId,
    Expression<String>? sessionId,
    Expression<int>? journalSequence,
    Expression<String>? kind,
    Expression<int>? offsetMs,
    Expression<int>? ordinal,
    Expression<int>? playbackOrdinal,
    Expression<String>? status,
    Expression<String>? errorCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (sessionId != null) 'session_id': sessionId,
      if (journalSequence != null) 'journal_sequence': journalSequence,
      if (kind != null) 'kind': kind,
      if (offsetMs != null) 'offset_ms': offsetMs,
      if (ordinal != null) 'ordinal': ordinal,
      if (playbackOrdinal != null) 'playback_ordinal': playbackOrdinal,
      if (status != null) 'status': status,
      if (errorCode != null) 'error_code': errorCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExperimentalSessionMarksCompanion copyWith({
    Value<String>? recordId,
    Value<String>? sessionId,
    Value<int>? journalSequence,
    Value<String>? kind,
    Value<int>? offsetMs,
    Value<int>? ordinal,
    Value<int?>? playbackOrdinal,
    Value<String?>? status,
    Value<String?>? errorCode,
    Value<int>? rowid,
  }) {
    return ExperimentalSessionMarksCompanion(
      recordId: recordId ?? this.recordId,
      sessionId: sessionId ?? this.sessionId,
      journalSequence: journalSequence ?? this.journalSequence,
      kind: kind ?? this.kind,
      offsetMs: offsetMs ?? this.offsetMs,
      ordinal: ordinal ?? this.ordinal,
      playbackOrdinal: playbackOrdinal ?? this.playbackOrdinal,
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (journalSequence.present) {
      map['journal_sequence'] = Variable<int>(journalSequence.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (offsetMs.present) {
      map['offset_ms'] = Variable<int>(offsetMs.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (playbackOrdinal.present) {
      map['playback_ordinal'] = Variable<int>(playbackOrdinal.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExperimentalSessionMarksCompanion(')
          ..write('recordId: $recordId, ')
          ..write('sessionId: $sessionId, ')
          ..write('journalSequence: $journalSequence, ')
          ..write('kind: $kind, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('ordinal: $ordinal, ')
          ..write('playbackOrdinal: $playbackOrdinal, ')
          ..write('status: $status, ')
          ..write('errorCode: $errorCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportedRecordsTable extends ImportedRecords
    with TableInfo<$ImportedRecordsTable, ImportedRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportedRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _journalSequenceMeta = const VerificationMeta(
    'journalSequence',
  );
  @override
  late final GeneratedColumn<int> journalSequence = GeneratedColumn<int>(
    'journal_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _payloadHashMeta = const VerificationMeta(
    'payloadHash',
  );
  @override
  late final GeneratedColumn<String> payloadHash = GeneratedColumn<String>(
    'payload_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordTypeMeta = const VerificationMeta(
    'recordType',
  );
  @override
  late final GeneratedColumn<String> recordType = GeneratedColumn<String>(
    'record_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recordId,
    journalSequence,
    payloadHash,
    recordType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'imported_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportedRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('journal_sequence')) {
      context.handle(
        _journalSequenceMeta,
        journalSequence.isAcceptableOrUnknown(
          data['journal_sequence']!,
          _journalSequenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_journalSequenceMeta);
    }
    if (data.containsKey('payload_hash')) {
      context.handle(
        _payloadHashMeta,
        payloadHash.isAcceptableOrUnknown(
          data['payload_hash']!,
          _payloadHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadHashMeta);
    }
    if (data.containsKey('record_type')) {
      context.handle(
        _recordTypeMeta,
        recordType.isAcceptableOrUnknown(data['record_type']!, _recordTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_recordTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordId};
  @override
  ImportedRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportedRecordRow(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      journalSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}journal_sequence'],
      )!,
      payloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_hash'],
      )!,
      recordType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_type'],
      )!,
    );
  }

  @override
  $ImportedRecordsTable createAlias(String alias) {
    return $ImportedRecordsTable(attachedDatabase, alias);
  }
}

class ImportedRecordRow extends DataClass
    implements Insertable<ImportedRecordRow> {
  final String recordId;
  final int journalSequence;
  final String payloadHash;
  final String recordType;
  const ImportedRecordRow({
    required this.recordId,
    required this.journalSequence,
    required this.payloadHash,
    required this.recordType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    map['journal_sequence'] = Variable<int>(journalSequence);
    map['payload_hash'] = Variable<String>(payloadHash);
    map['record_type'] = Variable<String>(recordType);
    return map;
  }

  ImportedRecordsCompanion toCompanion(bool nullToAbsent) {
    return ImportedRecordsCompanion(
      recordId: Value(recordId),
      journalSequence: Value(journalSequence),
      payloadHash: Value(payloadHash),
      recordType: Value(recordType),
    );
  }

  factory ImportedRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportedRecordRow(
      recordId: serializer.fromJson<String>(json['recordId']),
      journalSequence: serializer.fromJson<int>(json['journalSequence']),
      payloadHash: serializer.fromJson<String>(json['payloadHash']),
      recordType: serializer.fromJson<String>(json['recordType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'journalSequence': serializer.toJson<int>(journalSequence),
      'payloadHash': serializer.toJson<String>(payloadHash),
      'recordType': serializer.toJson<String>(recordType),
    };
  }

  ImportedRecordRow copyWith({
    String? recordId,
    int? journalSequence,
    String? payloadHash,
    String? recordType,
  }) => ImportedRecordRow(
    recordId: recordId ?? this.recordId,
    journalSequence: journalSequence ?? this.journalSequence,
    payloadHash: payloadHash ?? this.payloadHash,
    recordType: recordType ?? this.recordType,
  );
  ImportedRecordRow copyWithCompanion(ImportedRecordsCompanion data) {
    return ImportedRecordRow(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      journalSequence: data.journalSequence.present
          ? data.journalSequence.value
          : this.journalSequence,
      payloadHash: data.payloadHash.present
          ? data.payloadHash.value
          : this.payloadHash,
      recordType: data.recordType.present
          ? data.recordType.value
          : this.recordType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportedRecordRow(')
          ..write('recordId: $recordId, ')
          ..write('journalSequence: $journalSequence, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('recordType: $recordType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(recordId, journalSequence, payloadHash, recordType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportedRecordRow &&
          other.recordId == this.recordId &&
          other.journalSequence == this.journalSequence &&
          other.payloadHash == this.payloadHash &&
          other.recordType == this.recordType);
}

class ImportedRecordsCompanion extends UpdateCompanion<ImportedRecordRow> {
  final Value<String> recordId;
  final Value<int> journalSequence;
  final Value<String> payloadHash;
  final Value<String> recordType;
  final Value<int> rowid;
  const ImportedRecordsCompanion({
    this.recordId = const Value.absent(),
    this.journalSequence = const Value.absent(),
    this.payloadHash = const Value.absent(),
    this.recordType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportedRecordsCompanion.insert({
    required String recordId,
    required int journalSequence,
    required String payloadHash,
    required String recordType,
    this.rowid = const Value.absent(),
  }) : recordId = Value(recordId),
       journalSequence = Value(journalSequence),
       payloadHash = Value(payloadHash),
       recordType = Value(recordType);
  static Insertable<ImportedRecordRow> custom({
    Expression<String>? recordId,
    Expression<int>? journalSequence,
    Expression<String>? payloadHash,
    Expression<String>? recordType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (journalSequence != null) 'journal_sequence': journalSequence,
      if (payloadHash != null) 'payload_hash': payloadHash,
      if (recordType != null) 'record_type': recordType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportedRecordsCompanion copyWith({
    Value<String>? recordId,
    Value<int>? journalSequence,
    Value<String>? payloadHash,
    Value<String>? recordType,
    Value<int>? rowid,
  }) {
    return ImportedRecordsCompanion(
      recordId: recordId ?? this.recordId,
      journalSequence: journalSequence ?? this.journalSequence,
      payloadHash: payloadHash ?? this.payloadHash,
      recordType: recordType ?? this.recordType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (journalSequence.present) {
      map['journal_sequence'] = Variable<int>(journalSequence.value);
    }
    if (payloadHash.present) {
      map['payload_hash'] = Variable<String>(payloadHash.value);
    }
    if (recordType.present) {
      map['record_type'] = Variable<String>(recordType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportedRecordsCompanion(')
          ..write('recordId: $recordId, ')
          ..write('journalSequence: $journalSequence, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('recordType: $recordType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RealPreferencesTable extends RealPreferences
    with TableInfo<$RealPreferencesTable, RealPreferencesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RealPreferencesTable(this.attachedDatabase, [this._alias]);
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
    check: () =>
        soundPatternId.isIn(const ['patron_1', 'patron_2', 'patron_3']),
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
    Insertable<RealPreferencesRow> instance, {
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
  RealPreferencesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RealPreferencesRow(
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
  $RealPreferencesTable createAlias(String alias) {
    return $RealPreferencesTable(attachedDatabase, alias);
  }
}

class RealPreferencesRow extends DataClass
    implements Insertable<RealPreferencesRow> {
  final int singleton;
  final String theme;

  /// Solo patrones del catálogo local incluido (Área 06 §9: sin inventar IDs).
  final String soundPatternId;
  final bool reducedMotion;
  final int updatedEpochMs;
  const RealPreferencesRow({
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

  RealPreferencesCompanion toCompanion(bool nullToAbsent) {
    return RealPreferencesCompanion(
      singleton: Value(singleton),
      theme: Value(theme),
      soundPatternId: Value(soundPatternId),
      reducedMotion: Value(reducedMotion),
      updatedEpochMs: Value(updatedEpochMs),
    );
  }

  factory RealPreferencesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RealPreferencesRow(
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

  RealPreferencesRow copyWith({
    int? singleton,
    String? theme,
    String? soundPatternId,
    bool? reducedMotion,
    int? updatedEpochMs,
  }) => RealPreferencesRow(
    singleton: singleton ?? this.singleton,
    theme: theme ?? this.theme,
    soundPatternId: soundPatternId ?? this.soundPatternId,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    updatedEpochMs: updatedEpochMs ?? this.updatedEpochMs,
  );
  RealPreferencesRow copyWithCompanion(RealPreferencesCompanion data) {
    return RealPreferencesRow(
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
    return (StringBuffer('RealPreferencesRow(')
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
      (other is RealPreferencesRow &&
          other.singleton == this.singleton &&
          other.theme == this.theme &&
          other.soundPatternId == this.soundPatternId &&
          other.reducedMotion == this.reducedMotion &&
          other.updatedEpochMs == this.updatedEpochMs);
}

class RealPreferencesCompanion extends UpdateCompanion<RealPreferencesRow> {
  final Value<int> singleton;
  final Value<String> theme;
  final Value<String> soundPatternId;
  final Value<bool> reducedMotion;
  final Value<int> updatedEpochMs;
  const RealPreferencesCompanion({
    this.singleton = const Value.absent(),
    this.theme = const Value.absent(),
    this.soundPatternId = const Value.absent(),
    this.reducedMotion = const Value.absent(),
    this.updatedEpochMs = const Value.absent(),
  });
  RealPreferencesCompanion.insert({
    this.singleton = const Value.absent(),
    required String theme,
    required String soundPatternId,
    required bool reducedMotion,
    required int updatedEpochMs,
  }) : theme = Value(theme),
       soundPatternId = Value(soundPatternId),
       reducedMotion = Value(reducedMotion),
       updatedEpochMs = Value(updatedEpochMs);
  static Insertable<RealPreferencesRow> custom({
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

  RealPreferencesCompanion copyWith({
    Value<int>? singleton,
    Value<String>? theme,
    Value<String>? soundPatternId,
    Value<bool>? reducedMotion,
    Value<int>? updatedEpochMs,
  }) {
    return RealPreferencesCompanion(
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
    return (StringBuffer('RealPreferencesCompanion(')
          ..write('singleton: $singleton, ')
          ..write('theme: $theme, ')
          ..write('soundPatternId: $soundPatternId, ')
          ..write('reducedMotion: $reducedMotion, ')
          ..write('updatedEpochMs: $updatedEpochMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$ExperimentalHistoryDatabase extends GeneratedDatabase {
  _$ExperimentalHistoryDatabase(QueryExecutor e) : super(e);
  $ExperimentalHistoryDatabaseManager get managers =>
      $ExperimentalHistoryDatabaseManager(this);
  late final $ExperimentalSessionsTable experimentalSessions =
      $ExperimentalSessionsTable(this);
  late final $ExperimentalSessionMarksTable experimentalSessionMarks =
      $ExperimentalSessionMarksTable(this);
  late final $ImportedRecordsTable importedRecords = $ImportedRecordsTable(
    this,
  );
  late final $RealPreferencesTable realPreferences = $RealPreferencesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    experimentalSessions,
    experimentalSessionMarks,
    importedRecords,
    realPreferences,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'experimental_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('experimental_session_marks', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$ExperimentalSessionsTableCreateCompanionBuilder =
    ExperimentalSessionsCompanion Function({
      required String sessionId,
      Value<String?> accountId,
      Value<bool> cloudSynced,
      Value<String> origin,
      Value<String> qualificationStatus,
      required String profileId,
      required String landmarkSchema,
      required String modelId,
      required String modelSha256,
      required String engineInstanceId,
      required String calibrationId,
      required int openEarRightE6,
      required int openEarLeftE6,
      required int calibrationSamples,
      required int calibrationCoverageE6,
      required int startedEpochMs,
      required int startOffsetMinutes,
      required String lifecycle,
      Value<int?> endedEpochMs,
      Value<int?> endOffsetMinutes,
      Value<int?> endOffsetMs,
      required int latestDurableOffsetMs,
      Value<int?> recoveredEpochMs,
      required String integrityStatus,
      Value<int> recordsLost,
      Value<int?> activeMs,
      Value<int?> evaluableMs,
      Value<int?> nonEvaluableMs,
      Value<int?> pausedMs,
      Value<int?> closureActivations,
      Value<int?> tonesPlayed,
      Value<int?> tonesFailed,
      Value<int?> pauseCount,
      Value<int?> knownThroughMs,
      Value<int?> knownActiveMs,
      Value<int?> knownEvaluableMs,
      Value<int?> knownPausedMs,
      Value<int> rowid,
    });
typedef $$ExperimentalSessionsTableUpdateCompanionBuilder =
    ExperimentalSessionsCompanion Function({
      Value<String> sessionId,
      Value<String?> accountId,
      Value<bool> cloudSynced,
      Value<String> origin,
      Value<String> qualificationStatus,
      Value<String> profileId,
      Value<String> landmarkSchema,
      Value<String> modelId,
      Value<String> modelSha256,
      Value<String> engineInstanceId,
      Value<String> calibrationId,
      Value<int> openEarRightE6,
      Value<int> openEarLeftE6,
      Value<int> calibrationSamples,
      Value<int> calibrationCoverageE6,
      Value<int> startedEpochMs,
      Value<int> startOffsetMinutes,
      Value<String> lifecycle,
      Value<int?> endedEpochMs,
      Value<int?> endOffsetMinutes,
      Value<int?> endOffsetMs,
      Value<int> latestDurableOffsetMs,
      Value<int?> recoveredEpochMs,
      Value<String> integrityStatus,
      Value<int> recordsLost,
      Value<int?> activeMs,
      Value<int?> evaluableMs,
      Value<int?> nonEvaluableMs,
      Value<int?> pausedMs,
      Value<int?> closureActivations,
      Value<int?> tonesPlayed,
      Value<int?> tonesFailed,
      Value<int?> pauseCount,
      Value<int?> knownThroughMs,
      Value<int?> knownActiveMs,
      Value<int?> knownEvaluableMs,
      Value<int?> knownPausedMs,
      Value<int> rowid,
    });

final class $$ExperimentalSessionsTableReferences
    extends
        BaseReferences<
          _$ExperimentalHistoryDatabase,
          $ExperimentalSessionsTable,
          ExperimentalSessionRow
        > {
  $$ExperimentalSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $ExperimentalSessionMarksTable,
    List<ExperimentalMarkRow>
  >
  _experimentalSessionMarksRefsTable(_$ExperimentalHistoryDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.experimentalSessionMarks,
        aliasName: 'experimental_sessions__session_id__experimental_session_marks__session_id',
      );

  $$ExperimentalSessionMarksTableProcessedTableManager
  get experimentalSessionMarksRefs {
    final manager =
        $$ExperimentalSessionMarksTableTableManager(
          $_db,
          $_db.experimentalSessionMarks,
        ).filter(
          (f) => f.sessionId.sessionId.sqlEquals(
            $_itemColumn<String>('session_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _experimentalSessionMarksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExperimentalSessionsTableFilterComposer
    extends
        Composer<_$ExperimentalHistoryDatabase, $ExperimentalSessionsTable> {
  $$ExperimentalSessionsTableFilterComposer({
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

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cloudSynced => $composableBuilder(
    column: $table.cloudSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualificationStatus => $composableBuilder(
    column: $table.qualificationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get landmarkSchema => $composableBuilder(
    column: $table.landmarkSchema,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelSha256 => $composableBuilder(
    column: $table.modelSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engineInstanceId => $composableBuilder(
    column: $table.engineInstanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calibrationId => $composableBuilder(
    column: $table.calibrationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openEarRightE6 => $composableBuilder(
    column: $table.openEarRightE6,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openEarLeftE6 => $composableBuilder(
    column: $table.openEarLeftE6,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calibrationSamples => $composableBuilder(
    column: $table.calibrationSamples,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calibrationCoverageE6 => $composableBuilder(
    column: $table.calibrationCoverageE6,
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

  ColumnFilters<int> get recoveredEpochMs => $composableBuilder(
    column: $table.recoveredEpochMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get integrityStatus => $composableBuilder(
    column: $table.integrityStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordsLost => $composableBuilder(
    column: $table.recordsLost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMs => $composableBuilder(
    column: $table.activeMs,
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

  ColumnFilters<int> get closureActivations => $composableBuilder(
    column: $table.closureActivations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tonesPlayed => $composableBuilder(
    column: $table.tonesPlayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tonesFailed => $composableBuilder(
    column: $table.tonesFailed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get knownThroughMs => $composableBuilder(
    column: $table.knownThroughMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get knownActiveMs => $composableBuilder(
    column: $table.knownActiveMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get knownEvaluableMs => $composableBuilder(
    column: $table.knownEvaluableMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get knownPausedMs => $composableBuilder(
    column: $table.knownPausedMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> experimentalSessionMarksRefs(
    Expression<bool> Function($$ExperimentalSessionMarksTableFilterComposer f)
    f,
  ) {
    final $$ExperimentalSessionMarksTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionId,
          referencedTable: $db.experimentalSessionMarks,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentalSessionMarksTableFilterComposer(
                $db: $db,
                $table: $db.experimentalSessionMarks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExperimentalSessionsTableOrderingComposer
    extends
        Composer<_$ExperimentalHistoryDatabase, $ExperimentalSessionsTable> {
  $$ExperimentalSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cloudSynced => $composableBuilder(
    column: $table.cloudSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualificationStatus => $composableBuilder(
    column: $table.qualificationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get landmarkSchema => $composableBuilder(
    column: $table.landmarkSchema,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelSha256 => $composableBuilder(
    column: $table.modelSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engineInstanceId => $composableBuilder(
    column: $table.engineInstanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calibrationId => $composableBuilder(
    column: $table.calibrationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openEarRightE6 => $composableBuilder(
    column: $table.openEarRightE6,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openEarLeftE6 => $composableBuilder(
    column: $table.openEarLeftE6,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calibrationSamples => $composableBuilder(
    column: $table.calibrationSamples,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calibrationCoverageE6 => $composableBuilder(
    column: $table.calibrationCoverageE6,
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

  ColumnOrderings<int> get recoveredEpochMs => $composableBuilder(
    column: $table.recoveredEpochMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get integrityStatus => $composableBuilder(
    column: $table.integrityStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordsLost => $composableBuilder(
    column: $table.recordsLost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMs => $composableBuilder(
    column: $table.activeMs,
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

  ColumnOrderings<int> get closureActivations => $composableBuilder(
    column: $table.closureActivations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tonesPlayed => $composableBuilder(
    column: $table.tonesPlayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tonesFailed => $composableBuilder(
    column: $table.tonesFailed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get knownThroughMs => $composableBuilder(
    column: $table.knownThroughMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get knownActiveMs => $composableBuilder(
    column: $table.knownActiveMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get knownEvaluableMs => $composableBuilder(
    column: $table.knownEvaluableMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get knownPausedMs => $composableBuilder(
    column: $table.knownPausedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExperimentalSessionsTableAnnotationComposer
    extends
        Composer<_$ExperimentalHistoryDatabase, $ExperimentalSessionsTable> {
  $$ExperimentalSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<bool> get cloudSynced => $composableBuilder(
    column: $table.cloudSynced,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get qualificationStatus => $composableBuilder(
    column: $table.qualificationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get landmarkSchema => $composableBuilder(
    column: $table.landmarkSchema,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get modelSha256 => $composableBuilder(
    column: $table.modelSha256,
    builder: (column) => column,
  );

  GeneratedColumn<String> get engineInstanceId => $composableBuilder(
    column: $table.engineInstanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calibrationId => $composableBuilder(
    column: $table.calibrationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openEarRightE6 => $composableBuilder(
    column: $table.openEarRightE6,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openEarLeftE6 => $composableBuilder(
    column: $table.openEarLeftE6,
    builder: (column) => column,
  );

  GeneratedColumn<int> get calibrationSamples => $composableBuilder(
    column: $table.calibrationSamples,
    builder: (column) => column,
  );

  GeneratedColumn<int> get calibrationCoverageE6 => $composableBuilder(
    column: $table.calibrationCoverageE6,
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

  GeneratedColumn<int> get recoveredEpochMs => $composableBuilder(
    column: $table.recoveredEpochMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get integrityStatus => $composableBuilder(
    column: $table.integrityStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordsLost => $composableBuilder(
    column: $table.recordsLost,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activeMs =>
      $composableBuilder(column: $table.activeMs, builder: (column) => column);

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

  GeneratedColumn<int> get closureActivations => $composableBuilder(
    column: $table.closureActivations,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tonesPlayed => $composableBuilder(
    column: $table.tonesPlayed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tonesFailed => $composableBuilder(
    column: $table.tonesFailed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get knownThroughMs => $composableBuilder(
    column: $table.knownThroughMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get knownActiveMs => $composableBuilder(
    column: $table.knownActiveMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get knownEvaluableMs => $composableBuilder(
    column: $table.knownEvaluableMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get knownPausedMs => $composableBuilder(
    column: $table.knownPausedMs,
    builder: (column) => column,
  );

  Expression<T> experimentalSessionMarksRefs<T extends Object>(
    Expression<T> Function($$ExperimentalSessionMarksTableAnnotationComposer a)
    f,
  ) {
    final $$ExperimentalSessionMarksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionId,
          referencedTable: $db.experimentalSessionMarks,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentalSessionMarksTableAnnotationComposer(
                $db: $db,
                $table: $db.experimentalSessionMarks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExperimentalSessionsTableTableManager
    extends
        RootTableManager<
          _$ExperimentalHistoryDatabase,
          $ExperimentalSessionsTable,
          ExperimentalSessionRow,
          $$ExperimentalSessionsTableFilterComposer,
          $$ExperimentalSessionsTableOrderingComposer,
          $$ExperimentalSessionsTableAnnotationComposer,
          $$ExperimentalSessionsTableCreateCompanionBuilder,
          $$ExperimentalSessionsTableUpdateCompanionBuilder,
          (ExperimentalSessionRow, $$ExperimentalSessionsTableReferences),
          ExperimentalSessionRow,
          PrefetchHooks Function({bool experimentalSessionMarksRefs})
        > {
  $$ExperimentalSessionsTableTableManager(
    _$ExperimentalHistoryDatabase db,
    $ExperimentalSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExperimentalSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExperimentalSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExperimentalSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<bool> cloudSynced = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> qualificationStatus = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> landmarkSchema = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<String> modelSha256 = const Value.absent(),
                Value<String> engineInstanceId = const Value.absent(),
                Value<String> calibrationId = const Value.absent(),
                Value<int> openEarRightE6 = const Value.absent(),
                Value<int> openEarLeftE6 = const Value.absent(),
                Value<int> calibrationSamples = const Value.absent(),
                Value<int> calibrationCoverageE6 = const Value.absent(),
                Value<int> startedEpochMs = const Value.absent(),
                Value<int> startOffsetMinutes = const Value.absent(),
                Value<String> lifecycle = const Value.absent(),
                Value<int?> endedEpochMs = const Value.absent(),
                Value<int?> endOffsetMinutes = const Value.absent(),
                Value<int?> endOffsetMs = const Value.absent(),
                Value<int> latestDurableOffsetMs = const Value.absent(),
                Value<int?> recoveredEpochMs = const Value.absent(),
                Value<String> integrityStatus = const Value.absent(),
                Value<int> recordsLost = const Value.absent(),
                Value<int?> activeMs = const Value.absent(),
                Value<int?> evaluableMs = const Value.absent(),
                Value<int?> nonEvaluableMs = const Value.absent(),
                Value<int?> pausedMs = const Value.absent(),
                Value<int?> closureActivations = const Value.absent(),
                Value<int?> tonesPlayed = const Value.absent(),
                Value<int?> tonesFailed = const Value.absent(),
                Value<int?> pauseCount = const Value.absent(),
                Value<int?> knownThroughMs = const Value.absent(),
                Value<int?> knownActiveMs = const Value.absent(),
                Value<int?> knownEvaluableMs = const Value.absent(),
                Value<int?> knownPausedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExperimentalSessionsCompanion(
                sessionId: sessionId,
                accountId: accountId,
                cloudSynced: cloudSynced,
                origin: origin,
                qualificationStatus: qualificationStatus,
                profileId: profileId,
                landmarkSchema: landmarkSchema,
                modelId: modelId,
                modelSha256: modelSha256,
                engineInstanceId: engineInstanceId,
                calibrationId: calibrationId,
                openEarRightE6: openEarRightE6,
                openEarLeftE6: openEarLeftE6,
                calibrationSamples: calibrationSamples,
                calibrationCoverageE6: calibrationCoverageE6,
                startedEpochMs: startedEpochMs,
                startOffsetMinutes: startOffsetMinutes,
                lifecycle: lifecycle,
                endedEpochMs: endedEpochMs,
                endOffsetMinutes: endOffsetMinutes,
                endOffsetMs: endOffsetMs,
                latestDurableOffsetMs: latestDurableOffsetMs,
                recoveredEpochMs: recoveredEpochMs,
                integrityStatus: integrityStatus,
                recordsLost: recordsLost,
                activeMs: activeMs,
                evaluableMs: evaluableMs,
                nonEvaluableMs: nonEvaluableMs,
                pausedMs: pausedMs,
                closureActivations: closureActivations,
                tonesPlayed: tonesPlayed,
                tonesFailed: tonesFailed,
                pauseCount: pauseCount,
                knownThroughMs: knownThroughMs,
                knownActiveMs: knownActiveMs,
                knownEvaluableMs: knownEvaluableMs,
                knownPausedMs: knownPausedMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                Value<String?> accountId = const Value.absent(),
                Value<bool> cloudSynced = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> qualificationStatus = const Value.absent(),
                required String profileId,
                required String landmarkSchema,
                required String modelId,
                required String modelSha256,
                required String engineInstanceId,
                required String calibrationId,
                required int openEarRightE6,
                required int openEarLeftE6,
                required int calibrationSamples,
                required int calibrationCoverageE6,
                required int startedEpochMs,
                required int startOffsetMinutes,
                required String lifecycle,
                Value<int?> endedEpochMs = const Value.absent(),
                Value<int?> endOffsetMinutes = const Value.absent(),
                Value<int?> endOffsetMs = const Value.absent(),
                required int latestDurableOffsetMs,
                Value<int?> recoveredEpochMs = const Value.absent(),
                required String integrityStatus,
                Value<int> recordsLost = const Value.absent(),
                Value<int?> activeMs = const Value.absent(),
                Value<int?> evaluableMs = const Value.absent(),
                Value<int?> nonEvaluableMs = const Value.absent(),
                Value<int?> pausedMs = const Value.absent(),
                Value<int?> closureActivations = const Value.absent(),
                Value<int?> tonesPlayed = const Value.absent(),
                Value<int?> tonesFailed = const Value.absent(),
                Value<int?> pauseCount = const Value.absent(),
                Value<int?> knownThroughMs = const Value.absent(),
                Value<int?> knownActiveMs = const Value.absent(),
                Value<int?> knownEvaluableMs = const Value.absent(),
                Value<int?> knownPausedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExperimentalSessionsCompanion.insert(
                sessionId: sessionId,
                accountId: accountId,
                cloudSynced: cloudSynced,
                origin: origin,
                qualificationStatus: qualificationStatus,
                profileId: profileId,
                landmarkSchema: landmarkSchema,
                modelId: modelId,
                modelSha256: modelSha256,
                engineInstanceId: engineInstanceId,
                calibrationId: calibrationId,
                openEarRightE6: openEarRightE6,
                openEarLeftE6: openEarLeftE6,
                calibrationSamples: calibrationSamples,
                calibrationCoverageE6: calibrationCoverageE6,
                startedEpochMs: startedEpochMs,
                startOffsetMinutes: startOffsetMinutes,
                lifecycle: lifecycle,
                endedEpochMs: endedEpochMs,
                endOffsetMinutes: endOffsetMinutes,
                endOffsetMs: endOffsetMs,
                latestDurableOffsetMs: latestDurableOffsetMs,
                recoveredEpochMs: recoveredEpochMs,
                integrityStatus: integrityStatus,
                recordsLost: recordsLost,
                activeMs: activeMs,
                evaluableMs: evaluableMs,
                nonEvaluableMs: nonEvaluableMs,
                pausedMs: pausedMs,
                closureActivations: closureActivations,
                tonesPlayed: tonesPlayed,
                tonesFailed: tonesFailed,
                pauseCount: pauseCount,
                knownThroughMs: knownThroughMs,
                knownActiveMs: knownActiveMs,
                knownEvaluableMs: knownEvaluableMs,
                knownPausedMs: knownPausedMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ExperimentalSessionsTable,
                    ExperimentalSessionRow
                  >(table),
                  $$ExperimentalSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({experimentalSessionMarksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (experimentalSessionMarksRefs) db.experimentalSessionMarks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (experimentalSessionMarksRefs)
                    await $_getPrefetchedData<
                      ExperimentalSessionRow,
                      $ExperimentalSessionsTable,
                      ExperimentalMarkRow
                    >(
                      currentTable: table,
                      referencedTable: $$ExperimentalSessionsTableReferences
                          ._experimentalSessionMarksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ExperimentalSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).experimentalSessionMarksRefs,
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

typedef $$ExperimentalSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExperimentalHistoryDatabase,
      $ExperimentalSessionsTable,
      ExperimentalSessionRow,
      $$ExperimentalSessionsTableFilterComposer,
      $$ExperimentalSessionsTableOrderingComposer,
      $$ExperimentalSessionsTableAnnotationComposer,
      $$ExperimentalSessionsTableCreateCompanionBuilder,
      $$ExperimentalSessionsTableUpdateCompanionBuilder,
      (ExperimentalSessionRow, $$ExperimentalSessionsTableReferences),
      ExperimentalSessionRow,
      PrefetchHooks Function({bool experimentalSessionMarksRefs})
    >;
typedef $$ExperimentalSessionMarksTableCreateCompanionBuilder =
    ExperimentalSessionMarksCompanion Function({
      required String recordId,
      required String sessionId,
      required int journalSequence,
      required String kind,
      required int offsetMs,
      required int ordinal,
      Value<int?> playbackOrdinal,
      Value<String?> status,
      Value<String?> errorCode,
      Value<int> rowid,
    });
typedef $$ExperimentalSessionMarksTableUpdateCompanionBuilder =
    ExperimentalSessionMarksCompanion Function({
      Value<String> recordId,
      Value<String> sessionId,
      Value<int> journalSequence,
      Value<String> kind,
      Value<int> offsetMs,
      Value<int> ordinal,
      Value<int?> playbackOrdinal,
      Value<String?> status,
      Value<String?> errorCode,
      Value<int> rowid,
    });

final class $$ExperimentalSessionMarksTableReferences
    extends
        BaseReferences<
          _$ExperimentalHistoryDatabase,
          $ExperimentalSessionMarksTable,
          ExperimentalMarkRow
        > {
  $$ExperimentalSessionMarksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExperimentalSessionsTable _sessionIdTable(
    _$ExperimentalHistoryDatabase db,
  ) => db.experimentalSessions.createAlias(
    'experimental_session_marks__session_id__experimental_sessions__session_id',
  );

  $$ExperimentalSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$ExperimentalSessionsTableTableManager(
      $_db,
      $_db.experimentalSessions,
    ).filter((f) => f.sessionId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExperimentalSessionMarksTableFilterComposer
    extends
        Composer<
          _$ExperimentalHistoryDatabase,
          $ExperimentalSessionMarksTable
        > {
  $$ExperimentalSessionMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get journalSequence => $composableBuilder(
    column: $table.journalSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMs => $composableBuilder(
    column: $table.offsetMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playbackOrdinal => $composableBuilder(
    column: $table.playbackOrdinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  $$ExperimentalSessionsTableFilterComposer get sessionId {
    final $$ExperimentalSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.experimentalSessions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExperimentalSessionsTableFilterComposer(
            $db: $db,
            $table: $db.experimentalSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExperimentalSessionMarksTableOrderingComposer
    extends
        Composer<
          _$ExperimentalHistoryDatabase,
          $ExperimentalSessionMarksTable
        > {
  $$ExperimentalSessionMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get journalSequence => $composableBuilder(
    column: $table.journalSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMs => $composableBuilder(
    column: $table.offsetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playbackOrdinal => $composableBuilder(
    column: $table.playbackOrdinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExperimentalSessionsTableOrderingComposer get sessionId {
    final $$ExperimentalSessionsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionId,
          referencedTable: $db.experimentalSessions,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentalSessionsTableOrderingComposer(
                $db: $db,
                $table: $db.experimentalSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExperimentalSessionMarksTableAnnotationComposer
    extends
        Composer<
          _$ExperimentalHistoryDatabase,
          $ExperimentalSessionMarksTable
        > {
  $$ExperimentalSessionMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get journalSequence => $composableBuilder(
    column: $table.journalSequence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get offsetMs =>
      $composableBuilder(column: $table.offsetMs, builder: (column) => column);

  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<int> get playbackOrdinal => $composableBuilder(
    column: $table.playbackOrdinal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  $$ExperimentalSessionsTableAnnotationComposer get sessionId {
    final $$ExperimentalSessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionId,
          referencedTable: $db.experimentalSessions,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExperimentalSessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.experimentalSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExperimentalSessionMarksTableTableManager
    extends
        RootTableManager<
          _$ExperimentalHistoryDatabase,
          $ExperimentalSessionMarksTable,
          ExperimentalMarkRow,
          $$ExperimentalSessionMarksTableFilterComposer,
          $$ExperimentalSessionMarksTableOrderingComposer,
          $$ExperimentalSessionMarksTableAnnotationComposer,
          $$ExperimentalSessionMarksTableCreateCompanionBuilder,
          $$ExperimentalSessionMarksTableUpdateCompanionBuilder,
          (ExperimentalMarkRow, $$ExperimentalSessionMarksTableReferences),
          ExperimentalMarkRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$ExperimentalSessionMarksTableTableManager(
    _$ExperimentalHistoryDatabase db,
    $ExperimentalSessionMarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExperimentalSessionMarksTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ExperimentalSessionMarksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExperimentalSessionMarksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> journalSequence = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> offsetMs = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<int?> playbackOrdinal = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExperimentalSessionMarksCompanion(
                recordId: recordId,
                sessionId: sessionId,
                journalSequence: journalSequence,
                kind: kind,
                offsetMs: offsetMs,
                ordinal: ordinal,
                playbackOrdinal: playbackOrdinal,
                status: status,
                errorCode: errorCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordId,
                required String sessionId,
                required int journalSequence,
                required String kind,
                required int offsetMs,
                required int ordinal,
                Value<int?> playbackOrdinal = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExperimentalSessionMarksCompanion.insert(
                recordId: recordId,
                sessionId: sessionId,
                journalSequence: journalSequence,
                kind: kind,
                offsetMs: offsetMs,
                ordinal: ordinal,
                playbackOrdinal: playbackOrdinal,
                status: status,
                errorCode: errorCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ExperimentalSessionMarksTable,
                    ExperimentalMarkRow
                  >(table),
                  $$ExperimentalSessionMarksTableReferences(db, table, e),
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
                        referencedTable:
                            $$ExperimentalSessionMarksTableReferences
                                ._sessionIdTable(db),
                        referencedColumn:
                            $$ExperimentalSessionMarksTableReferences
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

typedef $$ExperimentalSessionMarksTableProcessedTableManager =
    ProcessedTableManager<
      _$ExperimentalHistoryDatabase,
      $ExperimentalSessionMarksTable,
      ExperimentalMarkRow,
      $$ExperimentalSessionMarksTableFilterComposer,
      $$ExperimentalSessionMarksTableOrderingComposer,
      $$ExperimentalSessionMarksTableAnnotationComposer,
      $$ExperimentalSessionMarksTableCreateCompanionBuilder,
      $$ExperimentalSessionMarksTableUpdateCompanionBuilder,
      (ExperimentalMarkRow, $$ExperimentalSessionMarksTableReferences),
      ExperimentalMarkRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$ImportedRecordsTableCreateCompanionBuilder =
    ImportedRecordsCompanion Function({
      required String recordId,
      required int journalSequence,
      required String payloadHash,
      required String recordType,
      Value<int> rowid,
    });
typedef $$ImportedRecordsTableUpdateCompanionBuilder =
    ImportedRecordsCompanion Function({
      Value<String> recordId,
      Value<int> journalSequence,
      Value<String> payloadHash,
      Value<String> recordType,
      Value<int> rowid,
    });

class $$ImportedRecordsTableFilterComposer
    extends Composer<_$ExperimentalHistoryDatabase, $ImportedRecordsTable> {
  $$ImportedRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get journalSequence => $composableBuilder(
    column: $table.journalSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportedRecordsTableOrderingComposer
    extends Composer<_$ExperimentalHistoryDatabase, $ImportedRecordsTable> {
  $$ImportedRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get journalSequence => $composableBuilder(
    column: $table.journalSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportedRecordsTableAnnotationComposer
    extends Composer<_$ExperimentalHistoryDatabase, $ImportedRecordsTable> {
  $$ImportedRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get journalSequence => $composableBuilder(
    column: $table.journalSequence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => column,
  );
}

class $$ImportedRecordsTableTableManager
    extends
        RootTableManager<
          _$ExperimentalHistoryDatabase,
          $ImportedRecordsTable,
          ImportedRecordRow,
          $$ImportedRecordsTableFilterComposer,
          $$ImportedRecordsTableOrderingComposer,
          $$ImportedRecordsTableAnnotationComposer,
          $$ImportedRecordsTableCreateCompanionBuilder,
          $$ImportedRecordsTableUpdateCompanionBuilder,
          (
            ImportedRecordRow,
            BaseReferences<
              _$ExperimentalHistoryDatabase,
              $ImportedRecordsTable,
              ImportedRecordRow
            >,
          ),
          ImportedRecordRow,
          PrefetchHooks Function()
        > {
  $$ImportedRecordsTableTableManager(
    _$ExperimentalHistoryDatabase db,
    $ImportedRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportedRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportedRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportedRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                Value<int> journalSequence = const Value.absent(),
                Value<String> payloadHash = const Value.absent(),
                Value<String> recordType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportedRecordsCompanion(
                recordId: recordId,
                journalSequence: journalSequence,
                payloadHash: payloadHash,
                recordType: recordType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordId,
                required int journalSequence,
                required String payloadHash,
                required String recordType,
                Value<int> rowid = const Value.absent(),
              }) => ImportedRecordsCompanion.insert(
                recordId: recordId,
                journalSequence: journalSequence,
                payloadHash: payloadHash,
                recordType: recordType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportedRecordsTable, ImportedRecordRow>(table),
                  BaseReferences<
                    _$ExperimentalHistoryDatabase,
                    $ImportedRecordsTable,
                    ImportedRecordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportedRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExperimentalHistoryDatabase,
      $ImportedRecordsTable,
      ImportedRecordRow,
      $$ImportedRecordsTableFilterComposer,
      $$ImportedRecordsTableOrderingComposer,
      $$ImportedRecordsTableAnnotationComposer,
      $$ImportedRecordsTableCreateCompanionBuilder,
      $$ImportedRecordsTableUpdateCompanionBuilder,
      (
        ImportedRecordRow,
        BaseReferences<
          _$ExperimentalHistoryDatabase,
          $ImportedRecordsTable,
          ImportedRecordRow
        >,
      ),
      ImportedRecordRow,
      PrefetchHooks Function()
    >;
typedef $$RealPreferencesTableCreateCompanionBuilder =
    RealPreferencesCompanion Function({
      Value<int> singleton,
      required String theme,
      required String soundPatternId,
      required bool reducedMotion,
      required int updatedEpochMs,
    });
typedef $$RealPreferencesTableUpdateCompanionBuilder =
    RealPreferencesCompanion Function({
      Value<int> singleton,
      Value<String> theme,
      Value<String> soundPatternId,
      Value<bool> reducedMotion,
      Value<int> updatedEpochMs,
    });

class $$RealPreferencesTableFilterComposer
    extends Composer<_$ExperimentalHistoryDatabase, $RealPreferencesTable> {
  $$RealPreferencesTableFilterComposer({
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

class $$RealPreferencesTableOrderingComposer
    extends Composer<_$ExperimentalHistoryDatabase, $RealPreferencesTable> {
  $$RealPreferencesTableOrderingComposer({
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

class $$RealPreferencesTableAnnotationComposer
    extends Composer<_$ExperimentalHistoryDatabase, $RealPreferencesTable> {
  $$RealPreferencesTableAnnotationComposer({
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

class $$RealPreferencesTableTableManager
    extends
        RootTableManager<
          _$ExperimentalHistoryDatabase,
          $RealPreferencesTable,
          RealPreferencesRow,
          $$RealPreferencesTableFilterComposer,
          $$RealPreferencesTableOrderingComposer,
          $$RealPreferencesTableAnnotationComposer,
          $$RealPreferencesTableCreateCompanionBuilder,
          $$RealPreferencesTableUpdateCompanionBuilder,
          (
            RealPreferencesRow,
            BaseReferences<
              _$ExperimentalHistoryDatabase,
              $RealPreferencesTable,
              RealPreferencesRow
            >,
          ),
          RealPreferencesRow,
          PrefetchHooks Function()
        > {
  $$RealPreferencesTableTableManager(
    _$ExperimentalHistoryDatabase db,
    $RealPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RealPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RealPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RealPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> singleton = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> soundPatternId = const Value.absent(),
                Value<bool> reducedMotion = const Value.absent(),
                Value<int> updatedEpochMs = const Value.absent(),
              }) => RealPreferencesCompanion(
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
              }) => RealPreferencesCompanion.insert(
                singleton: singleton,
                theme: theme,
                soundPatternId: soundPatternId,
                reducedMotion: reducedMotion,
                updatedEpochMs: updatedEpochMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RealPreferencesTable, RealPreferencesRow>(table),
                  BaseReferences<
                    _$ExperimentalHistoryDatabase,
                    $RealPreferencesTable,
                    RealPreferencesRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RealPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$ExperimentalHistoryDatabase,
      $RealPreferencesTable,
      RealPreferencesRow,
      $$RealPreferencesTableFilterComposer,
      $$RealPreferencesTableOrderingComposer,
      $$RealPreferencesTableAnnotationComposer,
      $$RealPreferencesTableCreateCompanionBuilder,
      $$RealPreferencesTableUpdateCompanionBuilder,
      (
        RealPreferencesRow,
        BaseReferences<
          _$ExperimentalHistoryDatabase,
          $RealPreferencesTable,
          RealPreferencesRow
        >,
      ),
      RealPreferencesRow,
      PrefetchHooks Function()
    >;

class $ExperimentalHistoryDatabaseManager {
  final _$ExperimentalHistoryDatabase _db;
  $ExperimentalHistoryDatabaseManager(this._db);
  $$ExperimentalSessionsTableTableManager get experimentalSessions =>
      $$ExperimentalSessionsTableTableManager(_db, _db.experimentalSessions);
  $$ExperimentalSessionMarksTableTableManager get experimentalSessionMarks =>
      $$ExperimentalSessionMarksTableTableManager(
        _db,
        _db.experimentalSessionMarks,
      );
  $$ImportedRecordsTableTableManager get importedRecords =>
      $$ImportedRecordsTableTableManager(_db, _db.importedRecords);
  $$RealPreferencesTableTableManager get realPreferences =>
      $$RealPreferencesTableTableManager(_db, _db.realPreferences);
}
