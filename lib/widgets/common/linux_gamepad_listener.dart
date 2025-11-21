import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class LinuxGamepadListener extends StatefulWidget {
  final Widget child;

  const LinuxGamepadListener({super.key, required this.child});

  @override
  State<LinuxGamepadListener> createState() => _LinuxGamepadListenerState();
}

class _LinuxGamepadListenerState extends State<LinuxGamepadListener> {
  StreamSubscription<List<int>>? _subscription;
  final List<int> _buffer = [];
  
  // Axis state to prevent multiple triggers
  final Map<int, int> _axisState = {};
  static const int _axisThreshold = 16000;
  
  // Debounce for buttons
  DateTime _lastButtonTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _connectToGamepad();
  }

  Future<void> _connectToGamepad() async {
    // Try js0, js1, js2
    for (int i = 0; i < 4; i++) {
      final file = File('/dev/input/js$i');
      if (await file.exists()) {
        try {
          // openRead is non-blocking
          _subscription = file.openRead().listen(
            _onData,
            onError: (e) => print('Error reading gamepad js$i: $e'),
            cancelOnError: true,
          );
          print('Connected to gamepad at /dev/input/js$i');
          return;
        } catch (e) {
          print('Failed to open gamepad js$i: $e');
        }
      }
    }
    print('No gamepad found at /dev/input/js*');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onData(List<int> data) {
    _buffer.addAll(data);
    
    while (_buffer.length >= 8) {
      final chunk = Uint8List.fromList(_buffer.sublist(0, 8));
      _buffer.removeRange(0, 8);
      _processEvent(chunk);
    }
  }

  void _processEvent(Uint8List chunk) {
    final view = ByteData.sublistView(chunk);
    // time (0-3), value (4-5), type (6), number (7)
    // Linux input event struct is usually little endian on these devices
    final value = view.getInt16(4, Endian.little);
    final type = view.getUint8(6);
    final number = view.getUint8(7);

    // Type: 0x01 = Button, 0x02 = Axis, 0x80 = Init (ignore init)
    if (type & 0x80 != 0) return;

    if (type == 0x01) { // Button
      _handleButton(number, value);
    } else if (type == 0x02) { // Axis
      _handleAxis(number, value);
    }
  }

  void _handleButton(int number, int value) {
    if (value == 0) return; // Button release

    // Debounce
    final now = DateTime.now();
    if (now.difference(_lastButtonTime).inMilliseconds < 200) return;
    _lastButtonTime = now;

    // Mapping (Generic Xbox/Linux)
    // 0: A, 1: B, 2: X, 3: Y
    if (number == 0) { // A
      _activateFocus();
    } else if (number == 1) { // B
      // Optional: Back
    }
  }

  void _handleAxis(int number, int value) {
    // Axis 6: D-Pad X, Axis 7: D-Pad Y (common)
    // Axis 0: Left Stick X, Axis 1: Left Stick Y
    
    // We only care about "pressed" state (crossing threshold)
    // We need to track state to avoid repeated triggers while holding, 
    // UNLESS we want repeat. For now, let's do single trigger on press.
    
    final lastValue = _axisState[number] ?? 0;
    _axisState[number] = value;

    // Check for crossing threshold
    if (value.abs() > _axisThreshold && lastValue.abs() <= _axisThreshold) {
      // Trigger direction
      if (number == 6 || number == 0) { // X Axis
        if (value < 0) {
          _moveFocus(TraversalDirection.left);
        } else {
          _moveFocus(TraversalDirection.right);
        }
      } else if (number == 7 || number == 1) { // Y Axis
        if (value < 0) {
          _moveFocus(TraversalDirection.up);
        } else {
          _moveFocus(TraversalDirection.down);
        }
      }
    }
    
    // Reset if back to center (handled by lastValue check on next event)
  }

  void _moveFocus(TraversalDirection direction) {
    final focusManager = FocusManager.instance;
    final primaryFocus = focusManager.primaryFocus;
    if (primaryFocus != null) {
      primaryFocus.focusInDirection(direction);
    }
  }

  void _activateFocus() {
    final focusManager = FocusManager.instance;
    final primaryFocus = focusManager.primaryFocus;
    if (primaryFocus != null) {
      final context = primaryFocus.context;
      if (context != null) {
        final action = Actions.maybeFind<ActivateIntent>(context);
        if (action != null) {
          Actions.invoke(context, const ActivateIntent());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
