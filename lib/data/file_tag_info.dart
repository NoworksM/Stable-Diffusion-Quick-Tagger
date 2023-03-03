import 'dart:collection';

import 'package:quick_tagger/data/tagfile_type.dart';

class FileTagInfo {
  final HashSet<String> tags;
  final List<TagFile> files;

  FileTagInfo(this.tags, this.files);
}
