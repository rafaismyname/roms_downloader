import 'package:flutter/material.dart';

class DownloadButton extends StatelessWidget {
  final bool isCompact;
  final bool isEnabled;
  final bool isDownloading;
  final bool isLoading;
  final int selectedCount;
  final VoidCallback onPressed;

  const DownloadButton({
    super.key,
    required this.isCompact,
    required this.isEnabled,
    required this.isDownloading,
    required this.isLoading,
    required this.selectedCount,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDownloading)
              SizedBox(
                width: isCompact ? 12 : 16,
                height: isCompact ? 12 : 16,
                child: CircularProgressIndicator(
                  strokeWidth: isCompact ? 2 : 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                ),
              )
            else if (!isLoading)
              Icon(
                Icons.download_rounded,
                size: isCompact ? 14 : 18,
              ),
            SizedBox(width: isCompact ? 4 : 8),
            Text(
              isCompact
                  ? (isDownloading
                      ? "DL..."
                      : isLoading
                          ? "..."
                          : "DL ($selectedCount)")
                  : (isDownloading
                      ? "Downloading..."
                      : isLoading
                          ? "Loading..."
                          : "Download Selected"),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 11 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
