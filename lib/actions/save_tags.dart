import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/services/gallery_service.dart';

class SaveTagsAction extends Action<SaveTagsIntent> {
  final TaggedImage image;
  final IGalleryService _galleryService;

  SaveTagsAction(this.image)
    : _galleryService = getIt.get<IGalleryService>();

  @override
  Future<void> invoke(SaveTagsIntent intent) async {
    _galleryService.saveImagePendingChanges(image);
  }
}

class SaveTagsIntent extends Intent {
}