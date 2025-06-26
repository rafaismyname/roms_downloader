import 'package:flutter/material.dart';

class DownloadButton extends StatelessWidget {
  final bool isCompact;
  final bool isEnabled;
  final bool isDownloading;
  final bool isLoading;
  final VoidCallback onPressed;

  const DownloadButton({
    super.key,
    required this.isCompact,
    required this.isEnabled,
    required this.isDownloading,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isCompact ? 32 : null,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: isCompact ? const EdgeInsets.symmetric(horizontal: 12) : const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          ),
          minimumSize: isCompact ? Size.zero : null,
        ),
        child: Icon(
          Icons.download_rounded,
          size: isCompact ? 14 : 18,
        ),
      ),
    );
  }
}
