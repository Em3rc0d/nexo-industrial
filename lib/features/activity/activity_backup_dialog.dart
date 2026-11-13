import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'activity_backup.dart';
import 'activity_store.dart';

Future<void> showActivityBackup(
  BuildContext context, ActivityStore store, {required bool restore}
) async {
  String initial;
  try {
    initial = restore ? '' : await store.exportBackup();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el historial.')),
      );
    }
    return;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _BackupDialog(store: store, restore: restore, initial: initial),
  );
}

class _BackupDialog extends StatefulWidget {
  const _BackupDialog({required this.store, required this.restore, required this.initial});
  final ActivityStore store;
  final bool restore;
  final String initial;

  @override
  State<_BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<_BackupDialog> {
  late final controller = TextEditingController(text: widget.initial);
  String? message;
  bool busy = false;
  bool confirmed = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => busy = true);
    try {
      if (!widget.restore) {
        await Clipboard.setData(ClipboardData(text: controller.text));
        if (mounted) setState(() => message = 'Copiado. Guárdalo fuera de la app para conservarlo.');
      } else if (!confirmed) {
        final rows = ActivityBackup.decode(controller.text);
        setState(() {
          confirmed = true;
          message = '${rows.length} gestiones válidas. Confirma para combinarlas con el historial. Los duplicados exactos se omitirán.';
        });
      } else {
        final count = await widget.store.restoreBackup(controller.text);
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count gestiones añadidas. Historial anterior conservado.')),
        );
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => message = error.message.toString());
    } catch (_) {
      if (mounted) setState(() => message = 'No se completó la operación. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(widget.restore ? 'Restaurar historial' : 'Respaldar historial'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.restore
              ? 'Pega el respaldo JSON. Se validará antes de añadir gestiones; no se borrará el historial existente.'
              : 'Copia el JSON y guárdalo en un archivo .json fuera de la app. Copiarlo al portapapeles no es un respaldo permanente. Contiene tus notas y gestiones.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              readOnly: !widget.restore || busy,
              maxLines: 7,
              decoration: const InputDecoration(labelText: 'Respaldo JSON', border: OutlineInputBorder()),
              onChanged: (_) => setState(() { confirmed = false; message = null; }),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!, semanticsLabel: message),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('Cerrar')),
        FilledButton(onPressed: busy ? null : submit, child: Text(
          widget.restore ? (confirmed ? 'Confirmar restauración' : 'Validar respaldo') : 'Copiar JSON',
        )),
      ],
    ),
  );
}
