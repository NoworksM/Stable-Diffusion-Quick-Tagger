import 'package:flutter_test/flutter_test.dart';
import 'package:quick_tagger/data_structures/trie.dart';

void main() {
  late Trie sampleTrie;

  setUp(() {
    sampleTrie = Trie.fromWords('', ['o-ring', 'o-ring bikini', 'o-ring donut']);
  });

  group('construction', () {
    test('creates proper trie', () {
      final suggestions = sampleTrie.findSuggestions('o-ring').toList(growable: false);

      expect(suggestions, equals(['o-ring', 'o-ring bikini', 'o-ring donut']));
    });
  });

  group('add', () {
    test('add adds new element', () {
      sampleTrie.add('o-ring thing');

      final suggestions = sampleTrie.findSuggestions('o-ring').toList(growable: false);;

      expect(suggestions, equals(['o-ring', 'o-ring bikini', 'o-ring donut', 'o-ring thing']));
    });

    test('add doesn\'t add duplicates', () {
      sampleTrie.add('o-ring');

      final suggestions = sampleTrie.findSuggestions('o-ring').toList(growable: false);;

      expect(suggestions, equals(['o-ring', 'o-ring bikini', 'o-ring donut']));
    });

    test('add works with radix trees', () {

    });
  });

  group('addAll', () {
    test('addAll adds new elements', () {
      sampleTrie.addAll(['o-ring thing', 'o-ring thing2']);

      final suggestions = sampleTrie.findSuggestions('o-ring').toList(growable: false);;

      expect(suggestions, containsAll(['o-ring', 'o-ring bikini', 'o-ring donut', 'o-ring thing', 'o-ring thing2']));
    });

    test('addLL doesn\'t add duplicates', () {
      sampleTrie.addAll(['o-ring thing', 'o-ring thing2', 'o-ring']);

      final suggestions = sampleTrie.findSuggestions('o-ring').toList(growable: false);;

      expect(suggestions, containsAll(['o-ring', 'o-ring bikini', 'o-ring donut', 'o-ring thing', 'o-ring thing2']));
    });
  });
}