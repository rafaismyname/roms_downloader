import 'package:flutter/material.dart';

class DownloadButton extends StatelessWidget {
  final bool isEnabled;
  final bool isDownloading;
  final bool isLoading;
  final VoidCallback onPressed;

  const DownloadButton({
    super.key,
    required this.isEnabled,
    required this.isDownloading,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          Icons.download_rounded,
        ),
      ),
    );
  }
}
