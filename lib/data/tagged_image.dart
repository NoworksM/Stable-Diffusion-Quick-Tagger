import 'dart:collection';

import 'package:crypto/crypto.dart';
import 'package:quick_tagger/data/file_tag_info.dart';
import 'package:quick_tagger/data/tagfile_type.dart';

class TaggedImage {
  final String path;
  final HashSet<String> tags;
  final List<TagFile> tagFiles;
  final Digest digest;

  TaggedImage(this.path, this.tags, this.tagFiles, this.digest);

  TaggedImage.noTags(this.path, this.digest)
      : tags = HashSet<String>.identity(),
        tagFiles = List.empty(growable: true);

  TaggedImage.file(this.path, FileTagInfo fileTagInfo, this.digest)
      : tags = fileTagInfo.tags,
        tagFiles = fileTagInfo.files;

  TaggedImage.withDigest(TaggedImage source, this.digest)
      : path = source.path,
        tags = source.tags,
        tagFiles = source.tagFiles;
}
