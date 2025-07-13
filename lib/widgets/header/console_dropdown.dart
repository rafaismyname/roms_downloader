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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.gamepad_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedConsole?.id,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.primary,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
