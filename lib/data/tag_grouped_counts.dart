import 'package:quick_tagger/data/tag_count.dart';

class TagGroupedCounts {
  List<TagCount> added;
  List<TagCount> removed;

  TagGroupedCounts(this.added, this.removed);
}