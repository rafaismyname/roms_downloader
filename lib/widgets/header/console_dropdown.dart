import 'package:flutter/material.dart';
import 'package:roms_downloader/models/console_model.dart';

class ConsoleDropdown extends StatefulWidget {
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
  State<ConsoleDropdown> createState() => _ConsoleDropdownState();
}

class _ConsoleDropdownState extends State<ConsoleDropdown> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: _hasFocus ? 0.2 : 0.1),
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: _hasFocus ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hasFocus
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: _hasFocus ? 3 : 1,
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
                focusNode: _focusNode,
                isExpanded: true,
                value: widget.selectedConsole?.id,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onChanged: widget.isInteractive
                    ? (value) {
                        if (value != null) {
                          final console = widget.consoles.firstWhere((c) => c.id == value);
                          widget.onConsoleSelect(console);
                        }
                      }
                    : null,
                items: widget.consoles.map((console) {
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
