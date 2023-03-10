import 'dart:collection';

import 'package:quick_tagger/data/edit.dart';
import 'package:quick_tagger/data/tagged_image.dart';

/// Record of a single change that was performed
class Change {
  final UnmodifiableSetView<TaggedImage> images;
  final Edit edit;
  final DateTime createdAt;

  Change(this.images, this.edit, this.createdAt);

  Change.now(this.images, this.edit)
    : createdAt = DateTime.now();
}