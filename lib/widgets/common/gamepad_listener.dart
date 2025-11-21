import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roms_downloader/widgets/common/linux_gamepad_listener.dart';

class GamepadListener extends StatelessWidget {
  final Widget child;

  const GamepadListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    Widget widget = child;

    // Add default shortcuts for game controllers that act as keyboards
    // This handles cases where the OS/Embedder maps gamepad buttons to keys
    widget = Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonB): const DismissIntent(),
      },
      child: widget,
    );

    // On Linux, add the direct /dev/input/js* listener
    // This handles cases where the OS/Embedder does NOT map gamepad buttons to keys
    // or when we want to support raw input (common on embedded Linux like Rocknix)
    if (Platform.isLinux) {
      widget = LinuxGamepadListener(child: widget);
    }

    return widget;
  }
}
