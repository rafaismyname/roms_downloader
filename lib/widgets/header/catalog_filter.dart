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
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (catalogState.availableRegions.isNotEmpty) ...[
                    Text('Regions', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: catalogState.availableRegions.map((region) {
                        final isSelected = filter.regions.contains(region);
                        return FilterChip(
                          label: Text(region),
                          selected: isSelected,
                          onSelected: (_) => catalogNotifier.toggleRegionFilter(region),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (catalogState.availableLanguages.isNotEmpty) ...[
                    Text('Languages', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: catalogState.availableLanguages.map((language) {
                        final isSelected = filter.languages.contains(language);
                        return FilterChip(
                          label: Text(language),
                          selected: isSelected,
                          onSelected: (_) => catalogNotifier.toggleLanguageFilter(language),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Dump Qualities', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Good Dumps'),
                        selected: filter.dumpQualities.contains('goodDump'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('dumpQualities', 'goodDump'),
                      ),
                      FilterChip(
                        label: const Text('Bad Dumps'),
                        selected: filter.dumpQualities.contains('badDump'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('dumpQualities', 'badDump'),
                      ),
                      FilterChip(
                        label: const Text('Overdumps'),
                        selected: filter.dumpQualities.contains('overdump'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('dumpQualities', 'overdump'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('ROM Types', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Demos'),
                        selected: filter.romTypes.contains('demo'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('romTypes', 'demo'),
                      ),
                      FilterChip(
                        label: const Text('Samples'),
                        selected: filter.romTypes.contains('sample'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('romTypes', 'sample'),
                      ),
                      FilterChip(
                        label: const Text('Prototypes'),
                        selected: filter.romTypes.contains('proto'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('romTypes', 'proto'),
                      ),
                      FilterChip(
                        label: const Text('Betas'),
                        selected: filter.romTypes.contains('beta'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('romTypes', 'beta'),
                      ),
                      FilterChip(
                        label: const Text('Alphas'),
                        selected: filter.romTypes.contains('alpha'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('romTypes', 'alpha'),
                      ),
                      FilterChip(
                        label: const Text('Normal ROMs'),
                        selected: filter.romTypes.contains('normal'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('romTypes', 'normal'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Modifications', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Hacks'),
                        selected: filter.modifications.contains('hack'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('modifications', 'hack'),
                      ),
                      FilterChip(
                        label: const Text('Translations'),
                        selected: filter.modifications.contains('translation'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('modifications', 'translation'),
                      ),
                      FilterChip(
                        label: const Text('Fixed'),
                        selected: filter.modifications.contains('fixed'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('modifications', 'fixed'),
                      ),
                      FilterChip(
                        label: const Text('Trainer'),
                        selected: filter.modifications.contains('trainer'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('modifications', 'trainer'),
                      ),
                      FilterChip(
                        label: const Text('Unmodified'),
                        selected: filter.modifications.contains('none'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('modifications', 'none'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Distribution Types', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Enhanced'),
                        selected: filter.distributionTypes.contains('enhanced'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('distributionTypes', 'enhanced'),
                      ),
                      FilterChip(
                        label: const Text('Special Editions'),
                        selected: filter.distributionTypes.contains('specialEdition'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('distributionTypes', 'specialEdition'),
                      ),
                      FilterChip(
                        label: const Text('Alternates'),
                        selected: filter.distributionTypes.contains('alternate'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('distributionTypes', 'alternate'),
                      ),
                      FilterChip(
                        label: const Text('Unlicensed'),
                        selected: filter.distributionTypes.contains('unlicensed'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('distributionTypes', 'unlicensed'),
                      ),
                      FilterChip(
                        label: const Text('Aftermarket'),
                        selected: filter.distributionTypes.contains('aftermarket'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('distributionTypes', 'aftermarket'),
                      ),
                      FilterChip(
                        label: const Text('Pirate'),
                        selected: filter.distributionTypes.contains('pirate'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('distributionTypes', 'pirate'),
                      ),
                      FilterChip(
                        label: const Text('Multi-Cart'),
                        selected: filter.distributionTypes.contains('multiCart'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('distributionTypes', 'multiCart'),
                      ),
                      FilterChip(
                        label: const Text('Standard'),
                        selected: filter.distributionTypes.contains('standard'),
                        onSelected: (_) => catalogNotifier.toggleFlagFilter('distributionTypes', 'standard'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: catalogNotifier.clearFilters,
                        child: const Text('Clear All'),
                      ),
                      const Spacer(),
                      Text(
                        '${catalogState.filteredGames.length} games',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
