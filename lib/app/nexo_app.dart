import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/activity/activity_store.dart';
import '../features/companies/data/asset_company_repository.dart';
import '../features/companies/domain/company.dart';
import '../features/home/home_shell.dart';

class NexoApp extends StatefulWidget {
  const NexoApp({super.key, required this.activityStore});

  final ActivityStore activityStore;

  @override
  State<NexoApp> createState() => _NexoAppState();
}

class _NexoAppState extends State<NexoApp> {
  final AssetCompanyRepository _repository = const AssetCompanyRepository();
  late final Future<List<Company>> _companies = _repository.loadCompanies();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexo Industrial',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: FutureBuilder<List<Company>>(
        future: _companies,
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
                      'No se pudo cargar el dataset local.\n\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }

          return HomeShell(
            companies: snapshot.data ?? const [],
            activityStore: widget.activityStore,
          );
        },
      ),
    );
  }
}
