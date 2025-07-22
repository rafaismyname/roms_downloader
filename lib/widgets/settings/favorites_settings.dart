import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/providers/favorites_provider.dart';

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
        content: Text('Are you sure you want to delete the current export? This will permanently remove the shared token.'),
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
                    Icon(Icons.favorite, color: theme.colorScheme.primary),
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
                            '${favorites.count} games marked as favorites',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (favorites.isNotEmpty) ...[
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _clearFavorites,
                      icon: Icon(Icons.clear_all),
                      label: Text('Clear All Favorites'),
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
                    Icon(Icons.cloud_upload, color: theme.colorScheme.primary),
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
                            'Export your favorites to get a shareable token',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: favorites.isNotEmpty && !_isExporting ? _exportFavorites : null,
                    icon: _isExporting ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.upload),
                    label: Text(_isExporting ? 'Exporting...' : 'Export Favorites'),
                  ),
                ),
                if (favorites.exportSlug != null) ...[
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.link, size: 16, color: theme.colorScheme.onSurfaceVariant),
                            SizedBox(width: 8),
                            Text(
                              'Export Token',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _copyToClipboard(favorites.exportSlug!),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          favorites.exportSlug!,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.copy, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: _isDeleting ? null : _deleteExport,
                              child: Container(
                                padding: EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                                ),
                                child: _isDeleting
                                    ? SizedBox(
                                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onErrorContainer))
                                    : Icon(Icons.delete, size: 16, color: theme.colorScheme.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                        if (favorites.lastExported != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'Last exported: ${_formatDateTime(favorites.lastExported!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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
                    Icon(Icons.cloud_download, color: theme.colorScheme.primary),
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
                            'Import favorites using your export token',
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
                TextField(
                  controller: _importController,
                  decoration: InputDecoration(
                    labelText: 'Import Token',
                    hintText: 'Enter token (e.g., abc123:xyz...)',
                    border: OutlineInputBorder(),
                    suffixIcon: _importController.text.trim().isNotEmpty
                        ? IconButton(
                            onPressed: () => setState(() => _importController.clear()),
                            icon: Icon(Icons.clear),
                          )
                        : null,
                  ),
                  enabled: !_isImporting,
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _importController.text.trim().isNotEmpty && !_isImporting ? _importFavorites : null,
                    icon: _isImporting ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.download),
                    label: Text(_isImporting ? 'Importing...' : 'Import Favorites'),
                  ),
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
