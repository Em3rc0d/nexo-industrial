import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../activity/activity_store.dart';
import '../map/ranking_service.dart';
import 'company_detail_screen.dart';

enum NearbySort { potential, distance }

class NearbyCompaniesScreen extends StatefulWidget {
  const NearbyCompaniesScreen({
    super.key,
    required this.companies,
    required this.activityStore,
  });

  final List<RankedCompany> companies;
  final ActivityStore activityStore;

  @override
  State<NearbyCompaniesScreen> createState() => _NearbyCompaniesScreenState();
}

class _NearbyCompaniesScreenState extends State<NearbyCompaniesScreen> {
  NearbySort _sort = NearbySort.potential;

  @override
  Widget build(BuildContext context) {
    final companies = [...widget.companies];

    if (_sort == NearbySort.distance) {
      companies.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Empresas cercanas',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: DropdownButtonFormField<NearbySort>(
              initialValue: _sort,
              decoration: const InputDecoration(
                labelText: 'Ordenar',
                prefixIcon: Icon(Icons.swap_vert_rounded),
              ),
              items: const [
                DropdownMenuItem(
                  value: NearbySort.potential,
                  child: Text('Mayor potencial comercial'),
                ),
                DropdownMenuItem(
                  value: NearbySort.distance,
                  child: Text('Más cercanas'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _sort = value);
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: companies.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = companies[index];
                final company = item.company;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: NexoColors.mint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.factory_outlined,
                      color: NexoColors.teal,
                    ),
                  ),
                  title: Text(
                    company.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${company.activity}\n'
                    '${company.managementStatus ?? company.locationLabel}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: NexoColors.text,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
