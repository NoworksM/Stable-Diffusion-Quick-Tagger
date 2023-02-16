import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/utils/tag_utils.dart' as tutils;

class SaveTagsAction extends Action<SaveTagsIntent> {
  final TaggedImage image;
  final List<String> tags;
  final Function() onComplete;

  SaveTagsAction(this.image, this.tags, this.onComplete);

  @override
  Future<void> invoke(SaveTagsIntent intent) async {
    for (final tagFile in image.tagFiles) {
      await tutils.save(tagFile, tags);
      tagFile.tags.clear();
      tagFile.tags.addAll(tags);
    }

    onComplete();
  }
}

class SaveTagsIntent extends Intent {
}