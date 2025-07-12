import 'package:rapidfuzz/rapidfuzz.dart';

String normalizeTitle(String name) {
  return name.toLowerCase().replaceAll('_', ' ').replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

Map<String, List<String>> buildTokenIndex(Iterable<String> names) {
  final Map<String, List<String>> index = {};
  for (final name in names) {
    for (final token in name.split(' ')) {
      if (!(RegExp(r'^\d+$').hasMatch(token) || token.length > 2 || RegExp(r'^[a-z]+\d+$').hasMatch(token))) {
        continue;
      }
      index.putIfAbsent(token, () => []).add(name);
    }
  }
  return index;
}

String? matchTitle({
  required String titleToMatch,
  required Map<String, String> candidates,
  required Map<String, List<String>> tokenIndex,
}) {
  final normalizedTitle = normalizeTitle(titleToMatch);

  if (candidates.containsKey(normalizedTitle)) {
    return candidates[normalizedTitle];
  }

  final numericRegExp = RegExp(r'^\d{2,}$');
  final mixedTokenRegExp = RegExp(r'^[a-z]+\d+$');
  final titleTokens = normalizedTitle.split(' ').where((token) {
    if (token.isEmpty) return false;
    return numericRegExp.hasMatch(token) || token.length > 2 || mixedTokenRegExp.hasMatch(token);
  }).toList();

  final numericTokens = titleTokens.where((t) => numericRegExp.hasMatch(t)).toList();

  Set<String> candidateNames = {};

  if (numericTokens.isNotEmpty) {
    Set<String>? intersection;
    for (final nt in numericTokens) {
      final names = tokenIndex[nt];
      if (names == null) {
        intersection = <String>{};
        break;
      }
      final nameSet = names.toSet();
      intersection = intersection == null ? nameSet : intersection.intersection(nameSet);
      if (intersection.isEmpty) break;
    }
    candidateNames = intersection ?? <String>{};
  }

  if (candidateNames.isEmpty && numericTokens.isEmpty) {
    for (final token in titleTokens.where((t) => !numericRegExp.hasMatch(t))) {
      final names = tokenIndex[token];
      if (names != null) candidateNames.addAll(names);
    }
  }

  if (candidateNames.isEmpty) {
    return null;
  }

  final mixedTokens = titleTokens.where((t) => mixedTokenRegExp.hasMatch(t)).toList();

  final hasMixedTokensInGame = mixedTokens.isNotEmpty;
  candidateNames = candidateNames.where((name) {
    if (!hasMixedTokensInGame && RegExp(r'\b[a-z]+\d+\b').hasMatch(name)) {
      return false;
    }
    return true;
  }).toSet();

  // Generic meaningful-token Jaccard style filter.
  if (candidateNames.isNotEmpty) {
    final Set<String> meaningfulGameTokens = {
      for (final t in titleTokens)
        if (!numericRegExp.hasMatch(t) && t.length > 2) t
    };

    if (meaningfulGameTokens.isNotEmpty) {
      candidateNames = candidateNames.where((name) {
        final tokens = name.split(' ').where((tok) => tok.length > 2 && !numericRegExp.hasMatch(tok)).toSet();
        final int common = tokens.intersection(meaningfulGameTokens).length;
        if (meaningfulGameTokens.length <= 4) {
          // For shorter titles, require all tokens to appear.
          return common == meaningfulGameTokens.length;
        }
        // For longer titles, allow at most one missing.
        if (common < meaningfulGameTokens.length - 1) return false;
        // Ensure candidate doesn't introduce many unrelated tokens.
        if (tokens.length > meaningfulGameTokens.length + 2) return false;
        return true;
      }).toSet();
    }
  }

  if (candidateNames.isEmpty) return null;

  final Iterable<String> searchSpace = candidateNames;
  final Set<String> nonNumericTokens = {
    for (final t in titleTokens)
      if (!numericRegExp.hasMatch(t)) t
  };

  String? bestMatchName;
  int highestScore = 0;
  for (final candidate in searchSpace) {
    if (nonNumericTokens.isNotEmpty && !nonNumericTokens.any((t) => candidate.contains(t))) {
      continue;
    }

    final score = tokenSetRatio(normalizedTitle, candidate).toInt();
    if (score > highestScore && score >= 90) {
      highestScore = score;
      bestMatchName = candidate;
    }
  }
  if (bestMatchName != null) {
    return candidates[bestMatchName];
  }
  return null;
}
