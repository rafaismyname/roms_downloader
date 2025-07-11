import 'package:flutter/material.dart';
import 'package:roms_downloader/models/game_model.dart';

class GameBoxart extends StatelessWidget {
  final Game game;
  final double size;
  final Widget? placeholder;

  const GameBoxart({
    super.key,
    required this.game,
    this.size = 40,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final boxart = game.boxart;

    if (boxart == null) {
      return placeholder ?? _DefaultPlaceholder(size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.network(
          boxart,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _DefaultPlaceholder(size: size),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DefaultPlaceholder extends StatelessWidget {
  final double size;

  const _DefaultPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
