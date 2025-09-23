import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'objectbox.dart';
import 'stores/subject_store.dart';
import 'theme/app_theme.dart';
import 'routes/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ObjectBox before runApp
  final objectBox = await ObjectBox.create();

  runApp(MyApp(objectBox: objectBox));
}

/// Top-level widget that owns the ObjectBox instance
class MyApp extends StatefulWidget {
  final ObjectBox objectBox;

  const MyApp({super.key, required this.objectBox});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ObjectBox _objectBox;
  late final SubjectStore _store;

  @override
  void initState() {
    super.initState();
    _objectBox = widget.objectBox;
    _store = SubjectStore(_objectBox);

    // Apply rating changes for all subjects on app startup
    _applyRatingChangesOnStartup();
  }

  Future<void> _applyRatingChangesOnStartup() async {
    try {
      await _store.applyRateChangesForAll(DateTime.now());
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Error applying rating changes on startup: $e');
    }
  }

  @override
  void dispose() {
    _store.dispose();
    _objectBox.store.close(); // Close the ObjectBox store
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SubjectStore>(
      create: (context) => _store,
      child: MaterialApp(
        title: 'Study Forces',
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const AppShell(),
      ),
    );
  }
}

