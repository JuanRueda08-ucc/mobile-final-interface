import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/demo_history/demo_history_repository.dart' show CivilTime;
import '../../data/experimental_history/experimental_history_providers.dart';
import '../../data/experimental_history/experimental_history_repository.dart';
import 'firebase_account.dart';

Map<String, Object?> cloudSessionData(ExperimentalSessionRecord session) {
  if (session.isOpen) throw ArgumentError('La sesión sigue abierta.');
  final totals = session.totals;
  return {
    'version': 1,
    'qualification': 'experimental',
    'profile': session.profileId,
    'status': session.lifecycle.name,
    'complete': session.complete,
    'startedAtMs': session.startedAt.epochMs,
    'startedOffsetMinutes': session.startedAt.offsetMinutes,
    'endedAtMs': session.endedAt?.epochMs,
    'durableMs': session.latestDurableOffset.inMilliseconds,
    'activeMs': totals?.active.inMilliseconds,
    'evaluableMs': totals?.evaluable.inMilliseconds,
    'closures': totals?.closureActivations,
  };
}

final class CloudSession {
  CloudSession(this.id, Map<String, dynamic> data)
    : startedAt = CivilTime(
        data['startedAtMs'] as int,
        data['startedOffsetMinutes'] as int,
      ),
      lifecycle = ExperimentalLifecycle.values.byName(data['status'] as String),
      complete = data['complete'] as bool,
      durable = Duration(milliseconds: data['durableMs'] as int),
      active = switch (data['activeMs']) {
        final int ms => Duration(milliseconds: ms),
        _ => null,
      },
      evaluable = switch (data['evaluableMs']) {
        final int ms => Duration(milliseconds: ms),
        _ => null,
      },
      closures = data['closures'] as int?;

  final String id;
  final CivilTime startedAt;
  final ExperimentalLifecycle lifecycle;
  final bool complete;
  final Duration durable;
  final Duration? active;
  final Duration? evaluable;
  final int? closures;
}

CollectionReference<Map<String, dynamic>> _sessions(String uid) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions');

/// Borra todos los resúmenes de [uid] en la nube, por lotes. Lo usa la
/// eliminación de la cuenta; las reglas lo permiten solo al propietario.
Future<void> deleteCloudSessions(String uid) async {
  while (true) {
    final page = await _sessions(uid)
        .limit(400)
        .get(const GetOptions(source: Source.server));
    if (page.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in page.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

final cloudSessionsEraserProvider = Provider<Future<void> Function(String)>(
  (ref) => deleteCloudSessions,
);

final cloudSessionUploadProvider = FutureProvider.autoDispose
    .family<void, String>((ref, uid) async {
      final auth = ref.watch(firebaseAuthProvider);
      final repo = ref.watch(experimentalHistoryRepositoryProvider);
      ref.watch(journalSyncProvider.select((s) => s.revision));
      if (auth == null || repo == null) return;
      bool current() =>
          ref.mounted &&
          ref.read(verifiedFirebaseUidProvider) == uid &&
          auth.currentUser?.uid == uid;

      for (final session in await repo.pendingCloudSessions(uid)) {
        if (!current()) return;
        final document = _sessions(uid).doc(session.sessionId);
        final data = cloudSessionData(session);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          if (!current()) throw StateError('La cuenta cambió.');
          final existing = await transaction.get(document);
          if (existing.exists) {
            final previous = existing.data()!;
            if (mapEquals(previous, data)) return;
            final incomplete = {
              ...previous,
              'complete': false,
              'activeMs': null,
              'evaluableMs': null,
              'closures': null,
            };
            if (previous['complete'] == true && mapEquals(incomplete, data)) {
              transaction.set(document, data);
              return;
            }
            throw StateError('El resumen remoto difiere del registro local.');
          }
          transaction.set(document, data);
        });
        await repo.confirmCloudSession(uid, session);
      }
    }, retry: (_, _) => null);

final cloudHistoryProvider = FutureProvider.autoDispose
    .family<List<CloudSession>, String>((ref, uid) async {
      ref.watch(
        cloudSessionUploadProvider(uid).select((result) => result.isLoading),
      );
      if (ref.watch(verifiedFirebaseUidProvider) != uid) return const [];
      final page = await _sessions(uid)
          .orderBy('startedAtMs', descending: true)
          .get(const GetOptions(source: Source.server));
      return [
        for (final doc in page.docs)
          if (doc.data()['version'] == 1) CloudSession(doc.id, doc.data()),
      ];
    }, retry: (_, _) => null);

class CloudSessionSync extends ConsumerStatefulWidget {
  const CloudSessionSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CloudSessionSync> createState() => _CloudSessionSyncState();
}

class _CloudSessionSyncState extends ConsumerState<CloudSessionSync> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        final uid = ref.read(verifiedFirebaseUidProvider);
        if (uid != null) {
          ref.invalidate(cloudSessionUploadProvider(uid));
          ref.invalidate(cloudHistoryProvider(uid));
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(verifiedFirebaseUidProvider);
    ref.listen(verifiedFirebaseUidProvider, (previous, next) {
      if (previous != next && next != null) {
        unawaited(ref.read(journalSyncProvider.notifier).sync());
      }
    });
    if (uid != null) {
      ref.listen(cloudSessionUploadProvider(uid), (_, _) {});
    }
    return widget.child;
  }
}
