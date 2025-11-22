import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum GamepadButton {
  a, b, x, y,
  l1, r1,
  select, start,
  dpadUp, dpadDown, dpadLeft, dpadRight,
  unknown
}

class LinuxGamepadListener extends StatefulWidget {
  final Widget child;

  const LinuxGamepadListener({super.key, required this.child});

  @override
  State<LinuxGamepadListener> createState() => _LinuxGamepadListenerState();
}

class _LinuxGamepadListenerState extends State<LinuxGamepadListener> {
  final List<StreamSubscription<List<int>>> _subscriptions = [];
  final List<int> _buffer = [];
  
  // Axis state to prevent multiple triggers
  final Map<int, int> _axisState = {};
  static const int _axisThreshold = 16000;
  
  // Debounce for buttons
  DateTime _lastButtonTime = DateTime.now();
  
  // Auto-repeat for navigation
  Timer? _repeatTimer;

  int _eventSize = 24; // Default to 64-bit (24 bytes)

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkArch();
    await _connectToGamepads();
  }

  Future<void> _checkArch() async {
    // Default to 64-bit (24 bytes)
    _eventSize = 24;
    
    try {
      final result = await Process.run('uname', ['-m']);
      final arch = result.stdout.toString().trim().toLowerCase();
      debugPrint('System architecture: $arch');
      
      // 32-bit architectures
      if (arch.contains('armv7') || arch == 'arm' || arch.contains('i386') || arch.contains('i686')) {
        _eventSize = 16;
      }
    } catch (e) {
      debugPrint('Failed to check architecture via uname: $e');
      // Fallback to Platform.version
      final version = Platform.version.toLowerCase();
      if (!version.contains('64')) {
         _eventSize = 16;
      }
    }
    
    debugPrint('Using event size: $_eventSize bytes');
  }

  Future<void> _connectToGamepads() async {
    // 1. Try to find event devices via /proc/bus/input/devices
    final eventPaths = await _findAllGamepadDevices();
    
    if (eventPaths.isNotEmpty) {
      debugPrint('Found gamepads at $eventPaths');
      for (final path in eventPaths) {
        _connectToPath(path, isEvdev: true);
      }
      return;
    }

    // 2. Fallback: Try js0, js1, js2
    debugPrint('No event device found, trying legacy js* devices...');
    bool foundLegacy = false;
    for (int i = 0; i < 4; i++) {
      final path = '/dev/input/js$i';
      if (await File(path).exists()) {
        debugPrint('Found legacy gamepad at $path');
        _connectToPath(path, isEvdev: false);
        foundLegacy = true;
      }
    }
    
    if (!foundLegacy) {
      debugPrint('No gamepad found at /dev/input/js* or event*');
    }
  }

  Future<List<String>> _findAllGamepadDevices() async {
    final paths = <String>[];
    try {
      final file = File('/proc/bus/input/devices');
      if (!await file.exists()) {
        return paths;
      }

      final content = await file.readAsString();
      final lines = content.split('\n');
      
      String? currentName;
      String? currentHandlers;

      for (final line in lines) {
        if (line.trim().isEmpty) {
          // End of block, process what we found
          if (currentName != null && currentHandlers != null) {
             // Check if it's a gamepad
             if (_isGamepadName(currentName) || _isGamepadHandler(currentHandlers)) {
                // Extract eventX
                final match = RegExp(r'event(\d+)').firstMatch(currentHandlers);
                if (match != null) {
                  final path = '/dev/input/event${match.group(1)}';
                  debugPrint('Found gamepad candidate: "$currentName" at $path');
                  paths.add(path);
                }
             }
          }
          // Reset for next block
          currentName = null;
          currentHandlers = null;
          continue;
        }

        if (line.startsWith('N: Name=')) {
          currentName = line.substring(8).replaceAll('"', '').trim();
        } else if (line.startsWith('H: Handlers=')) {
          currentHandlers = line.substring(12).trim();
        }
      }
      
      // Process last block if file doesn't end with newline
      if (currentName != null && currentHandlers != null) {
         if (_isGamepadName(currentName) || _isGamepadHandler(currentHandlers)) {
            final match = RegExp(r'event(\d+)').firstMatch(currentHandlers);
            if (match != null) {
              final path = '/dev/input/event${match.group(1)}';
              debugPrint('Found gamepad candidate: "$currentName" at $path');
              paths.add(path);
            }
         }
      }

    } catch (e) {
      debugPrint('Error scanning /proc/bus/input/devices: $e');
    }
    return paths;
  }

  bool _isGamepadName(String name) {
    final lowerName = name.toLowerCase();
    const keywords = [
      'gamepad', 'controller', 'joystick', 'pad', 
      'xbox', 'playstation', 'nintendo', 'switch',
      'retro', '8bitdo', 'odin', 'android', 'aw869a',
      'ayn' // Added AYN specifically
    ];
    return keywords.any((k) => lowerName.contains(k));
  }

  bool _isGamepadHandler(String handlers) {
    return handlers.contains('js');
  }

  Future<void> _connectToPath(String path, {required bool isEvdev}) async {
    try {
      final file = File(path);
      final subscription = file.openRead().listen(
        (data) => _onData(data, isEvdev),
        onError: (e) => debugPrint('Error reading $path: $e'),
        cancelOnError: true,
      );
      _subscriptions.add(subscription);
      debugPrint('Connected to $path');
    } catch (e) {
      debugPrint('Failed to open $path: $e');
    }
  }

  @override
  void dispose() {
    _stopRepeat();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
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
      // Simple mapping for legacy JS interface
      GamepadButton? button;
      if (number == 0) {
        button = GamepadButton.a;
      } else if (number == 1) {
        button = GamepadButton.b;
      } else if (number == 2) {
        button = GamepadButton.x;
      } else if (number == 3) {
        button = GamepadButton.y;
      } else if (number == 4) {
        button = GamepadButton.l1;
      } else if (number == 5) {
        button = GamepadButton.r1;
      } else if (number == 6) {
        button = GamepadButton.select;
      } else if (number == 7) {
        button = GamepadButton.start;
      }
      
      if (button != null) {
        _handleButton(button, value);
      }
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
      // BTN_TL (L1) = 310
      // BTN_TR (R1) = 311
      // BTN_SELECT = 314
      // BTN_START = 315
      // BTN_MODE (Home) = 316
      // BTN_THUMBL (L3) = 317
      // BTN_THUMBR (R3) = 318
      // BTN_DPAD_UP = 544
      // BTN_DPAD_DOWN = 545
      // BTN_DPAD_LEFT = 546
      // BTN_DPAD_RIGHT = 547
      
      GamepadButton? button;
      if (code == 304) {
        button = GamepadButton.a;
      } else if (code == 305) {
        button = GamepadButton.b;
      } else if (code == 307) {
        button = GamepadButton.x;
      } else if (code == 308) {
        button = GamepadButton.y;
      } else if (code == 310) {
        button = GamepadButton.l1;
      } else if (code == 311) {
        button = GamepadButton.r1;
      } else if (code == 314) {
        button = GamepadButton.select;
      } else if (code == 315) {
        button = GamepadButton.start;
      } else if (code == 544) {
        button = GamepadButton.dpadUp;
      } else if (code == 545) {
        button = GamepadButton.dpadDown;
      } else if (code == 546) {
        button = GamepadButton.dpadLeft;
      } else if (code == 547) {
        button = GamepadButton.dpadRight;
      }
      
      if (button != null) {
        _handleButton(button, value); // value 1=press, 0=release
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

  void _handleButton(GamepadButton button, int value) {
    if (value == 0) {
      _stopRepeat();
      return; // Button release
    }

    // Debounce logic
    final now = DateTime.now();
    // Only debounce non-navigation buttons or use a shorter debounce for them
    if (![GamepadButton.dpadUp, GamepadButton.dpadDown, GamepadButton.dpadLeft, GamepadButton.dpadRight].contains(button)) {
      if (now.difference(_lastButtonTime).inMilliseconds < 200) {
        return;
      }
      _lastButtonTime = now;
    }
    
    _processButton(button);
    _startRepeat(button);
  }

  void _startRepeat(GamepadButton button) {
    _stopRepeat();
    // Only repeat navigation buttons
    if ([GamepadButton.dpadUp, GamepadButton.dpadDown, GamepadButton.dpadLeft, GamepadButton.dpadRight].contains(button)) {
      // Initial delay before repeat
      _repeatTimer = Timer(const Duration(milliseconds: 400), () {
        _repeatTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
           _processButton(button);
        });
      });
    }
  }
  
  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _processButton(GamepadButton button) {
    switch (button) {
      case GamepadButton.a:
        _simulateKey(LogicalKeyboardKey.enter);
        break;
      case GamepadButton.b:
        _simulateKey(LogicalKeyboardKey.escape);
        break;
      case GamepadButton.x:
        _simulateKey(LogicalKeyboardKey.backspace);
        break;
      case GamepadButton.y:
        _simulateKey(LogicalKeyboardKey.tab);
        break;
      case GamepadButton.l1:
        _simulateShiftTab();
        break;
      case GamepadButton.r1:
        _simulateKey(LogicalKeyboardKey.tab);
        break;
      case GamepadButton.dpadUp:
        _simulateKey(LogicalKeyboardKey.arrowUp);
        break;
      case GamepadButton.dpadDown:
        _simulateKey(LogicalKeyboardKey.arrowDown);
        break;
      case GamepadButton.dpadLeft:
        _simulateKey(LogicalKeyboardKey.arrowLeft);
        break;
      case GamepadButton.dpadRight:
        _simulateKey(LogicalKeyboardKey.arrowRight);
        break;
      default:
        break;
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
          _simulateKey(LogicalKeyboardKey.arrowLeft);
        } else {
          _simulateKey(LogicalKeyboardKey.arrowRight);
        }
      } else if (number == 7 || number == 1) { // Y Axis
        if (value < 0) {
          _simulateKey(LogicalKeyboardKey.arrowUp);
        } else {
          _simulateKey(LogicalKeyboardKey.arrowDown);
        }
      }
    }
  }

  void _simulateKey(LogicalKeyboardKey key) {
    final physicalKey = _getPhysicalKey(key);
    final now = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
    
    final downEvent = KeyDownEvent(
      physicalKey: physicalKey,
      logicalKey: key,
      timeStamp: now,
    );
    
    _dispatchKey(downEvent);
    
    final upEvent = KeyUpEvent(
      physicalKey: physicalKey,
      logicalKey: key,
      timeStamp: now,
    );
    
    _dispatchKey(upEvent);
  }

  void _simulateShiftTab() {
    final shiftPhysical = PhysicalKeyboardKey.shiftLeft;
    final shiftLogical = LogicalKeyboardKey.shiftLeft;
    final tabPhysical = PhysicalKeyboardKey.tab;
    final tabLogical = LogicalKeyboardKey.tab;
    
    final now = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);

    _dispatchKey(KeyDownEvent(
      physicalKey: shiftPhysical,
      logicalKey: shiftLogical,
      timeStamp: now,
    ));

    _dispatchKey(KeyDownEvent(
      physicalKey: tabPhysical,
      logicalKey: tabLogical,
      timeStamp: now,
    ));

    _dispatchKey(KeyUpEvent(
      physicalKey: tabPhysical,
      logicalKey: tabLogical,
      timeStamp: now,
    ));

    _dispatchKey(KeyUpEvent(
      physicalKey: shiftPhysical,
      logicalKey: shiftLogical,
      timeStamp: now,
    ));
  }

  void _dispatchKey(KeyEvent event) {
    FocusNode? node = FocusManager.instance.primaryFocus;
    KeyEventResult result = KeyEventResult.ignored;
    
    while (node != null && result == KeyEventResult.ignored) {
      if (node.onKeyEvent != null) {
        result = node.onKeyEvent!(node, event);
      }
      if (result == KeyEventResult.ignored) {
        node = node.parent;
      }
    }
  }

  PhysicalKeyboardKey _getPhysicalKey(LogicalKeyboardKey logical) {
    if (logical == LogicalKeyboardKey.arrowUp) return PhysicalKeyboardKey.arrowUp;
    if (logical == LogicalKeyboardKey.arrowDown) return PhysicalKeyboardKey.arrowDown;
    if (logical == LogicalKeyboardKey.arrowLeft) return PhysicalKeyboardKey.arrowLeft;
    if (logical == LogicalKeyboardKey.arrowRight) return PhysicalKeyboardKey.arrowRight;
    if (logical == LogicalKeyboardKey.enter) return PhysicalKeyboardKey.enter;
    if (logical == LogicalKeyboardKey.escape) return PhysicalKeyboardKey.escape;
    if (logical == LogicalKeyboardKey.tab) return PhysicalKeyboardKey.tab;
    if (logical == LogicalKeyboardKey.backspace) return PhysicalKeyboardKey.backspace;
    if (logical == LogicalKeyboardKey.shiftLeft) return PhysicalKeyboardKey.shiftLeft;
    return PhysicalKeyboardKey.f1; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
