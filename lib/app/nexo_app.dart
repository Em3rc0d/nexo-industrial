import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/activity/activity_store.dart';
import '../features/home/home_shell.dart';
import '../features/sites/data/runtime_spatial_projection_repository.dart';
import '../features/sites/domain/runtime_spatial_projection.dart';

class NexoApp extends StatefulWidget {
  const NexoApp({super.key, required this.activityStore});

  final ActivityStore activityStore;

  @override
  State<NexoApp> createState() => _NexoAppState();
}

class _NexoAppState extends State<NexoApp> {
  final RuntimeSpatialProjectionRepository _repository =
      const RuntimeSpatialProjectionRepository();
  late final Future<RuntimeSpatialProjectionSnapshot> _runtime =
      _repository.loadSnapshot();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexo Industrial',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: FutureBuilder<RuntimeSpatialProjectionSnapshot>(
        future: _runtime,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No se pudo cargar el dataset local.\n\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }

          final runtime = snapshot.data;
          return HomeShell(
            companies: runtime?.companies ?? const [],
            spatialViews: runtime?.spatialViews ?? const [],
            activityStore: widget.activityStore,
          );
        },
      ),
    );
  }
}
