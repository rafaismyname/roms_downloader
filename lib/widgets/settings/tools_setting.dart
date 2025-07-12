import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';

class ToolsSetting extends ConsumerWidget {
  final Console? console;

  const ToolsSetting({
    super.key,
    required this.console,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogNotifier = ref.read(catalogProvider.notifier);

    return ListTile(
      leading: const Icon(Icons.delete_sweep),
      title: const Text('Clear Catalog Cache'),
      subtitle: console != null
          ? const Text('Clear cache for this console')
          : const Text('Clear cache for all consoles'),
      trailing: IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => _showClearCacheDialog(context, catalogNotifier),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, CatalogNotifier catalogNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Catalog Cache'),
        content: Text(
          console != null
              ? 'Are you sure you want to clear the catalog cache for ${console!.name}?'
              : 'Are you sure you want to clear the catalog cache for all consoles?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await catalogNotifier.clearCatalogCache(console?.id);
              await catalogNotifier.refreshCatalog();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Catalog cache cleared')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
