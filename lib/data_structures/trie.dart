class Trie {
  final bool radix;
  String _value;
  List<Trie> _children;

  Trie(List<String> words, {bool radix = false}) : this.fromWords("", words, radix: radix);

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
  Trie.fromWords(this._value, List<String> words, {this.radix = false})
    : _children = <Trie>[] {
    if (words.isEmpty) {
      return;
    }

    words.sort();

    var lastChar = words[0][0];
    var subWords = <String>[];

    if (words.length == 1 && words[0].length == 1) {
      _children.add(Trie.fromEntries(words[0], []));
    } else {
      for (var idx = 0; idx < words.length; idx++) {
        if (lastChar == words[idx][0]) {
          if (words[idx].length > 1) {
            subWords.add(words[idx].substring(1));
          }
        } else {
          _children.add(Trie.fromWords(lastChar, subWords, radix: radix));
          subWords.clear();

          if (words[idx].length > 1) {
            subWords.add(words[idx].substring(1));
          }

          lastChar = words[idx][0];
        }
      }

      if (subWords.isNotEmpty) {
        _children.add(Trie.fromWords(lastChar, subWords, radix: radix));
        subWords.clear();
      }

      if (radix) {
        _radixCompress();
      }
    }
  }

  /// Create an empty/root Trie
  Trie.empty({this.radix = false})
    : _value = "",
      _children = <Trie>[];

  /// Create a Trie from entries/children for the new node
  Trie.fromEntries(this._value, this._children, {this.radix = false});

  /// Create a Trie from a single word/trailing word
  /// TODO: Finish implementing Trie.single
  // Trie.single(String value, {this.radix = false}) {
  //   if (radix) {
  //     _value = value;
  //     _children = <Trie>[];
  //   } else {
  //
  //     for ()
  //   }
  // }

  get value => _value;
  
  Iterable<String> findSuggestions(String term, {String previous = ""}) sync* {
    if (term.isEmpty) {
      yield* buildTerms(previous.substring(0, previous.length - 1));
      return;
    }

    for (final child in _children) {
      if (term.startsWith(child._value)) {
        final newTerm = term.substring(child._value.length);
        final newPrevious = previous + term.substring(0, child._value.length);

        yield* child.findSuggestions(newTerm, previous: newPrevious);
        return;
      }
    }
  }

  Iterable<String> buildTerms(String root) sync* {
    if (_children.isEmpty) {
      yield root + _value;
    }

    for (final child in _children) {
      final newRoot = root + _value;

      yield* child.buildTerms(newRoot);
    }
  }

  /// Undo radix compaction on this trie and all it's children
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
    return 'Trie{_value: $_value, radix: $radix}';
  }

  /// TODO: Finish implementing add and addAll
  // add(String value) {
  //   // Value already exists
  //   if (value == _value) {
  //     return;
  //   }
  //
  //   if (_children.isEmpty) {
  //       _children.add(Trie.single(value.substring(_value.length), radix));
  //       return;
  //   }
  //
  //   for (final child in _children) {
  //
  //   }
  // }
  //
  // _add(String value, String previous)
  //
  // addAll(Iterable<String> values) {
  //   throw UnimplementedError();
  // }
}