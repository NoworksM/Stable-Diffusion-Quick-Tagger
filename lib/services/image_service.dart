import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/data/cached_image.dart';

abstract class IImageService {
  /// Asynchronously load images in
  Future<CachedImage> loadImage(TaggedImage image);

  /// Clear the cache data
  void clearCache();
}

@Singleton(as: IImageService)
class ImageService implements IImageService {
  final HashMap<String, CachedImage> _cachedImages = HashMap();

  @override
  Future<CachedImage> loadImage(TaggedImage image) async {
    if (_cachedImages.containsKey(image.path)) {
      return _cachedImages[image.path]!;
    }

    final file = File(image.path);
    final bytes = await file.readAsBytes();
    final decoded = await decodeImageFromList(bytes);

    final width = decoded.width;
    final height = decoded.height;

    return _cachedImages[image.path] = CachedImage(MemoryImage(bytes), width, height);
  }

  @override
  void clearCache() {
    for (final cached in _cachedImages.values) {
      cached.image.evict();
    }
    _cachedImages.clear();
  }

  void dispose() {
    clearCache();
  }
}