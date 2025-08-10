import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:roms_downloader/models/library_snapshot_model.dart';

final librarySnapshotProvider = StateNotifierProvider.family<LibrarySnapshotNotifier, Map<String, LibrarySnapshot>, String>(
  (ref, libraryDir) => LibrarySnapshotNotifier(libraryDir),
);

class LibrarySnapshotNotifier extends StateNotifier<Map<String, LibrarySnapshot>> {
  final String _libraryDir;
  LibrarySnapshotNotifier(this._libraryDir) : super(const {});

  bool _refreshing = false;
  Completer<void>? _refreshingCompleter;
  Future<void> refresh() async {
    if (_refreshing) {
      // someone else is refreshing – wait for them
      await _refreshingCompleter?.future;
      return;
    }
    _refreshing = true;
    _refreshingCompleter = Completer<void>();

    final dir = Directory(_libraryDir);
    if (!await dir.exists()) {
      state = {
        ...state,
        _libraryDir: LibrarySnapshot(
          libraryDir: _libraryDir,
          exactFiles: {},
          baseNames: {},
          relatedFiles: {},
          timestamp: DateTime.now(),
        ),
      };
      _refreshing = false;
      _refreshingCompleter?.complete();
      _refreshingCompleter = null;
      return;
    }

    Map<String, dynamic> raw;
    try {
      raw = await compute(_scanLibraryDir, _libraryDir);
    } catch (e) {
      debugPrint('Isolate scan failed, fallback inline: $e');
      // Fallback to inline (original logic) if compute fails
      raw = await _scanLibraryDir(_libraryDir);
    }

    final exact = Set<String>.from(raw['exact'] as List);
    final bases = Set<String>.from(raw['bases'] as List);
    final related = (raw['related'] as Map).map<String, List<String>>(
      (k, v) => MapEntry(k as String, List<String>.from(v as List)),
    );

    state = {
      ...state,
      _libraryDir: LibrarySnapshot(
        libraryDir: _libraryDir,
        exactFiles: exact,
        baseNames: bases,
        relatedFiles: related,
        timestamp: DateTime.now(),
      ),
    };
    _refreshing = false;
    _refreshingCompleter?.complete();
    _refreshingCompleter = null;
  }

  Future<Map<String, dynamic>> _scanLibraryDir(String libraryDir) async {
    final dir = Directory(libraryDir);
    if (!dir.existsSync()) {
      return {
        'exact': <String>[],
        'bases': <String>[],
        'related': <String, List<String>>{},
      };
    }

    final exact = <String>{};
    final bases = <String>{};
    final related = <String, List<String>>{};
    String abs(String name) => p.join(libraryDir, name);

    try {
      for (final e in dir.listSync()) {
        final base = p.basename(e.path);
        final baseNoExt = p.basenameWithoutExtension(base);

        if (e is File) {
          exact.add(base);
          bases.add(baseNoExt);
          related[base] = [abs(base)];
          related.putIfAbsent(baseNoExt, () => <String>[]).add(abs(base));
        } else if (e is Directory) {
          bases.add(base);
          bases.add(baseNoExt);

          final files = <String>[];
          try {
            for (final sub in e.listSync()) {
              if (sub is File) files.add(sub.path);
            }
          } catch (_) {}

          if (files.isNotEmpty) {
            related[base] = [...files];
            related[baseNoExt] = [
              ...files,
              ...(related[baseNoExt] ?? const []),
            ];
          } else {
            related.putIfAbsent(base, () => <String>[]);
            related.putIfAbsent(baseNoExt, () => <String>[]);
          }
        }
      }
    } catch (_) {}

    return {
      'exact': exact.toList(),
      'bases': bases.toList(),
      'related': related,
    };
  }

  Future<LibrarySnapshot> _ensure() async {
    var snap = state[_libraryDir];
    if (snap != null) return snap;
    await refresh();
    snap = state[_libraryDir];

    if (snap == null) {
      return LibrarySnapshot(
        libraryDir: _libraryDir,
        exactFiles: {},
        baseNames: {},
        relatedFiles: {},
        timestamp: DateTime.now(),
      );
    }

    return snap;
  }

  Future<LibraryPresence> getStatus(String filename) async {
    final snap = await _ensure();
    return snap.statusFor(filename);
  }

  Future<Map<String, LibraryPresence>> getStatuses(Iterable<String> filenames) async {
    final snap = await _ensure();
    return snap.statusesFor(filenames);
  }

