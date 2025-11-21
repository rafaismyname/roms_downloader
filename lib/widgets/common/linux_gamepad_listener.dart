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

  int _eventSize = 24; // Default to 64-bit (24 bytes)

  @override
  void initState() {
    super.initState();
    _checkArch();
    _connectToGamepad();
  }

  void _checkArch() {
    // Simple heuristic for 64-bit vs 32-bit based on Platform.version
    // This affects input_event struct size (timeval size)
    final version = Platform.version.toLowerCase();
    if (version.contains('aarch64') || version.contains('x86_64') || version.contains('arm64')) {
      _eventSize = 24;
    } else {
      _eventSize = 16;
    }
    debugPrint('Detected architecture: $version, using event size: $_eventSize');
  }

  Future<void> _connectToGamepad() async {
    // 1. Try to find event device via /proc/bus/input/devices
    String? eventPath = await _findGamepadDevice();
    
    if (eventPath != null) {
      debugPrint('Found gamepad at $eventPath');
      await _connectToPath(eventPath, isEvdev: true);
      return;
    }

    // 2. Fallback: Try js0, js1, js2
    debugPrint('No event device found, trying legacy js* devices...');
    for (int i = 0; i < 4; i++) {
      final path = '/dev/input/js$i';
      if (await File(path).exists()) {
        debugPrint('Found legacy gamepad at $path');
        await _connectToPath(path, isEvdev: false);
        return;
      }
    }
    debugPrint('No gamepad found at /dev/input/js* or event*');
  }

  Future<String?> _findGamepadDevice() async {
    try {
      final file = File('/proc/bus/input/devices');
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final blocks = content.split('\n\n');

      for (final block in blocks) {
        if (_isGamepadBlock(block)) {
          final handlersLine = block.split('\n').firstWhere(
            (line) => line.startsWith('H: Handlers='),
            orElse: () => '',
          );
          
          // Extract eventX
          final match = RegExp(r'event(\d+)').firstMatch(handlersLine);
          if (match != null) {
            return '/dev/input/event${match.group(1)}';
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning /proc/bus/input/devices: $e');
    }
    return null;
  }

  bool _isGamepadBlock(String block) {
    final nameLine = block.split('\n').firstWhere(
      (line) => line.startsWith('N: Name='),
      orElse: () => '',
    ).toLowerCase();
    
    if (nameLine.isEmpty) {
      return false;
    }

    // Keywords for gamepads
    const keywords = [
      'gamepad', 'controller', 'joystick', 'pad', 
      'xbox', 'playstation', 'nintendo', 'switch',
      'retro', '8bitdo'
    ];

    return keywords.any((k) => nameLine.contains(k));
  }

  Future<void> _connectToPath(String path, {required bool isEvdev}) async {
    try {
      final file = File(path);
      _subscription = file.openRead().listen(
        (data) => _onData(data, isEvdev),
        onError: (e) => debugPrint('Error reading $path: $e'),
        cancelOnError: true,
      );
      debugPrint('Connected to $path');
    } catch (e) {
      debugPrint('Failed to open $path: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onData(List<int> data, bool isEvdev) {
    _buffer.addAll(data);
    
    final packetSize = isEvdev ? _eventSize : 8;
    
    while (_buffer.length >= packetSize) {
      final chunk = Uint8List.fromList(_buffer.sublist(0, packetSize));
      _buffer.removeRange(0, packetSize);
      if (isEvdev) {
        _processEvdevEvent(chunk);
      } else {
        _processJsEvent(chunk);
      }
    }
  }

  void _processJsEvent(Uint8List chunk) {
    final view = ByteData.sublistView(chunk);
    // time (0-3), value (4-5), type (6), number (7)
    final value = view.getInt16(4, Endian.little);
    final type = view.getUint8(6);
    final number = view.getUint8(7);

    // Type: 0x01 = Button, 0x02 = Axis, 0x80 = Init
    if (type & 0x80 != 0) {
      return;
    }

    if (type == 0x01) { // Button
      _handleButton(number, value);
    } else if (type == 0x02) { // Axis
      _handleAxis(number, value);
    }
  }

  void _processEvdevEvent(Uint8List chunk) {
    final view = ByteData.sublistView(chunk);
    // struct input_event {
    //   struct timeval time; // 16 bytes (64-bit) or 8 bytes (32-bit)
    //   __u16 type;
    //   __u16 code;
    //   __s32 value;
    // };
    
    int offset = _eventSize == 24 ? 16 : 8;
    
    final type = view.getUint16(offset, Endian.little);
    final code = view.getUint16(offset + 2, Endian.little);
    final value = view.getInt32(offset + 4, Endian.little);

    // EV_KEY = 0x01, EV_ABS = 0x03
    if (type == 0x01) { // Key/Button
      // Map Linux key codes to our internal button numbers
      // BTN_SOUTH (A) = 304 -> 0
      // BTN_EAST (B) = 305 -> 1
      // BTN_NORTH (X) = 307 -> 2
      // BTN_WEST (Y) = 308 -> 3
      
      int? btnNumber;
      if (code == 304) {
        btnNumber = 0; // A
      } else if (code == 305) {
        btnNumber = 1; // B
      } else if (code == 307) {
        btnNumber = 2; // X
      } else if (code == 308) {
        btnNumber = 3; // Y
      }
      
      if (btnNumber != null) {
        _handleButton(btnNumber, value); // value 1=press, 0=release
      }
    } else if (type == 0x03) { // Absolute Axis
      // ABS_X = 0x00, ABS_Y = 0x01
      // ABS_HAT0X = 0x10 (16), ABS_HAT0Y = 0x11 (17)
      
      int? axisNumber;
      if (code == 0x00) {
        axisNumber = 0;
      } else if (code == 0x01) {
        axisNumber = 1;
      } else if (code == 0x10) {
        axisNumber = 6; // Hat X
      } else if (code == 0x11) {
        axisNumber = 7; // Hat Y
      }
      
      if (axisNumber != null) {
        if (axisNumber == 6 || axisNumber == 7) {
          _handleAxis(axisNumber, value * 32000);
        } else {
          _handleAxis(axisNumber, value);
        }
      }
    }
  }

  void _handleButton(int number, int value) {
    if (value == 0) {
      return; // Button release
    }

    // Debounce
    final now = DateTime.now();
    if (now.difference(_lastButtonTime).inMilliseconds < 200) {
      return;
    }
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
