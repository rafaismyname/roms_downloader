import 'package:flutter/material.dart';
import 'package:roms_downloader/models/console_model.dart';

class ConsoleDropdown extends StatelessWidget {
  final List<Console> consoles;
  final Console? selectedConsole;
  final bool isInteractive;
  final Function(Console) onConsoleSelect;

  const ConsoleDropdown({
    super.key,
    required this.consoles,
    required this.selectedConsole,
    required this.isInteractive,
    required this.onConsoleSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedConsole?.id,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onChanged: isInteractive
              ? (value) {
                  if (value != null) {
                    final console = consoles.firstWhere((c) => c.id == value);
                    onConsoleSelect(console);
                  }
                }
              : null,
          items: consoles.map((console) {
            return DropdownMenuItem<String>(
              value: console.id,
              child: Text(
                console.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
