import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data_structures/trie.dart';

abstract class ITagService {
  Iterable<String> suggestedTags(String term);

  void replaceTags(List<String> tags);

  void replaceTagCounts(List<TagCount> tagCounts);

  Stream<List<TagCount>> get tagCountStream;
}

@Singleton(as: ITagService)
class TagService implements ITagService {
  final StreamController<List<TagCount>> _tagCountStreamController = StreamController<List<TagCount>>();
  late final Stream<List<TagCount>> _tagCountStream = _tagCountStreamController.stream.asBroadcastStream();
  Trie trie;

  TagService()
    : trie = Trie.empty();

  @override
  Iterable<String> suggestedTags(String term) {
    if (term.isEmpty) {
      return <String>[];
    }

    return trie.findSuggestions(term).take(5);
  }

  @override
  void replaceTags(List<String> tags) {
    trie = Trie(tags);
  }

  @override
  Stream<List<TagCount>> get tagCountStream => _tagCountStream;

  @override
  void replaceTagCounts(List<TagCount> tagCounts) {
    _tagCountStreamController.add(tagCounts);
  }
}