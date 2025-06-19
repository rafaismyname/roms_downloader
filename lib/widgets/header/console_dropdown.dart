import 'package:flutter/material.dart';
import 'package:roms_downloader/models/app_models.dart';

class ConsoleDropdown extends StatelessWidget {
  final List<Console> consoles;
  final Console? selectedConsole;
  final bool isInteractive;
  final bool isCompact;
  final Function(Console) onConsoleSelect;

  const ConsoleDropdown({
    super.key,
    required this.consoles,
    required this.selectedConsole,
    required this.isInteractive,
    required this.isCompact,
    required this.onConsoleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(isCompact ? 4 : 8);

    return Container(
      height: isCompact ? 32 : null,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: borderRadius,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: isCompact ? 0.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedConsole?.id,
          style: TextStyle(
            fontSize: isCompact ? 12 : 14,
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
