import 'package:flutter/material.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/widgets/header/console_dropdown.dart';

class SettingsTabSelector extends StatelessWidget {
  final bool showGeneral;
  final Console? selectedConsole;
  final List<Console> consoles;
  final Function(bool) onTabChanged;
  final Function(Console) onConsoleSelected;

  const SettingsTabSelector({
    super.key,
    required this.showGeneral,
    required this.selectedConsole,
    required this.consoles,
    required this.onTabChanged,
    required this.onConsoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('General'),
                        icon: Icon(Icons.settings),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Console'),
                        icon: Icon(Icons.videogame_asset),
                      ),
                    ],
                    selected: {showGeneral},
                    onSelectionChanged: (selection) {
                      onTabChanged(selection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!showGeneral) ...[
              const SizedBox(height: 8),
              ConsoleDropdown(
                selectedConsole: selectedConsole,
                consoles: consoles,
                isInteractive: true,
                onConsoleSelect: onConsoleSelected,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
