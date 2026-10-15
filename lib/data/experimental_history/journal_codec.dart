import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

/// Serialización canónica del journal experimental (fase 5D), idéntica a
/// `JournalCodec.kt`: subconjunto propio, no JCS completo.
///
/// - Solo objetos, listas, cadenas, enteros, booleanos y nulos.
/// - Claves ordenadas por unidades UTF-16, sin espacios.
/// - En cadenas se escapan `"`, `\` y U+0000–U+001F como `\u00xx`.
/// - Hash: SHA-256 en hexadecimal (minúsculas) de los bytes UTF-8.
abstract final class JournalCodec {
  static String encode(Object? value) {
    final out = StringBuffer();
    _write(out, value);
    return out.toString();
  }

  static String sha256Hex(String text) =>
      sha256.convert(utf8.encode(text)).toString();

  static const _maxSafe = 9007199254740991;

  static void _write(StringBuffer out, Object? v) {
    switch (v) {
      case null:
        out.write('null');
      case bool b:
        out.write(b ? 'true' : 'false');
      case int i:
        if (i > _maxSafe || i < -_maxSafe) {
          throw FormatException('Entero fuera de rango: $i');
        }
        out.write(i);
      case String s:
        _string(out, s);
      case Map<String, Object?> m:
        final keys = m.keys.toList()..sort();
        out.write('{');
        for (var i = 0; i < keys.length; i++) {
          if (i > 0) out.write(',');
          _string(out, keys[i]);
          out.write(':');
          _write(out, m[keys[i]]);
        }
        out.write('}');
      case List<Object?> l:
        out.write('[');
        for (var i = 0; i < l.length; i++) {
          if (i > 0) out.write(',');
          _write(out, l[i]);
        }
        out.write(']');
      default:
        throw FormatException(
          'Tipo no admitido en el journal: ${v.runtimeType}',
        );
    }
  }

  static void _string(StringBuffer out, String s) {
    out.write('"');
    for (final c in s.codeUnits) {
      if (c == 0x22) {
        out.write(r'\"');
      } else if (c == 0x5c) {
        out.write(r'\\');
      } else if (c < 0x20) {
        out.write(r'\u00');
        out.write(c.toRadixString(16).padLeft(2, '0'));
      } else {
        out.writeCharCode(c);
      }
    }
    out.write('"');
  }

  /// Sobre del registro cuyo hash firma Kotlin (Área 06 §8).
  static Map<String, Object?> envelope(
    JournalRecordMessage r,
    Map<String, Object?> payload,
  ) => {
    'schemaVersion': 1,
    'datasetMode': 'realExperimental',
    'journalSequence': r.journalSequence,
    'recordId': r.recordId,
    'sessionId': r.sessionId,
    'recordType': r.recordType,
    'occurredEpochMs': r.occurredEpochMs,
    'occurredOffsetMinutes': r.occurredOffsetMinutes,
    'sessionOffsetMs': r.sessionOffsetMs,
    'payloadSchemaVersion': r.payloadSchemaVersion,
    'payload': payload,
  };

  /// Decodifica el payload y comprueba que su forma canónica y el hash del
  /// sobre coinciden con lo recibido. Lanza [FormatException] si no.
  static Map<String, Object?> verify(JournalRecordMessage r) {
    final Object? decoded;
    try {
      decoded = jsonDecode(r.payloadJson);
    } on FormatException {
      throw const FormatException('payload no es JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('payload no es un objeto');
    }
    if (encode(decoded) != r.payloadJson) {
      throw const FormatException('payload no canónico');
    }
    if (sha256Hex(encode(envelope(r, decoded))) != r.payloadHash) {
      throw const FormatException('hash del registro no coincide');
    }
    return decoded;
  }
}
