import 'package:quick_tagger/utils/functional_utils.dart';

class Trie {
  final bool radix;
  late String _value;
  late List<Trie> _children;

  Trie(List<String> words, {bool radix = false}) : this.fromWords('', words, radix: radix);

  _radixCompress() {
    if (_children.length == 1) {
      _value += _children[0]._value;
      _children = _children[0]._children;

      for (final child in _children) {
        child._radixCompress();
      }
    }
  }

  /// Create a Trie from a list of words
  Trie.fromWords(this._value, List<String> words, {this.radix = false, bool sorted = false}) : _children = <Trie>[] {
    if (words.isEmpty) {
      return;
    }

    if (!sorted) {
      words.sort();
    }

    String lastChar;
    if (words[0].isEmpty) {
      lastChar = '';
    } else {
      lastChar = words[0][0];
    }
    var subWords = <String>[];

    for (var idx = 0; idx < words.length; idx++) {
      if (words[idx].isEmpty) {
        continue;
      }
      if (lastChar == words[idx][0]) {
        if (words[idx].isNotEmpty) {
          subWords.add(words[idx].substring(1));
        }
      } else {
        _children.add(Trie.fromWords(lastChar, subWords, radix: radix, sorted: true));
        subWords.clear();

        if (words[idx].isNotEmpty) {
          subWords.add(words[idx].substring(1));
        }

        lastChar = words[idx][0];
      }
    }

    if (subWords.isNotEmpty) {
      _children.add(Trie.fromWords(lastChar, subWords, radix: radix, sorted: true));
      subWords.clear();
    }

    if (radix) {
      _radixCompress();
    }
  }

  /// Create an empty/root Trie
  Trie.empty({this.radix = false})
      : _value = '',
        _children = <Trie>[];

  /// Create a Trie from entries/children for the new node
  Trie.fromEntries(this._value, this._children, {this.radix = false}) {
    if (radix) {
      _radixCompress();
    }
  }

  /// Create a Trie from a single word/trailing word
  Trie.single(String value, {this.radix = false}) {
    if (radix || value.isEmpty) {
      _value = value;
      _children = <Trie>[];
    } else {
      _value = value[0];
      _children = <Trie>[Trie.single(value.substring(1), radix: radix)];
    }

    if (radix) {
      _radixCompress();
    }
  }

  get value => _value;

  Iterable<String> findSuggestions(String term, {String previous = ''}) sync* {
    if (term.isEmpty) {
      yield* buildTerms(previous.substring(0, previous.length - 1));
      return;
    }

    for (final child in _children) {
      if (child._value.isEmpty) {
        continue;
      }

      if (term.startsWith(child._value)) {
        final newTerm = term.substring(child._value.length);
        final newPrevious = previous + term.substring(0, child._value.length);

        yield* child.findSuggestions(newTerm, previous: newPrevious);
        return;
      }
    }
  }

  Iterable<String> buildTerms(String root) sync* {
    if (_value.isEmpty || _children.isEmpty) {
      yield root + _value;
    }

    for (final child in _children) {
      final newRoot = root + _value;

      yield* child.buildTerms(newRoot);
    }
  }

  /// Undo radix compaction on this trie and all it's children
  // ignore: unused_element
  _radixDecompress({bool recurse = false}) {
    if (recurse) {
      for (final child in _children) {
        child._radixDecompress();
      }
    }

    while (_value.length > 1) {
      final segment = _value.substring(_value.length - 1, _value.length);

      _children = [Trie.fromEntries(segment, _children, radix: radix)];

      _value = _value.substring(0, _value.length - 1);
    }
  }

  @override
  String toString() {
    return 'Trie{_value: $_value, radix: $radix, children: ${_children.length}';
  }

  Trie clone() {
    return Trie.fromEntries(_value, _children.map((t) => t.clone()).toList(), radix: radix);
  }

  Trie cloneWith(Iterable<String> words) {
    final cloned = clone();

    cloned.addAll(words);

    return cloned;
  }

  add(String value) {
    _add(value);
    if (radix) {
      _radixCompress();
    }
  }

  _add(String value) {
    // Value already exists
    if (value == _value) {
      return;
    }

    if (_children.isEmpty) {
      _children.add(Trie.single(value.substring(_value.length), radix: radix));
      return;
    }

    value = value.substring(_value.length);

    int mdx = 0;
    String mid = '';
    int comparison = 0;
    bool found = false;
    for (int ldx = 0, udx = _children.length; ldx != udx;) {
      mdx = (ldx + udx) ~/ 2;
      mid = _children[mdx]._value;

      comparison = value.substring(0, mid.length).compareTo(mid);

      if (comparison == 0) {
        found = true;
        break;
      }
      if (comparison < 0) {
        udx = mdx - 1;
      }
      if (comparison > 0) {
        ldx = mdx + 1;
      }
    }

    if (found) {
      _children[mdx].add(value);
    } else {
      _children.insert(comparison > 0 ? mdx + 1 : mdx, Trie.single(value, radix: radix));
    }
  }

  addAll(Iterable<String> values) {
    final list = values.toList(growable: false);
    list.sort();
    _addAll(list);
  }

  _addAll(List<String> words) {
    final newChildren = <MapEntry<int?, String>>[];

    int wordIndex = 0;
    for (int idx = 0; idx < _children.length; idx++) {
      if (wordIndex == words.length) {
        break;
      }

      final child = _children[idx];

      final grandChildren = <String>[];

      while (wordIndex < words.length && !words[wordIndex].startsWith(child._value)) {
        newChildren.add(MapEntry(idx, words[wordIndex]));
        wordIndex++;
      }

      while (wordIndex < words.length && words[wordIndex].startsWith(child._value)) {
        grandChildren.add(words[wordIndex].substring(child._value.length));
        wordIndex++;
      }

      child._addAll(grandChildren);
    }

    while (wordIndex < words.length) {
      newChildren.add(MapEntry(null, words[wordIndex]));
      wordIndex++;
    }

    if (newChildren.isEmpty) {
      return;
    }

    int inserted = 0;
    for (final grouping in newChildren.groupSortedBy((v) => MapEntry<int?, String>(v.key, v.value.isNotEmpty ? v.value.substring(0, 1) : ''))) {
      final words = grouping.items.map((p) => p.value).map((w) => w.isNotEmpty ? w.substring(1) : '').toList();

      if (grouping.key.key == null) {
        _children.add(Trie.fromWords(grouping.key.value, words));
      } else {
        _children.insert(inserted, Trie.fromWords(grouping.key.value, words));
        inserted++;
      }
    }
  }
}
