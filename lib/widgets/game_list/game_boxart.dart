import 'package:flutter/material.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

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
      key: ValueKey('boxart_${game.taskId}'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              child: PhotoView(
                imageProvider: CachedNetworkImageProvider(boxart),
                backgroundDecoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3.0,
                onTapUp: (context, details, controllerValue) => Navigator.of(context).pop(),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: CachedNetworkImage(
            imageUrl: boxart,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => _DefaultPlaceholder(size: size),
            progressIndicatorBuilder: (context, url, downloadProgress) => Container(
              width: size,
              height: size,
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: downloadProgress.progress,
                  ),
                ),
              ),
            ),
          ),
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
