import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../companies/domain/company.dart';

enum ActivityType {
  visit,
  call,
  information;

  String get label => switch (this) {
        ActivityType.visit => 'Visita',
        ActivityType.call => 'Llamada',
        ActivityType.information => 'Información enviada',
      };
}

enum ProspectStatus {
  contacted,
  interested,
  followUp,
  noOpportunity;

  String get label => switch (this) {
        ProspectStatus.contacted => 'Contactada',
        ProspectStatus.interested => 'Interesada',
        ProspectStatus.followUp => 'Seguimiento',
        ProspectStatus.noOpportunity => 'No oportunidad',
      };
}

class CommercialActivity {
  const CommercialActivity({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.type,
    required this.outcome,
    required this.note,
    required this.nextStep,
    required this.status,
    required this.createdAt,
    this.followUpAt,
  });

  final int id;
  final String companyId;
  final String companyName;
  final ActivityType type;
  final String outcome;
  final String note;
  final String nextStep;
  final ProspectStatus status;
  final DateTime createdAt;
  final DateTime? followUpAt;

  factory CommercialActivity.fromMap(Map<String, Object?> map) {
    final rawStatus = map['status'] as String?;

    return CommercialActivity(
      id: map['id']! as int,
      companyId: map['company_id']! as String,
      companyName: map['company_name']! as String,
      type: ActivityType.values.byName(map['type']! as String),
      outcome: map['outcome']! as String,
      note: (map['note'] as String?) ?? '',
      nextStep: map['next_step']! as String,
      status: ProspectStatus.values.where((item) => item.name == rawStatus).firstOrNull ??
          ProspectStatus.contacted,
      createdAt: DateTime.parse(map['created_at']! as String),
      followUpAt: map['follow_up_at'] == null
          ? null
          : DateTime.tryParse(map['follow_up_at']! as String),
    );
  }
}

class ActivityStore extends ChangeNotifier {
  Database? _database;
  List<CommercialActivity> _items = const [];

  List<CommercialActivity> get items => List.unmodifiable(_items);

  Future<void> initialize() async {
    final databasePath = await getDatabasesPath();

    _database = await openDatabase(
      '$databasePath/nexo_industrial.db',
      version: 2,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE activities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id TEXT NOT NULL,
            company_name TEXT NOT NULL,
            type TEXT NOT NULL,
            outcome TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            next_step TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'contacted',
            follow_up_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await database.execute(
          'CREATE INDEX idx_activities_company_created '
          'ON activities(company_id, created_at DESC)',
        );
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            "ALTER TABLE activities ADD COLUMN note TEXT NOT NULL DEFAULT ''",
          );
          await database.execute(
            "ALTER TABLE activities ADD COLUMN status TEXT NOT NULL DEFAULT 'contacted'",
          );
          await database.execute(
            'ALTER TABLE activities ADD COLUMN follow_up_at TEXT',
          );
          await database.execute(
            'CREATE INDEX IF NOT EXISTS idx_activities_company_created '
            'ON activities(company_id, created_at DESC)',
          );
        }
      },
    );

    await _reload();
  }

  CommercialActivity? latestFor(String companyId) {
    for (final item in _items) {
      if (item.companyId == companyId) return item;
    }
    return null;
  }

  ProspectStatus? statusFor(String companyId) => latestFor(companyId)?.status;

  bool hasActivity(String companyId) => latestFor(companyId) != null;

  Future<void> record(
    Company company,
    ActivityType type, {
    String? outcome,
    String? nextStep,
    String note = '',
    ProspectStatus status = ProspectStatus.contacted,
    DateTime? followUpAt,
  }) async {
    final database = _database;
    if (database == null) {
      throw StateError('ActivityStore has not been initialized.');
    }

    final defaultOutcome = switch (type) {
      ActivityType.visit => 'Visita registrada en campo.',
      ActivityType.call => 'Llamada comercial registrada.',
      ActivityType.information => 'Información comercial enviada.',
    };

    await database.insert('activities', {
      'company_id': company.id,
      'company_name': company.name,
      'type': type.name,
      'outcome': (outcome?.trim().isNotEmpty ?? false)
          ? outcome!.trim()
          : defaultOutcome,
      'note': note.trim(),
      'next_step': (nextStep?.trim().isNotEmpty ?? false)
          ? nextStep!.trim()
          : company.suggestedNextStep,
      'status': status.name,
      'follow_up_at': followUpAt?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });

    await _reload();
  }

  Future<void> _reload() async {
    final database = _database;
    if (database == null) return;

    final rows = await database.query(
      'activities',
      orderBy: 'created_at DESC',
    );

    _items = rows.map(CommercialActivity.fromMap).toList(growable: false);
    notifyListeners();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
