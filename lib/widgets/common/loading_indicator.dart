import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double strokeWidth;
  final double? size;
  final Color? color;
  final double? value;

  const LoadingIndicator({
    super.key,
    this.strokeWidth = 2.0,
    this.size,
    this.color,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    const bool disableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS');

    if (disableAnimations) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            Icons.hourglass_top_rounded,
            size: size != null ? size! * 0.8 : 24,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color,
        value: value,
      ),
    );
  }
}
