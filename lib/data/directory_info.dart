import 'dart:collection';

import 'package:quick_tagger/data/tagged_image.dart';

class DirectoryInfo {
  final String path;
  final DirectoryType type;
  final List<DirectoryInfo> _subDirectories;
  final int? repeats;
  final List<TaggedImage> _images;

  DirectoryInfo(this.path, this.type, this._subDirectories, this._images, {this.repeats});

  DirectoryInfo.single(this.path, this.type, this._images, {this.repeats})
    : _subDirectories = List.empty();

  DirectoryInfo.imageLess(this.path, this.type, this._subDirectories, {this.repeats})
    : _images = List.empty();

  UnmodifiableListView<TaggedImage> get images => UnmodifiableListView(_images);

  UnmodifiableListView<DirectoryInfo> get subDirectories => UnmodifiableListView(_subDirectories);
}

enum DirectoryType {
  normal,
  loraRepeat,
  lora,
  unknown
}