import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../activity/activity_entry_sheet.dart';
import '../activity/activity_store.dart';
import 'domain/company.dart';

class CompanyDetailScreen extends StatelessWidget {
  const CompanyDetailScreen({
    super.key,
    required this.company,
    required this.activityStore,
  });

  final Company company;
  final ActivityStore activityStore;

  Future<void> _call(BuildContext context) async {
    final phone = company.contact.phone;
    if (phone == null || phone.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: phone);

    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar la llamada.')),
      );
    }
  }

  Future<void> _openLocation(BuildContext context) async {
    final precise = company.navigationEligible;
    final uri = precise
        ? company.googleMapsDirectionsUri
        : company.googleMapsSearchUri;

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            precise
                ? 'No se pudo abrir la navegación.'
                : 'No se pudo abrir la búsqueda en Google Maps.',
          ),
        ),
      );
    }
  }

  Future<void> _openActivityEntry(
    BuildContext context,
    ActivityType type,
  ) async {
    final saved = await showActivityEntrySheet(
      context: context,
      company: company,
      activityStore: activityStore,
      type: type,
    );

    if (!context.mounted || !saved) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${type.label} registrada.')),
    );
  }

  void _showActivityPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Registrar gestión',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.directions_walk_rounded),
                  title: const Text('Visité la empresa'),
                  subtitle: const Text('Guarda resultado, nota y siguiente paso'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openActivityEntry(context, ActivityType.visit);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.call_outlined),
                  title: const Text('Realicé una llamada'),
                  subtitle: const Text('Registra qué pasó y cómo continuar'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openActivityEntry(context, ActivityType.call);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.send_outlined),
                  title: const Text('Envié información comercial'),
                  subtitle: const Text('Deja trazabilidad del seguimiento'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openActivityEntry(context, ActivityType.information);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = company.contact.phone?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ficha comercial',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NexoColors.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.factory_rounded,
                  color: NexoColors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'RUC: ${company.ruc}',
                      style: const TextStyle(color: NexoColors.muted),
                    ),
                    const SizedBox(height: 7),
                    _StatusPill(label: company.locationLabel),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            icon: Icons.handshake_outlined,
            title: '¿Por qué me conviene contactarla?',
            child: Text(company.opportunityReason),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            icon: Icons.inventory_2_outlined,
            title: '¿Qué puedo ofrecerle de Aurora o Sigma?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (company.auroraProducts.isNotEmpty) ...[
                  const Text(
                    'Aurora',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: company.auroraProducts
                        .map((product) => Chip(label: Text(product)))
                        .toList(),
                  ),
                ],
                if (company.sigmaProducts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Sigma',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: company.sigmaProducts
                        .map((product) => Chip(label: Text(product)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            icon: Icons.people_alt_outlined,
            title: '¿Con quién hablo y cómo lo contacto?',
            child: company.contact.hasAny
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (company.contact.name case final name?)
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      if (company.contact.role case final role?) Text(role),
                      if (company.contact.phone case final phone?) Text(phone),
                      if (company.contact.email case final email?) Text(email),
                    ],
                  )
                : const Text(
                    'No hay un contacto directo confirmado. El siguiente paso '
                    'es identificar o validar al responsable de compras.',
                  ),
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: activityStore,
            builder: (context, _) {
              final latest = activityStore.latestFor(company.id);

              return _SectionCard(
                icon: Icons.history_rounded,
                title: '¿Qué pasó antes y qué toca hacer?',
                child: latest == null
                    ? Text(
                        'No hay gestiones registradas todavía.\n\n'
                        'Siguiente paso sugerido: ${company.suggestedNextStep}',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${latest.type.label} · ${_dateLabel(latest.createdAt)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _StatusPill(label: latest.status.label),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(latest.outcome),
                          if (latest.note.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              latest.note,
                              style: const TextStyle(color: NexoColors.muted),
                            ),
                          ],
                          const SizedBox(height: 10),
                          const Text(
                            'Ahora toca',
                            style: TextStyle(
                              color: NexoColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(latest.nextStep),
                          if (latest.followUpAt case final followUp?) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Seguimiento: ${_dateLabel(followUp)}',
                              style: const TextStyle(
                                color: NexoColors.orange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            'Fuente ubicación: ${company.source} · Procesado: '
            '${_dateLabel(company.sourceUpdatedAt)}',
            style: const TextStyle(color: NexoColors.muted, fontSize: 12),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: NexoColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: hasPhone
                      ? () => _call(context)
                      : () => _showActivityPicker(context),
                  icon: Icon(
                    hasPhone ? Icons.call_rounded : Icons.add_task_rounded,
                  ),
                  label: Text(hasPhone ? 'Llamar' : 'Registrar gestión'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Tooltip(
                  message: company.navigationEligible
                      ? 'Abrir navegación en Google Maps'
                      : 'Buscar esta empresa en Google Maps',
                  child: OutlinedButton.icon(
                    onPressed: () => _openLocation(context),
                    icon: Icon(
                      company.navigationEligible
                          ? Icons.directions_outlined
                          : Icons.search_rounded,
                    ),
                    label: Text(
                      company.locationActionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: hasPhone
          ? FloatingActionButton.extended(
              onPressed: () => _showActivityPicker(context),
              label: const Text('Registrar'),
              icon: const Icon(Icons.add_task_rounded),
            )
          : null,
    );
  }

  static String _dateLabel(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    return '$day/$month/$year';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NexoColors.mint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: NexoColors.teal,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: NexoColors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
