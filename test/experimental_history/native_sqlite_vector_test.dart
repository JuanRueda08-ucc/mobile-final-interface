import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/data/experimental_history/experimental_history_database.dart';
import 'package:vigia/data/experimental_history/experimental_history_repository.dart';
import 'package:vigia/data/experimental_history/journal_codec.dart';

void main() {
  test(
    'SQLite Kotlin → hash Dart → commit Drift → reapertura sin duplicados',
    () async {
      // Hechos sintéticos leídos de SQLite Android, no de una cámara.
      final fixture = jsonDecode(
        File('test/fixtures/fase5d_native_records.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final records = (fixture['records'] as List).map((value) {
        final m = value as Map<String, dynamic>;
        return JournalRecordMessage(
          journalSequence: m['journalSequence'] as int,
          recordId: m['recordId'] as String,
          sessionId: m['sessionId'] as String?,
          recordType: m['recordType'] as String,
          occurredEpochMs: m['occurredEpochMs'] as int,
          occurredOffsetMinutes: m['occurredOffsetMinutes'] as int,
          sessionOffsetMs: m['sessionOffsetMs'] as int?,
          payloadSchemaVersion: m['payloadSchemaVersion'] as int,
          payloadJson: m['payloadJson'] as String,
          payloadHash: m['payloadHash'] as String,
        );
      }).toList();
      expect(records, hasLength(3));
      for (final record in records) {
        expect(() => JournalCodec.verify(record), returnsNormally);
      }
      final dir = await Directory.systemTemp.createTemp('vigia_native_vector_');
      try {
        final file = File('${dir.path}/projection.sqlite');
        var db = ExperimentalHistoryDatabase(NativeDatabase(file));
        var repo = ExperimentalHistoryRepository(db);
        final first = await repo.importRecords(records);
        expect(first.stop, isNull);
        expect(first.acks, hasLength(3));
        await db.close(); // simula caída antes del ACK
        db = ExperimentalHistoryDatabase(NativeDatabase(file));
        repo = ExperimentalHistoryRepository(db);
        final second = await repo.importRecords(records);
        expect(second.applied, 0);
        expect(second.acks, first.acks);
        expect(await repo.importedCount(), 3);
        final session = (await repo.sessions()).single;
        expect(session.complete, isTrue);
        expect(session.totals!.active, const Duration(seconds: 2));
        expect(session.totals!.evaluable, const Duration(seconds: 1));
        await db.close();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
