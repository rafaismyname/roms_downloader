import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';

class CatalogFilter extends ConsumerWidget {
  const CatalogFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogProvider);
    final catalogNotifier = ref.read(catalogProvider.notifier);
    final filter = catalogState.filter;

    return ExpansionTile(
      leading: Icon(
        filter.isActive ? Icons.filter_alt : Icons.filter_alt_outlined,
        color: filter.isActive ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        'Filters',
        style: TextStyle(
          color: filter.isActive ? Theme.of(context).colorScheme.primary : null,
          fontWeight: filter.isActive ? FontWeight.bold : null,
        ),
      ),
      children: [
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (catalogState.availableRegions.isNotEmpty) ...[
                    _SectionHeader(icon: Icons.public, title: 'Regions'),
                    const SizedBox(height: 2),
                    _FilterChipGroup(
                      items: catalogState.availableRegions.toList(),
                      selectedItems: filter.regions,
                      onToggle: (region) => catalogNotifier.toggleRegionFilter(region),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (catalogState.availableLanguages.isNotEmpty) ...[
                    _SectionHeader(icon: Icons.language, title: 'Languages'),
                    const SizedBox(height: 2),
                    _FilterChipGroup(
                      items: catalogState.availableLanguages.toList(),
                      selectedItems: filter.languages,
                      onToggle: (language) => catalogNotifier.toggleLanguageFilter(language),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    leading: const Icon(Icons.tune, size: 20),
                    title: const Text(
                      'Advanced Filters',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    children: [
                      _SectionHeader(icon: Icons.verified, title: 'Dump Qualities'),
                      const SizedBox(height: 8),
                      _FilterChipGroup(
                        items: const ['goodDump', 'badDump', 'overdump'],
                        labels: const ['Good', 'Bad', 'Overdump'],
                        selectedItems: filter.dumpQualities,
                        onToggle: (quality) => catalogNotifier.toggleFlagFilter('dumpQualities', quality),
                      ),
                      const SizedBox(height: 8),
                      _SectionHeader(icon: Icons.category, title: 'ROM Types'),
                      const SizedBox(height: 8),
                      _FilterChipGroup(
                        items: const ['normal', 'demo', 'sample', 'proto', 'beta', 'alpha'],
                        labels: const ['Normal', 'Demo', 'Sample', 'Proto', 'Beta', 'Alpha'],
                        selectedItems: filter.romTypes,
                        onToggle: (type) => catalogNotifier.toggleFlagFilter('romTypes', type),
                      ),
                      const SizedBox(height: 8),
                      _SectionHeader(icon: Icons.build, title: 'Modifications'),
                      const SizedBox(height: 8),
                      _FilterChipGroup(
                        items: const ['none', 'hack', 'translation', 'fixed', 'trainer'],
                        labels: const ['Original', 'Hack', 'Translation', 'Fixed', 'Trainer'],
                        selectedItems: filter.modifications,
                        onToggle: (mod) => catalogNotifier.toggleFlagFilter('modifications', mod),
                      ),
                      const SizedBox(height: 8),
                      _SectionHeader(icon: Icons.inventory, title: 'Distribution'),
                      const SizedBox(height: 8),
                      _FilterChipGroup(
                        items: const ['standard', 'enhanced', 'specialEdition', 'alternate', 'unlicensed', 'aftermarket', 'pirate', 'multiCart'],
                        labels: const ['Standard', 'Enhanced', 'Special Ed.', 'Alternate', 'Unlicensed', 'Aftermarket', 'Pirate', 'Multi-Cart'],
                        selectedItems: filter.distributionTypes,
                        onToggle: (type) => catalogNotifier.toggleFlagFilter('distributionTypes', type),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          Icons.games,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${catalogState.filteredGames.length} games found',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: catalogNotifier.clearFilters,
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Clear'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: catalogNotifier.defaultFilters,
                          icon: const Icon(Icons.restart_alt, size: 16),
                          label: const Text('Default'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipGroup extends StatelessWidget {
  final List<String> items;
  final List<String>? labels;
  final Set<String> selectedItems;
  final Function(String) onToggle;

  const _FilterChipGroup({
    required this.items,
    this.labels,
    required this.selectedItems,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 3,
      runSpacing: 1,
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
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onToggle(item),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
