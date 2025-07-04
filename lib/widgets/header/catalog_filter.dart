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
            maxHeight: MediaQuery.of(context).size.height * 0.6, // Limit to 60% of screen height
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
                  Text('Dump Types', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Good Dumps'),
                        selected: filter.showGoodDumps,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('goodDumps', value),
                      ),
                      FilterChip(
                        label: const Text('Bad Dumps'),
                        selected: filter.showBadDumps,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('badDumps', value),
                      ),
                      FilterChip(
                        label: const Text('Overdumps'),
                        selected: filter.showOverdumps,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('overdumps', value),
                      ),
                      FilterChip(
                        label: const Text('Hacks'),
                        selected: filter.showHacks,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('hacks', value),
                      ),
                      FilterChip(
                        label: const Text('Translations'),
                        selected: filter.showTranslations,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('translations', value),
                      ),
                      FilterChip(
                        label: const Text('Alternates'),
                        selected: filter.showAlternates,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('alternates', value),
                      ),
                      FilterChip(
                        label: const Text('Fixed'),
                        selected: filter.showFixed,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('fixed', value),
                      ),
                      FilterChip(
                        label: const Text('Trainer'),
                        selected: filter.showTrainer,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('trainer', value),
                      ),
                      FilterChip(
                        label: const Text('Unlicensed'),
                        selected: filter.showUnlicensed,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('unlicensed', value),
                      ),
                      FilterChip(
                        label: const Text('Demos'),
                        selected: filter.showDemos,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('demos', value),
                      ),
                      FilterChip(
                        label: const Text('Samples'),
                        selected: filter.showSamples,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('samples', value),
                      ),
                      FilterChip(
                        label: const Text('Prototypes'),
                        selected: filter.showProtos,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('protos', value),
                      ),
                      FilterChip(
                        label: const Text('Betas'),
                        selected: filter.showBetas,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('betas', value),
                      ),
                      FilterChip(
                        label: const Text('Alphas'),
                        selected: filter.showAlphas,
                        onSelected: (value) => catalogNotifier.toggleDumpTypeFilter('alphas', value),
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
