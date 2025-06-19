import 'package:flutter/material.dart';
import 'dart:async';

class SearchField extends StatefulWidget {
  final String initialText;
  final bool isEnabled;
  final bool isCompact;
  final Function(String) onChanged;

  const SearchField({
    super.key,
    required this.initialText,
    required this.isEnabled,
    required this.isCompact,
    required this.onChanged,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText && widget.initialText != _controller.text) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.isCompact ? 4 : 8);

    return SizedBox(
      height: widget.isCompact ? 32 : null,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(fontSize: widget.isCompact ? 12 : 14),
          prefixIcon: Icon(Icons.search, size: widget.isCompact ? 16 : 24),
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: widget.isCompact ? 0.5 : 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: widget.isCompact ? 0.5 : 1,
            ),
          ),
          contentPadding: widget.isCompact ? const EdgeInsets.symmetric(vertical: 0, horizontal: 8) : const EdgeInsets.symmetric(vertical: 12),
          isDense: widget.isCompact,
        ),
        style: TextStyle(fontSize: widget.isCompact ? 12 : 14),
        enabled: widget.isEnabled,
        onChanged: _onSearchChanged,
      ),
    );
  }
}
