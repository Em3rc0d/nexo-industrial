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

class CommercialActivity {
  const CommercialActivity({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.type,
    required this.outcome,
    required this.nextStep,
    required this.createdAt,
  });

  final int id;
  final String companyId;
  final String companyName;
  final ActivityType type;
  final String outcome;
  final String nextStep;
  final DateTime createdAt;

  factory CommercialActivity.fromMap(Map<String, Object?> map) {
    return CommercialActivity(
      id: map['id']! as int,
      companyId: map['company_id']! as String,
      companyName: map['company_name']! as String,
      type: ActivityType.values.byName(map['type']! as String),
      outcome: map['outcome']! as String,
      nextStep: map['next_step']! as String,
      createdAt: DateTime.parse(map['created_at']! as String),
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
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE activities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id TEXT NOT NULL,
            company_name TEXT NOT NULL,
            type TEXT NOT NULL,
            outcome TEXT NOT NULL,
            next_step TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
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

  Future<void> record(Company company, ActivityType type) async {
    final database = _database;
    if (database == null) {
      throw StateError('ActivityStore has not been initialized.');
    }

    final outcome = switch (type) {
      ActivityType.visit => 'Visita registrada en campo.',
      ActivityType.call => 'Llamada comercial registrada.',
      ActivityType.information => 'Información comercial enviada.',
    };

    await database.insert('activities', {
      'company_id': company.id,
      'company_name': company.name,
      'type': type.name,
      'outcome': outcome,
      'next_step': company.suggestedNextStep,
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
