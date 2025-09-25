import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/data_export_import_widget.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: ListView(
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Data Export/Import Section
          const DataExportImportWidget(),

          const SizedBox(height: AppConstants.spacingL),

          // App Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 24),
                      SizedBox(width: AppConstants.spacingS),
                      Text(
                        'App Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  const Text('StudyForces v1.1.0 beta'),
                  const SizedBox(height: AppConstants.spacingS),
                  const Text(
                    'Track your study progress and problem solving sessions with intelligent rating systems.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
