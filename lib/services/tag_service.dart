import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data_structures/trie.dart';

const suggestionLimit = 10;

abstract class ITagService {
  Iterable<String> suggestedDatasetTags(String term);

  Iterable<String> suggestedGlobalTags(String term);

  void replaceDatasetTags(List<String> tags);

  void replaceGlobalTags(List<String> tags);

  void replaceTagCounts(List<TagCount> tagCounts);

  Stream<List<TagCount>> get tagCountStream;
}

@Singleton(as: ITagService)
class TagService implements ITagService {
  final StreamController<List<TagCount>> _tagCountStreamController = StreamController<List<TagCount>>();
  late final Stream<List<TagCount>> _tagCountStream = _tagCountStreamController.stream.asBroadcastStream();
  Trie globalTrie;
  Trie datasetTrie;

  TagService()
    : globalTrie = Trie.empty(),
      datasetTrie = Trie.empty();

  @override
  Iterable<String> suggestedDatasetTags(String term) {
    if (term.isEmpty) {
      return <String>[];
    }

    return datasetTrie.findSuggestions(term).take(suggestionLimit);
  }

  @override
  Iterable<String> suggestedGlobalTags(String term) {
    if (term.isEmpty) {
      return <String>[];
    }

    return globalTrie.findSuggestions(term).take(suggestionLimit);
  }

  @override
  void replaceDatasetTags(List<String> tags) {
    datasetTrie = globalTrie.cloneWith(tags);
  }

  @override
  void replaceGlobalTags(List<String> tags) {
    globalTrie = Trie(tags);
  }

  @override
  Stream<List<TagCount>> get tagCountStream => _tagCountStream;

  @override
  void replaceTagCounts(List<TagCount> tagCounts) {
    _tagCountStreamController.add(tagCounts);
  }
}