import 'package:flutter/material.dart';

import 'app/nexo_app.dart';
import 'features/activity/activity_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final activityStore = ActivityStore();
  await activityStore.initialize();

  runApp(NexoApp(activityStore: activityStore));
}