  Future<Map<String, LibraryPresence>> getAllStatuses() async {
    final snap = await _ensure();
    return snap.allStatuses();
  }

  Future<List<String>> getRelatedFiles(String filename) async {
    final snap = await _ensure();
    return snap.relatedFilesFor(filename);
  }

  // Incremental updates

  void markFileAdded(String filename) {
    final base = p.basename(filename);
    final baseNoExt = p.basenameWithoutExtension(base);
    final snap = state[_libraryDir] ??
        LibrarySnapshot(
          libraryDir: _libraryDir,
          exactFiles: {},
          baseNames: {},
          relatedFiles: {},
          timestamp: DateTime.now(),
        );

    final exact = {...snap.exactFiles}..add(base);
    final bases = {...snap.baseNames}..add(baseNoExt);
    final related = _cloneRelated(snap.relatedFiles);

    final absPath = p.join(_libraryDir, base);
    related[base] = [absPath]; // exact filename -> itself
    related.putIfAbsent(baseNoExt, () => <String>[]).add(absPath);

    state = {
      ...state,
      _libraryDir: snap.copyWith(exactFiles: exact, baseNames: bases, relatedFiles: related),
    };
  }

  void markFileRemoved(String filename) {
    final base = p.basename(filename);
    final baseNoExt = p.basenameWithoutExtension(base);
    final snap = state[_libraryDir];
    if (snap == null) return;

    final exact = {...snap.exactFiles}..remove(base);
    final bases = {...snap.baseNames};
    final related = _cloneRelated(snap.relatedFiles);

    // Remove exact mapping
    related.remove(base);

    // Remove from base mapping
    final absPath = p.join(_libraryDir, base);
    final list = related[baseNoExt];
    if (list != null) {
      list.removeWhere((pth) => p.normalize(pth) == p.normalize(absPath));
      if (list.isEmpty) related.remove(baseNoExt);
    }

    // Drop base if no variants (files) left and no extracted dir present
    final stillHasVariant = exact.any((f) => p.basenameWithoutExtension(f) == baseNoExt);
    if (!stillHasVariant) {
      // If there’s no dir content mapped either, remove base
      final hasDirContent = (related[baseNoExt] ?? const []).any((pth) {
        final dirName = p.basename(p.dirname(pth));
        return dirName == baseNoExt;
      });
      if (!hasDirContent) bases.remove(baseNoExt);
    }

    state = {
      ...state,
      _libraryDir: snap.copyWith(exactFiles: exact, baseNames: bases, relatedFiles: related),
    };
  }

  void markDirAdded(String dirName) {
    final base = p.basename(dirName);
    final baseNoExt = p.basenameWithoutExtension(base);
    final snap = state[_libraryDir] ??
        LibrarySnapshot(
          libraryDir: _libraryDir,
          exactFiles: {},
          baseNames: {},
          relatedFiles: {},
          timestamp: DateTime.now(),
        );

    final bases = {...snap.baseNames}
      ..add(base)
      ..add(baseNoExt);
    final related = _cloneRelated(snap.relatedFiles);

    final dirPath = p.join(_libraryDir, base);
    final files = <String>[];
    try {
      final d = Directory(dirPath);
      if (d.existsSync()) {
        for (final sub in d.listSync()) {
          if (sub is File) files.add(sub.path);
        }
      }
    } catch (_) {}

    related[base] = [...files];
    related[baseNoExt] = [
      ...files,
      ...(related[baseNoExt] ?? const []),
    ];

    state = {
      ...state,
      _libraryDir: snap.copyWith(baseNames: bases, relatedFiles: related),
    };
  }

  void markDirRemoved(String dirName) {
    final base = p.basename(dirName);
    final baseNoExt = p.basenameWithoutExtension(base);
    final snap = state[_libraryDir];
    if (snap == null) return;

    final bases = {...snap.baseNames}
      ..remove(base)
      ..remove(baseNoExt);
    final related = _cloneRelated(snap.relatedFiles)
      ..remove(base)
      ..remove(baseNoExt);

    state = {
      ...state,
      _libraryDir: snap.copyWith(baseNames: bases, relatedFiles: related),
    };
  }

  Map<String, List<String>> _cloneRelated(Map<String, List<String>> src) {
    final out = <String, List<String>>{};
    for (final e in src.entries) {
      out[e.key] = [...e.value];
    }
    return out;
  }
}
