import 'package:injectable/injectable.dart';
import 'package:quick_tagger/data_structures/trie.dart';

abstract class ITagService {
  Iterable<String> suggestedTags(String term);

  void replaceTags(List<String> tags);
}

@Singleton(as: ITagService)
class TagService implements ITagService {
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
}