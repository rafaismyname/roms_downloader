import 'package:path/path.dart' as p;

enum LibraryPresence { none, file, extracted, fileAndExtracted }

class LibrarySnapshot {
  final String libraryDir;
  final Set<String> exactFiles;
  final Set<String> baseNames;
  final Map<String, List<String>> relatedFiles;

  final DateTime timestamp;

  const LibrarySnapshot({
    required this.libraryDir,
    required this.exactFiles,
    required this.baseNames,
    required this.relatedFiles,
    required this.timestamp,
  });

  LibraryPresence statusFor(String filename) {
    final base = p.basename(filename);
    final ext = p.extension(base).toLowerCase();
    final baseNoExt = p.basenameWithoutExtension(base);
    final hasExact = exactFiles.contains(base);

    // Files we indexed for this base (includes root siblings and any files from an extracted folder)
    final rel = relatedFiles[baseNoExt] ?? const <String>[];

    // 1) Treat as extracted if there are files under .../<baseNoExt>/...
    final hasDirContent = rel.any((abs) {
      final parent = p.basename(p.dirname(abs));
      return parent == baseNoExt;
    });

    // 2) Or if there is a root-level sibling with same base but different extension
    final hasSiblingDifferentExtAtRoot = rel.any((abs) {
      if (p.dirname(abs) != libraryDir) return false; // only root-level
      final b = p.basename(abs);
      return p.basenameWithoutExtension(b) == baseNoExt && p.extension(b).toLowerCase() != ext;
    });

    final extracted = hasDirContent || hasSiblingDifferentExtAtRoot;

    if (hasExact && extracted) return LibraryPresence.fileAndExtracted;
    if (extracted) return LibraryPresence.extracted;
    if (hasExact) return LibraryPresence.file;
    return LibraryPresence.none;
  }

  Map<String, LibraryPresence> statusesFor(Iterable<String> filenames) {
    final result = <String, LibraryPresence>{};
    for (final f in filenames) {
      result[f] = statusFor(f);
    }
    return result;
  }

  Map<String, LibraryPresence> allStatuses() {
    final map = <String, LibraryPresence>{};
    for (final f in exactFiles) {
      map[f] = LibraryPresence.file;
    }
    for (final b in baseNames) {
      final hasExact = exactFiles.any((f) => p.basenameWithoutExtension(f) == b);
      map[b] = hasExact ? LibraryPresence.fileAndExtracted : LibraryPresence.extracted;
    }
    return map;
  }

  List<String> relatedFilesFor(String filename) {
    final base = p.basenameWithoutExtension(p.basename(filename));
    final fromBase = relatedFiles[base] ?? const [];
    if (fromBase.isNotEmpty) {
      final preferred = fromBase.where((abs) {
        final seg = p.separator + base + p.separator;
        return abs.contains(seg) || p.dirname(abs).endsWith(p.separator + base);
      }).toList();
      return preferred.isNotEmpty ? preferred : fromBase;
    }
    return relatedFiles[p.basename(filename)] ?? const [];
  }

  LibrarySnapshot copyWith({
    Set<String>? exactFiles,
    Set<String>? baseNames,
    Map<String, List<String>>? relatedFiles,
    DateTime? timestamp,
  }) {
    return LibrarySnapshot(
      libraryDir: libraryDir,
      exactFiles: exactFiles ?? this.exactFiles,
      baseNames: baseNames ?? this.baseNames,
      relatedFiles: relatedFiles ?? this.relatedFiles,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}
