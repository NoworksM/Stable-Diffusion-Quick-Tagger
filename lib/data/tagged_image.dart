import 'dart:collection';

import 'package:quick_tagger/data/file_tag_info.dart';
import 'package:quick_tagger/data/tagfile_type.dart';

class TaggedImage {
  final String path;
  final HashSet<String> tags;
  final List<TagFile> tagFiles;

  TaggedImage(this.path, this.tags, this.tagFiles);

  TaggedImage.noTags(this.path)
      : tags = HashSet<String>.identity(),
        tagFiles = List.empty();

  TaggedImage.file(this.path, FileTagInfo fileTagInfo)
    : tags = fileTagInfo.tags,
      tagFiles = fileTagInfo.files;
}
