import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/providers/favorites_provider.dart';
import 'package:roms_downloader/widgets/common/loading_indicator.dart';

class FavoritesSettings extends ConsumerStatefulWidget {
  const FavoritesSettings({super.key});

  @override
  ConsumerState<FavoritesSettings> createState() => _FavoritesSettingsState();
}

class _FavoritesSettingsState extends ConsumerState<FavoritesSettings> {
  final TextEditingController _importController = TextEditingController();
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _exportFavorites() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      await ref.read(favoritesProvider.notifier).exportFavorites();
      _showSnackBar('Favorites exported successfully!');
    } catch (e) {
      _showSnackBar('Failed to export favorites', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importFavorites() async {
    final slug = _importController.text.trim();
    if (slug.isEmpty || _isImporting) return;

    setState(() => _isImporting = true);

    try {
      await ref.read(favoritesProvider.notifier).importFavorites(slug, merge: true);
      _importController.clear();
      _showSnackBar('Favorites imported successfully!');
    } catch (e) {
      _showSnackBar('Failed to import favorites', isError: true);
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _clearFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Favorites'),
        content: Text('Are you sure you want to remove all favorites? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(favoritesProvider.notifier).clearFavorites();
      _showSnackBar('Favorites cleared');
    }
  }

  Future<void> _deleteExport() async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Export'),
        content: Text('Are you sure you want to delete the current export? This will permanently remove the shared code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);

      try {
        await ref.read(favoritesProvider.notifier).deleteExport();
        _showSnackBar('Export deleted successfully');
      } catch (e) {
        _showSnackBar('Failed to delete export', isError: true);
      } finally {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final theme = Theme.of(context);

    final displayableCode = favorites.exportSlug?.split(':').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_outline, color: theme.colorScheme.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Favorites Summary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${favorites.count} favorite${favorites.count == 1 ? '' : 's'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (favorites.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _clearFavorites,
                        icon: Icon(Icons.clear, size: 18),
                        label: Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: theme.colorScheme.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Favorites',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Export your favorites',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: favorites.isNotEmpty && !_isExporting ? _exportFavorites : null,
                      icon: _isExporting
                          ? LoadingIndicator(size: 18, strokeWidth: 2)
                          : Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(_isExporting ? 'Exporting' : 'Export'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                  ],
                ),
                if (displayableCode != null) ...[
                  SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export Code',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Last exported: ${_formatDateTime(favorites.lastExported!)}",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: Platform.isAndroid ? 0 : 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayableCode,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _copyToClipboard(displayableCode),
                                icon: Icon(Icons.copy, size: 18),
                                tooltip: 'Copy',
                                style: IconButton.styleFrom(
                                  minimumSize: Size(32, 32),
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _isDeleting ? null : _deleteExport,
                                icon: _isDeleting
                                    ? LoadingIndicator(size: 16, strokeWidth: 2)
                                    : Icon(Icons.delete_outline, size: 18),
                                tooltip: 'Delete export',
                                style: IconButton.styleFrom(
                                  minimumSize: Size(32, 32),
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_download_outlined, color: theme.colorScheme.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Favorites',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Import favorites using an export code',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _importController,
                        decoration: InputDecoration(
                          hintText: 'Enter code (e.g., abcd.fav)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          suffixIcon: _importController.text.trim().isNotEmpty
                              ? IconButton(
                                  onPressed: () => setState(() => _importController.clear()),
                                  icon: Icon(Icons.clear),
                                  tooltip: 'Clear',
                                )
                              : null,
                        ),
                        enabled: !_isImporting,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(width: 12),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _importController.text.trim().isNotEmpty && !_isImporting ? _importFavorites : null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          foregroundColor: theme.colorScheme.onSecondaryContainer,
                          padding: EdgeInsets.zero,
                          minimumSize: Size(48, 48),
                        ),
                        child:
                            _isImporting ? LoadingIndicator(size: 18, strokeWidth: 2) : Icon(Icons.download, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
