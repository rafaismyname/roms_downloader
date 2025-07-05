import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/catalog_filter_model.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';

class FilterModal extends ConsumerWidget {
  const FilterModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => const FilterModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogProvider);
    final catalogNotifier = ref.read(catalogProvider.notifier);
    final filter = catalogState.filter;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (catalogState.availableRegions.isNotEmpty) ...[
                    _FilterSection(
                      title: 'Regions',
                      icon: Icons.public,
                      items: catalogState.availableRegions.toList(),
                      selectedItems: filter.regions,
                      onToggle: catalogNotifier.toggleRegionFilter,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (catalogState.availableLanguages.isNotEmpty) ...[
                    _FilterSection(
                      title: 'Languages',
                      icon: Icons.language,
                      items: catalogState.availableLanguages.toList(),
                      selectedItems: filter.languages,
                      onToggle: catalogNotifier.toggleLanguageFilter,
                    ),
                    const SizedBox(height: 20),
                  ],
                  _AdvancedFiltersSection(
                    filter: filter,
                    catalogNotifier: catalogNotifier,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.games,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${catalogState.filteredGamesCount} games',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: catalogNotifier.clearFilters,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: catalogNotifier.defaultFilters,
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final List<String>? labels;
  final Set<String> selectedItems;
  final Function(String) onToggle;

  const _FilterSection({
    required this.title,
    required this.icon,
    required this.items,
    this.labels,
    required this.selectedItems,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final label = labels?[index] ?? item;
            final isSelected = selectedItems.contains(item);

            return FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onToggle(item),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AdvancedFiltersSection extends StatefulWidget {
  final CatalogFilter filter;
  final CatalogNotifier catalogNotifier;

  const _AdvancedFiltersSection({
    required this.filter,
    required this.catalogNotifier,
  });

  @override
  State<_AdvancedFiltersSection> createState() => _AdvancedFiltersSectionState();
}

class _AdvancedFiltersSectionState extends State<_AdvancedFiltersSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasAdvancedFilters = widget.filter.dumpQualities.isNotEmpty ||
        widget.filter.romTypes.isNotEmpty ||
        widget.filter.modifications.isNotEmpty ||
        widget.filter.distributionTypes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: hasAdvancedFilters ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Advanced Filters',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: hasAdvancedFilters ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 12),
          _FilterSection(
            title: 'Quality',
            icon: Icons.verified,
            items: const ['goodDump', 'badDump', 'overdump'],
            labels: const ['Good', 'Bad', 'Overdump'],
            selectedItems: widget.filter.dumpQualities,
            onToggle: (item) => widget.catalogNotifier.toggleFlagFilter('dumpQualities', item),
          ),
          const SizedBox(height: 20),
          _FilterSection(
            title: 'Type',
            icon: Icons.category,
            items: const ['normal', 'demo', 'sample', 'proto', 'beta', 'alpha'],
            labels: const ['Normal', 'Demo', 'Sample', 'Proto', 'Beta', 'Alpha'],
            selectedItems: widget.filter.romTypes,
            onToggle: (item) => widget.catalogNotifier.toggleFlagFilter('romTypes', item),
          ),
          const SizedBox(height: 20),
          _FilterSection(
            title: 'Modifications',
            icon: Icons.build,
            items: const ['none', 'hack', 'translation', 'fixed', 'trainer'],
            labels: const ['Original', 'Hack', 'Translation', 'Fixed', 'Trainer'],
            selectedItems: widget.filter.modifications,
            onToggle: (item) => widget.catalogNotifier.toggleFlagFilter('modifications', item),
          ),
          const SizedBox(height: 20),
          _FilterSection(
            title: 'Distribution',
            icon: Icons.inventory,
            items: const ['standard', 'alternate', 'unlicensed', 'aftermarket', 'pirate', 'multiCart'],
            labels: const ['Standard', 'Alternate', 'Unlicensed', 'Aftermarket', 'Pirate', 'Multi-Cart'],
            selectedItems: widget.filter.distributionTypes,
            onToggle: (item) => widget.catalogNotifier.toggleFlagFilter('distributionTypes', item),
          ),
        ],
      ],
    );
  }
}
