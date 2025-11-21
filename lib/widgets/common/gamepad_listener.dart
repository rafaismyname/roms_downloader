import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';

class GamepadListener extends StatefulWidget {
  final Widget child;

  const GamepadListener({super.key, required this.child});

  @override
  State<GamepadListener> createState() => _GamepadListenerState();
}

class _GamepadListenerState extends State<GamepadListener> {
  StreamSubscription<GamepadEvent>? _subscription;
  DateTime _lastEventTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _subscription = Gamepads.events.listen(_onGamepadEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onGamepadEvent(GamepadEvent event) {
    // Simple debounce to prevent double inputs if the controller is noisy
    final now = DateTime.now();
    if (now.difference(_lastEventTime).inMilliseconds < 100) {
      return;
    }
    _lastEventTime = now;

    // Only handle button presses (value > 0.5)
    if (event.value < 0.5) return;

    final key = event.key.toLowerCase();
    
    // Navigation
    if (key.contains('dpad-up') || key.contains('dpup')) {
      _moveFocus(TraversalDirection.up);
    } else if (key.contains('dpad-down') || key.contains('dpdown')) {
      _moveFocus(TraversalDirection.down);
    } else if (key.contains('dpad-left') || key.contains('dpleft')) {
      _moveFocus(TraversalDirection.left);
    } else if (key.contains('dpad-right') || key.contains('dpright')) {
      _moveFocus(TraversalDirection.right);
    } 
    // Actions
    else if (key.contains('button-a') || key.contains('btn-south')) {
      _activateFocus();
    } else if (key.contains('button-b') || key.contains('btn-east')) {
      // Back/Dismiss logic could go here, but usually handled by Navigator.pop
      // We can try to simulate a back button press
      // Navigator.maybePop(context); // Context might be tricky here if not using a global key
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
      // Simulate a tap/enter
      // This is tricky. Focus nodes don't have a generic "activate".
      // But we can look for InkWells or Buttons.
      // Or we can rely on the fact that if we are using Shortcuts/Actions, we could invoke the ActivateIntent.
      // But we are bypassing Shortcuts.
      
      // Best bet: Find the widget and simulate a tap? No.
      // Use Actions.invoke?
      
      final context = primaryFocus.context;
      if (context != null) {
        final action = Actions.maybeFind<ActivateIntent>(context);
        if (action != null) {
          Actions.invoke(context, const ActivateIntent());
          return;
        }
        
        // Fallback for InkWell/Buttons that might not handle ActivateIntent explicitly but usually do via ButtonStyleButton
        // Actually, InkWell handles ActivateIntent.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
