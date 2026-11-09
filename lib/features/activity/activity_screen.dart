import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'activity_store.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({
    super.key,
    required this.activityStore,
  });

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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Solo lo que realmente registraste en campo.',
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
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    NexoColors.mint.withValues(alpha: 0.12),
                                foregroundColor: NexoColors.teal,
                                child: Icon(_iconFor(item.type)),
                              ),
                              title: Text(
                                item.companyName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${item.type.label} · ${item.outcome}\n'
                                'Siguiente: ${item.nextStep}',
                              ),
                              isThreeLine: true,
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

  static IconData _iconFor(ActivityType type) => switch (type) {
        ActivityType.visit => Icons.directions_walk_rounded,
        ActivityType.call => Icons.call_outlined,
        ActivityType.information => Icons.send_outlined,
      };
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nexo no inventa tu agenda. Aquí aparecerán las visitas, llamadas '
              'o envíos de información que tú registres desde una ficha comercial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: NexoColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
