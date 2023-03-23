import 'dart:collection';

import 'package:quick_tagger/data/tagged_image.dart';

class DirectoryInfo {
  final String path;
  final DirectoryType type;
  final List<DirectoryInfo> _subDirectories;
  final int? repeats;
  final List<TaggedImage> _images;
  final String name;

  DirectoryInfo(this.path, this.name, this.type, this._subDirectories, this._images, {this.repeats});

  DirectoryInfo.single(this.path, this.name, this.type, this._images, {this.repeats})
    : _subDirectories = List.empty();

  DirectoryInfo.imageLess(this.path, this.name, this.type, this._subDirectories, {this.repeats})
    : _images = List.empty();

  DirectoryInfo.withChildren(DirectoryInfo info, this._subDirectories, this._images)
    : path = info.path,
      type = info.type,
      repeats = info.repeats,
      name = info.name;

  UnmodifiableListView<TaggedImage> get images => UnmodifiableListView(_images);

  UnmodifiableListView<DirectoryInfo> get subDirectories => UnmodifiableListView(_subDirectories);
}

enum DirectoryType {
  normal,
  loraRepeat,
  lora,
  unknown
}