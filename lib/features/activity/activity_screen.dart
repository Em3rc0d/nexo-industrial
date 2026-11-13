import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'activity_store.dart';
import 'activity_backup_dialog.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key, required this.activityStore});

  final ActivityStore activityStore;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: activityStore,
        builder: (context, _) {
          final items = activityStore.items;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actividad',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => showActivityBackup(context, activityStore, restore: false),
                          icon: const Icon(Icons.copy_outlined),
                          label: const Text('Respaldar'),
                        ),
                        TextButton.icon(
                          onPressed: () => showActivityBackup(context, activityStore, restore: true),
                          icon: const Icon(Icons.restore),
                          label: const Text('Restaurar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gestiones reales, resultados y próximos pasos.',
                      style: TextStyle(color: NexoColors.muted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const _EmptyActivity()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: NexoColors.mint.withValues(
                                      alpha: 0.12,
                                    ),
                                    foregroundColor: NexoColors.teal,
                                    child: Icon(_iconFor(item.type)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.companyName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            _StatusPill(
                                              label: item.status.label,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${item.type.label} · ${item.outcome}',
                                        ),
                                        if (item.note.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            item.note,
                                            style: const TextStyle(
                                              color: NexoColors.muted,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Text(
                                          'Siguiente: ${item.nextStep}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (item.followUpAt case final date?) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Seguimiento: ${_dateLabel(date)}',
                                            style: const TextStyle(
                                              color: NexoColors.orange,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  static IconData _iconFor(ActivityType type) => switch (type) {
    ActivityType.visit => Icons.directions_walk_rounded,
    ActivityType.call => Icons.call_outlined,
    ActivityType.information => Icons.send_outlined,
  };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NexoColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: NexoColors.teal,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NexoColors.mint.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 34,
                color: NexoColors.teal,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Todavía no hay gestiones',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aquí aparecerán las visitas, llamadas y envíos que registres, '
              'junto con su resultado y siguiente paso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: NexoColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
