import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/widgets/common/loading_indicator.dart';

class GameBoxart extends StatefulWidget {
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
  State<GameBoxart> createState() => _GameBoxartState();
}

class _GameBoxartState extends State<GameBoxart> {
  bool _hasFocus = false;
  bool disableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS');

  @override
  Widget build(BuildContext context) {
    final boxart = widget.game.boxart;

    if (boxart == null) {
      return widget.placeholder ?? _DefaultPlaceholder(size: widget.size);
    }

    return Container(
      key: ValueKey('boxart_${widget.game.gameId}'),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: _hasFocus
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: _hasFocus ? 2 : 1,
        ),
      ),
      child: InkWell(
        onFocusChange: (value) => setState(() => _hasFocus = value),
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
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            fadeInDuration: disableAnimations ? Duration.zero : const Duration(milliseconds: 300),
            fadeOutDuration: disableAnimations ? Duration.zero : const Duration(milliseconds: 300),
            errorWidget: (context, url, error) => _DefaultPlaceholder(size: widget.size),
            errorListener: (value) => debugPrint('Error loading boxart: $value'),
            progressIndicatorBuilder: (context, url, downloadProgress) => Container(
              width: widget.size,
              height: widget.size,
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: SizedBox(
                  width: widget.size * 0.4,
                  height: widget.size * 0.4,
                  child: LoadingIndicator(
                    strokeWidth: 2,
                    value: downloadProgress.progress,
                    size: widget.size * 0.4,
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
        borderRadius: BorderRadius.circular(2),
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
