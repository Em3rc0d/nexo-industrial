import 'dart:convert';

import 'activity_store.dart';

/// Portable backup. Database IDs are deliberately excluded on restore.
class ActivityBackup {
  static const format = 'nexo-industrial-activities';
  static const fields = [
    'company_id', 'company_name', 'type', 'outcome', 'note',
    'next_step', 'status', 'follow_up_at', 'created_at',
  ];

  static String encode(List<Map<String, Object?>> rows) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': format,
        'version': 1,
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'activities': rows.map(normalize).toList(),
      });

  static List<Map<String, Object?>> decode(String source) {
    if (source.length > 20 * 1024 * 1024) {
      throw const FormatException('El respaldo supera el límite de 20 MB.');
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map || decoded['format'] != format ||
        decoded['version'] != 1 || decoded['activities'] is! List) {
      throw const FormatException('Formato o versión de respaldo no compatible.');
    }
    final rows = decoded['activities'] as List;
    if (rows.length > 50000) {
      throw const FormatException('El respaldo supera las 50,000 gestiones.');
    }
    return rows.map((row) {
      if (row is! Map<String, dynamic>) {
        throw const FormatException('Gestión inválida.');
      }
      return normalize(row);
    }).toList();
  }

  static Map<String, Object?> normalize(Map<String, Object?> row) {
    for (final field in fields) {
      if (field == 'follow_up_at' && row[field] == null) continue;
      if (row[field] is! String) {
        throw FormatException('Campo inválido: $field');
      }
    }
    if ((row['company_id']! as String).trim().isEmpty ||
        (row['company_name']! as String).trim().isEmpty ||
        !ActivityType.values.any((v) => v.name == row['type']) ||
        !ProspectStatus.values.any((v) => v.name == row['status']) ||
        DateTime.tryParse(row['created_at']! as String) == null ||
        (row['follow_up_at'] != null &&
          DateTime.tryParse(row['follow_up_at']! as String) == null)) {
      throw const FormatException('La gestión contiene valores inválidos.');
    }
    return {for (final field in fields) field: row[field]};
  }

  static String fingerprint(Map<String, Object?> row) =>
      jsonEncode(normalize(row));
}
