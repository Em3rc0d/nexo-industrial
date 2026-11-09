import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../activity/activity_store.dart';
import 'company_detail_screen.dart';
import 'domain/company.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({
    super.key,
    required this.companies,
    required this.activityStore,
  });

  final List<Company> companies;
  final ActivityStore activityStore;

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final companies =
        widget.companies.where((company) {
            if (query.isEmpty) return true;
            return company.name.toLowerCase().contains(query) ||
                company.ruc.toLowerCase().contains(query) ||
                company.activity.toLowerCase().contains(query) ||
                company.sector.toLowerCase().contains(query);
          }).toList()
          ..sort((a, b) => b.internalPotential.compareTo(a.internalPotential));

    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuentas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Busca una empresa del dataset maestro.',
                  style: TextStyle(color: NexoColors.muted),
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar empresa o RUC',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: companies.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final company = companies[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1612A69A),
                      foregroundColor: NexoColors.teal,
                      child: Icon(Icons.apartment_rounded),
                    ),
                    title: Text(
                      company.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${company.activity}\n${company.locationLabel}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CompanyDetailScreen(
                            company: company,
                            activityStore: widget.activityStore,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
