import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/activity/activity_backup.dart';

void main() {
  final row = <String, Object?>{
    'id': 9,
    'company_id': '20100000001',
    'company_name': 'Empresa de prueba',
    'type': 'visit',
    'outcome': 'Visita registrada',
    'note': 'Información con tildes: cotización',
    'next_step': 'Revisar propuesta',
    'status': 'followUp',
    'follow_up_at': '2026-11-15T09:00:00.000',
    'created_at': '2026-11-13T10:00:00.000',
  };

  test('round trip preserves every field without carrying SQLite IDs', () {
    final restored = ActivityBackup.decode(ActivityBackup.encode([row]));
    expect(restored.single, ActivityBackup.normalize(row));
    expect(restored.single.containsKey('id'), isFalse);
    expect(ActivityBackup.fingerprint(row), ActivityBackup.fingerprint(restored.single));
  });

  test('supports empty history and missing optional follow-up', () {
    expect(ActivityBackup.decode(ActivityBackup.encode([])), isEmpty);
    expect(ActivityBackup.decode(ActivityBackup.encode([{...row, 'follow_up_at': null}])).single['follow_up_at'], isNull);
  });

  test('rejects incompatible and malformed documents before import', () {
    for (final source in ['bad json', '{}', '{"format":"nexo-industrial-activities","version":2,"activities":[]}']) {
      expect(() => ActivityBackup.decode(source), throwsFormatException);
    }
  });

  test('rejects entire backup if any activity is invalid', () {
    for (final invalid in [
      {...row, 'type': 'unknown'}, {...row, 'status': 'invalid'},
      {...row, 'created_at': 'yesterday'}, {...row, 'company_id': ''},
      {...row, 'note': 5}, {...row, 'follow_up_at': 'tomorrow'},
    ]) {
      final source = jsonEncode({'format': ActivityBackup.format, 'version': 1, 'activities': [row, invalid]});
      expect(() => ActivityBackup.decode(source), throwsFormatException);
    }
  });
}
