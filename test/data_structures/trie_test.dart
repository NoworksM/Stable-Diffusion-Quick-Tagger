import 'package:flutter_test/flutter_test.dart';
import 'package:quick_tagger/data_structures/trie.dart';

final oRingTrie = Trie.fromWords('', ['o-ring', 'o-ring bikini', 'o-ring donut']);

void main() {
  group('construction', () {
    test('creates proper trie', () {
      final trie = Trie.fromWords('', ['o-ring', 'o-ring donut', 'o-ring bikini']);

      final suggestions = trie.findSuggestions('o-ring').toList(growable: false);

      expect(suggestions, equals(['o-ring', 'o-ring bikini', 'o-ring donut']));
    });
  });

  group('access', () {
    test('findSuggestions to grab', () {

    });
  });
}