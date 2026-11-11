import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../activity/activity_store.dart';
import 'company_detail_screen.dart';
import 'domain/company.dart';

enum _LocationFilter { all, reliable, approximate }

enum _ManagementFilter { all, unmanaged, managed }

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
  String? _sector;
  _LocationFilter _locationFilter = _LocationFilter.all;
  _ManagementFilter _managementFilter = _ManagementFilter.all;
  bool _onlyPriority = false;

  int get _activeFilterCount =>
      (_sector == null ? 0 : 1) +
      (_locationFilter == _LocationFilter.all ? 0 : 1) +
      (_managementFilter == _ManagementFilter.all ? 0 : 1) +
      (_onlyPriority ? 1 : 0);

  List<String> get _sectors {
    final sectors = widget.companies.map((c) => c.sector).toSet().toList()
      ..sort();
    return sectors;
  }

  List<Company> _filteredCompanies() {
    final query = _query.trim().toLowerCase();

    final companies =
        widget.companies.where((company) {
            if (!company.matchesQuery(query)) return false;

            if (_sector != null && company.sector != _sector) return false;

            if (_locationFilter == _LocationFilter.reliable &&
                !company.hasReliableCoordinates) {
              return false;
            }

            if (_locationFilter == _LocationFilter.approximate &&
                company.hasReliableCoordinates) {
              return false;
            }

            final managed = widget.activityStore.hasActivity(company.id);
            if (_managementFilter == _ManagementFilter.unmanaged && managed) {
              return false;
            }
            if (_managementFilter == _ManagementFilter.managed && !managed) {
              return false;
            }

            if (_onlyPriority && company.internalPotential < 0.75) return false;

            return true;
          }).toList()
          ..sort((a, b) => b.internalPotential.compareTo(a.internalPotential));

    return companies;
  }

  Future<void> _showFilters() async {
    var sector = _sector;
    var location = _locationFilter;
    var management = _managementFilter;
    var onlyPriority = _onlyPriority;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Filtrar cuentas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: sector ?? '__all__',
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sector',
                        prefixIcon: Icon(Icons.factory_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '__all__',
                          child: Text('Todos los sectores'),
                        ),
                        ..._sectors.map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setSheetState(
                        () => sector = value == '__all__' ? null : value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<_LocationFilter>(
                      initialValue: location,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: _LocationFilter.all,
                          child: Text('Cualquier calidad'),
                        ),
                        DropdownMenuItem(
                          value: _LocationFilter.reliable,
                          child: Text('Dirección precisa/verificada'),
                        ),
                        DropdownMenuItem(
                          value: _LocationFilter.approximate,
                          child: Text('Ubicación aproximada'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => location = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<_ManagementFilter>(
                      initialValue: management,
                      decoration: const InputDecoration(
                        labelText: 'Gestión',
                        prefixIcon: Icon(Icons.task_alt_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: _ManagementFilter.all,
                          child: Text('Todas'),
                        ),
                        DropdownMenuItem(
                          value: _ManagementFilter.unmanaged,
                          child: Text('Sin gestionar'),
                        ),
                        DropdownMenuItem(
                          value: _ManagementFilter.managed,
                          child: Text('Gestionadas'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => management = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: onlyPriority,
                      title: const Text('Solo prioridad alta'),
                      subtitle: const Text(
                        'Usa el ranking interno sin mostrar el score.',
                      ),
                      onChanged: (value) =>
                          setSheetState(() => onlyPriority = value),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _sector = null;
                                _locationFilter = _LocationFilter.all;
                                _managementFilter = _ManagementFilter.all;
                                _onlyPriority = false;
                              });
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _sector = sector;
                                _locationFilter = location;
                                _managementFilter = management;
                                _onlyPriority = onlyPriority;
                              });
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: widget.activityStore,
        builder: (context, _) {
          final companies = _filteredCompanies();

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Cuentas',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Badge(
                          isLabelVisible: _activeFilterCount > 0,
                          label: Text('$_activeFilterCount'),
                          child: IconButton(
                            tooltip: 'Filtrar cuentas',
                            onPressed: _showFilters,
                            icon: const Icon(Icons.tune_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${companies.length} de ${widget.companies.length} cuentas',
                      style: const TextStyle(color: NexoColors.muted),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Empresa, RUC, distrito o sector',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: companies.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No hay cuentas que coincidan con estos filtros.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: NexoColors.muted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: companies.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final company = companies[index];
                          final latest = widget.activityStore.latestFor(
                            company.id,
                          );

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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${company.activity}\n'
                                '${company.compactLocationLabel}'
                                '${latest == null ? ' · Sin gestionar' : ' · ${latest.status.label}'}',
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
          );
        },
      ),
    );
  }
}
