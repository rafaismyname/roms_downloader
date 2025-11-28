import 'package:rapidfuzz/rapidfuzz.dart';

String normalizeTitle(String name) {
  return RegExp(r'[_\W]+')
      .allMatches(name.toLowerCase())
      .fold<StringBuffer>(StringBuffer(), (b, m) {
        b
          ..write(name.substring(b.length, m.start).replaceAll('_', ' '))
          ..write(' ');
        return b;
      })
      .toString()
      .trim();
}

Map<String, List<String>> buildTokenIndex(Iterable<String> names) {
  final Map<String, List<String>> index = {};
  for (final name in names) {
    for (final token in name.split(' ')) {
      if (token.length > 1) {
        index.putIfAbsent(token, () => []).add(name);
      }
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

  final numericRegExp = RegExp(r'^\d+$');
  final mixedTokenRegExp = RegExp(r'^[a-z]+\d+$');
  final titleTokens = normalizedTitle.split(' ').where((token) {
    return token.length > 1;
  }).toList();

  final numericTokens = titleTokens.where((t) => numericRegExp.hasMatch(t)).toList();
  final meaningfulTokens = titleTokens.where((t) => !numericRegExp.hasMatch(t)).toSet();

  Set<String>? candidateNames;

  if (numericTokens.isNotEmpty) {
    for (final nt in numericTokens) {
      final names = tokenIndex[nt];
      if (names == null) {
        candidateNames = {};
        break;
      }
      final nameSet = names.toSet();
      candidateNames = candidateNames == null ? nameSet : candidateNames.intersection(nameSet);
      if (candidateNames.isEmpty) break;
    }
    candidateNames ??= {};
  }

  if (meaningfulTokens.isNotEmpty) {
    final threshold = (meaningfulTokens.length * 0.7).ceil();
    final Map<String, int> counts = {};
    
    for (final token in meaningfulTokens) {
      final names = tokenIndex[token];
      if (names != null) {
        for (final name in names) {
          if (candidateNames == null || candidateNames.contains(name)) {
            counts[name] = (counts[name] ?? 0) + 1;
          }
        }
      }
    }

    final passed = <String>{};
    counts.forEach((name, count) {
      if (count >= threshold) {
        passed.add(name);
      }
    });

    if (candidateNames == null) {
      candidateNames = passed;
    } else {
      candidateNames = candidateNames.intersection(passed);
    }
  } else {
    candidateNames ??= {};
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

  if (candidateNames.isEmpty) return null;

  final Iterable<String> searchSpace = candidateNames;

  String? bestMatchName;
  int highestScore = 0;
  for (final candidate in searchSpace) {
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
