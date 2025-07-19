import 'package:flutter/material.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_metadata_model.dart';

class GameTags extends StatelessWidget {
  final Game game;

  const GameTags({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final tags = _getGameTags();
    if (tags.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 2),
        Wrap(
          spacing: 3,
          runSpacing: 2,
          children: tags
              .map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getTagColor(tag),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  List<String> _getGameTags() {
    final tags = <String>[];
    final metadata = game.metadata;
    if (metadata == null) return tags;

    if (metadata.dumpQualities.contains(DumpQuality.badDump)) tags.add('Bad');
    if (metadata.dumpQualities.contains(DumpQuality.overdump)) tags.add('Over');

    if (metadata.romTypes.contains(RomType.demo)) tags.add('Demo');
    if (metadata.romTypes.contains(RomType.sample)) tags.add('Sample');
    if (metadata.romTypes.contains(RomType.proto)) tags.add('Proto');
    if (metadata.romTypes.contains(RomType.beta)) tags.add('Beta');
    if (metadata.romTypes.contains(RomType.alpha)) tags.add('Alpha');
    if (metadata.romTypes.contains(RomType.bios)) tags.add('BIOS');

    if (metadata.modifications.contains(ModificationType.hack)) tags.add('Hack');
    if (metadata.modifications.contains(ModificationType.translation)) tags.add('Transl.');
    if (metadata.modifications.contains(ModificationType.fixed)) tags.add('Fixed');
    if (metadata.modifications.contains(ModificationType.trainer)) tags.add('Trainer');

    if (metadata.distributionTypes.contains(DistributionType.alternate)) tags.add('Alt');
    if (metadata.distributionTypes.contains(DistributionType.unlicensed)) tags.add('Unlic');
    if (metadata.distributionTypes.contains(DistributionType.aftermarket)) tags.add('After');
    if (metadata.distributionTypes.contains(DistributionType.pirate)) tags.add('Pirate');

    return tags;
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'Bad':
      case 'Over':
        return Colors.red.shade600;
      case 'Demo':
      case 'Sample':
      case 'Proto':
      case 'Beta':
      case 'Alpha':
        return Colors.orange.shade600;
      case 'Hack':
      case 'Transl.':
      case 'Fixed':
      case 'Trainer':
        return Colors.blue.shade600;
      case 'Alt':
      case 'Unlic':
      case 'After':
      case 'Pirate':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
