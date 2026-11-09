import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../companies/domain/company.dart';
import 'activity_store.dart';

Future<bool> showActivityEntrySheet({
  required BuildContext context,
  required Company company,
  required ActivityStore activityStore,
  required ActivityType type,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _ActivityEntrySheet(
          company: company,
          activityStore: activityStore,
          type: type,
        ),
      ) ??
      false;
}

class _ActivityEntrySheet extends StatefulWidget {
  const _ActivityEntrySheet({
    required this.company,
    required this.activityStore,
    required this.type,
  });

  final Company company;
  final ActivityStore activityStore;
  final ActivityType type;

  @override
  State<_ActivityEntrySheet> createState() => _ActivityEntrySheetState();
}

class _ActivityEntrySheetState extends State<_ActivityEntrySheet> {
  late final TextEditingController _outcomeController;
  late final TextEditingController _noteController;
  late final TextEditingController _nextStepController;

  ProspectStatus _status = ProspectStatus.contacted;
  DateTime? _followUpAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _outcomeController = TextEditingController(
      text: switch (widget.type) {
        ActivityType.visit => 'Visita realizada.',
        ActivityType.call => 'Llamada realizada.',
        ActivityType.information => 'Información comercial enviada.',
      },
    );
    _noteController = TextEditingController();
    _nextStepController = TextEditingController(
      text: widget.company.suggestedNextStep,
    );
  }

  @override
  void dispose() {
    _outcomeController.dispose();
    _noteController.dispose();
    _nextStepController.dispose();
    super.dispose();
  }

  Future<void> _pickFollowUp() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _followUpAt ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );

    if (selected != null && mounted) {
      setState(() => _followUpAt = selected);
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    await widget.activityStore.record(
      widget.company,
      widget.type,
      outcome: _outcomeController.text,
      note: _noteController.text,
      nextStep: _nextStepController.text,
      status: _status,
      followUpAt: _followUpAt,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + insets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.type.label,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                widget.company.name,
                style: const TextStyle(color: NexoColors.muted),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProspectStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Estado del prospecto',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: ProspectStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _outcomeController,
                decoration: const InputDecoration(
                  labelText: 'Resultado',
                  hintText: 'Ej. No atendieron / pidió ficha técnica',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Nota',
                  hintText: 'Persona, necesidad, detalle relevante…',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nextStepController,
                decoration: const InputDecoration(
                  labelText: 'Siguiente paso',
                  hintText: 'Qué toca hacer después',
                ),
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFollowUp,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  _followUpAt == null
                      ? 'Agregar fecha de seguimiento'
                      : 'Seguimiento: ${_dateLabel(_followUpAt!)}',
                ),
              ),
              if (_followUpAt != null)
                TextButton(
                  onPressed: () => setState(() => _followUpAt = null),
                  child: const Text('Quitar fecha'),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Guardando…' : 'Guardar gestión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
