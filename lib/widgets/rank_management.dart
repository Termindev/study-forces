import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/rank.dart';

class RankManagementWidget extends StatefulWidget {
  final List<Rank> ranks;
  final Function(List<Rank>) onRanksChanged;

  const RankManagementWidget({
    super.key,
    required this.ranks,
    required this.onRanksChanged,
  });

  @override
  State<RankManagementWidget> createState() => _RankManagementWidgetState();
}

class _RankManagementWidgetState extends State<RankManagementWidget> {
  // Work directly with the widget's ranks - no local copies
  List<Rank> get _ranks => widget.ranks;

  void _addRank() {
    setState(() {
      _ranks.add(
        Rank.create(
          requiredRating: 0,
          name: 'New Rank',
          description: '',
          color:
              '#FF${Colors.blue.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
          glow: false,
        ),
      );
    });
    widget.onRanksChanged(_ranks);
  }

  void _removeRank(Rank rank) {
    setState(() {
      _ranks.remove(rank);
    });
    widget.onRanksChanged(_ranks);
  }

  void _updateRank(Rank rankToUpdate) {
    setState(() {
      // The rank object is already updated in the dialog - just notify parent
      print(
        'DEBUG: Rank updated: ${rankToUpdate.name} (${rankToUpdate.requiredRating})',
      );
    });
    widget.onRanksChanged(_ranks);
  }

  Future<String?> _showColorPickerDialog(String currentColorHex) async {
    final currentColor = Color(
      int.parse(currentColorHex.replaceFirst('#', '0x')),
    );
    Color selectedColor = currentColor;

    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                setDialogState(() {
                  selectedColor = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                  '#${selectedColor.toARGB32().toRadixString(16).toUpperCase()}',
                );
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRankDialog(Rank rank) {
    final nameController = TextEditingController(text: rank.name);
    final descriptionController = TextEditingController(text: rank.description);
    final ratingController = TextEditingController(
      text: rank.requiredRating.toString(),
    );
    bool glow = rank.glow;
    String currentColor = rank.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Rank'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Rank Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ratingController,
                  decoration: const InputDecoration(
                    labelText: 'Required Rating',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Glow Effect:'),
                    const SizedBox(width: 8),
                    Switch(
                      value: glow,
                      onChanged: (value) {
                        setDialogState(() {
                          glow = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Color:'),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final result = await _showColorPickerDialog(
                          currentColor,
                        );
                        if (result != null) {
                          setDialogState(() {
                            currentColor = result;
                          });
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(currentColor.replaceFirst('#', '0x')),
                          ),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update the existing rank object directly
                rank.requiredRating = int.tryParse(ratingController.text) ?? 0;
                rank.name = nameController.text;
                rank.description = descriptionController.text;
                rank.color = currentColor;
                rank.glow = glow;
                print(
                  'DEBUG: Updated rank directly: ${rank.name} (${rank.requiredRating})',
                );
                _updateRank(rank);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ranks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _addRank,
              icon: const Icon(Icons.add),
              label: const Text('Add Rank'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_ranks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No ranks defined. Add a rank to get started.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...(() {
            final sortedRanks = List<Rank>.from(_ranks);
            sortedRanks.sort(
              (a, b) => a.requiredRating.compareTo(b.requiredRating),
            );
            return sortedRanks.asMap().entries.map((entry) {
              final index = entry.key;
              final rank = entry.value;
              final color = Color(
                int.parse(rank.color.replaceFirst('#', '0x')),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: rank.glow
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    rank.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rank.description.isNotEmpty) Text(rank.description),
                      Text(
                        'Required Rating: ${rank.requiredRating}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (rank.glow)
                        const Text(
                          '✨ Glows',
                          style: TextStyle(fontSize: 12, color: Colors.amber),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditRankDialog(rank);
                          break;
                        case 'delete':
                          _removeRank(rank);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          })(),
      ],
    );
  }
}
