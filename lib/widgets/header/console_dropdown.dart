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

  void _onFocusChange([bool? hasFocus]) {
    setState(() {
      _hasFocus = hasFocus ?? _focusNode.hasFocus;
    });
  }

  void _performTap() {
    if (!widget.isInteractive) return;
    bool disableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS');

    showDialog(
      context: context,
      animationStyle: disableAnimations ? AnimationStyle.noAnimation : null,
      builder: (context) => SimpleDialog(
        title: const Text('Select Console'),
        children: widget.consoles.map((console) {
          return SimpleDialogOption(
            onPressed: () {
              widget.onConsoleSelect(console);
              Navigator.pop(context);
            },
            child: Text(
              console.name,
              style: TextStyle(
                fontWeight: widget.selectedConsole?.id == console.id ? FontWeight.bold : FontWeight.normal,
                color: widget.selectedConsole?.id == console.id ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bool disableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS');

    if (disableAnimations) {
      return FocusableActionDetector(
        focusNode: _focusNode,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) => _performTap()),
        },
        child: InkWell(
          onFocusChange: _onFocusChange,
          onTap: _performTap,
          child: Container(
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
                  child: Text(
                    widget.selectedConsole?.name ?? 'Select Console',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      );
    }

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
