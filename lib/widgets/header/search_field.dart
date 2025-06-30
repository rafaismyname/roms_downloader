import 'package:flutter/material.dart';
import 'dart:async';

class SearchField extends StatefulWidget {
  final String initialText;
  final bool isEnabled;
  final Function(String) onChanged;

  const SearchField({
    super.key,
    required this.initialText,
    required this.isEnabled,
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
    final borderRadius = BorderRadius.circular(4);

    return SizedBox(
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(fontSize: 14),
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          isDense: true,
        ),
        style: TextStyle(fontSize: 14),
        enabled: widget.isEnabled,
        onChanged: _onSearchChanged,
      ),
    );
  }
}
