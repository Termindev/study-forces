import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_constants.dart';
import '../services/data_export_service.dart';
import '../main.dart';

class DataExportImportWidget extends StatefulWidget {
  const DataExportImportWidget({super.key});

  @override
  State<DataExportImportWidget> createState() => _DataExportImportWidgetState();
}

class _DataExportImportWidgetState extends State<DataExportImportWidget> {
  final DataExportService _exportService = DataExportService();
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _saveToLocalStorage() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Export data
      if (globalObjectBox == null) {
        throw Exception('ObjectBox not initialized');
      }
      final filePath = await _exportService.exportData(globalObjectBox!);

      if (mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data saved to: $filePath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // User canceled the save dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export canceled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
    });

    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          // Show confirmation dialog
          final shouldImport = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Import Data'),
              content: const Text(
                'This will replace all your current data with the imported data. '
                'Are you sure you want to continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Import'),
                ),
              ],
            ),
          );

          if (shouldImport == true) {
            // Import data
            if (globalObjectBox == null) {
              throw Exception('ObjectBox not initialized');
            }
            await _exportService.importData(globalObjectBox!, filePath);

            // The store will automatically refresh due to the watch query
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data imported successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: AppConstants.spacingS),
                const Text(
                  'Data Backup & Restore',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            const Text(
              'Export your data to share between devices or create backups.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: AppConstants.spacingL),
            // Save to device button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _saveToLocalStorage,
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isExporting ? 'Saving...' : 'Save to Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            // Import button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _importData,
                icon: _isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(_isImporting ? 'Importing...' : 'Import Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Text(
                      'Export creates a JSON file with all your subjects, sessions, and settings. Import will replace all current data.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
