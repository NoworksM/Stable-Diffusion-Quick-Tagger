import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/data/cached_image.dart';
import 'package:quick_tagger/data_structures/tuple.dart';

abstract class IImageService {
  Future<void> loadImages(Stream<TaggedImage> images);

  /// Asynchronously load images in
  Future<CachedImage> loadImage(String image);

  Future<Digest> hashImage(String path);

  /// Clear the cache data
  void clearCache();
}

@Singleton(as: IImageService)
class ImageService implements IImageService {
  final HashMap<String, Pair<CachedImage, Digest>> _cachedImages = HashMap();
  final HashMap<String, Future<Pair<CachedImage, Digest>>> _loadingImages = HashMap();

  @override
  Future<CachedImage> loadImage(String path) async {
    if (_cachedImages.containsKey(path)) {
      return _cachedImages[path]!.first;
    }

    if (_loadingImages.containsKey(path)) {
      return (await _loadingImages[path]!).first;
    }

    final future = _loadImage(path);

    _loadingImages[path] = future;

    final loaded = await future;

    _loadingImages.remove(path);

    return loaded.first;
  }

  Future<Pair<CachedImage, Digest>> _loadImage(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final decoded = await decodeImageFromList(bytes);

    final width = decoded.width;
    final height = decoded.height;

    final digest = md5.convert(bytes);

    return _cachedImages[path] = Pair(CachedImage(MemoryImage(bytes), width, height), digest);
  }

  @override
  void clearCache() {
    for (final cached in _cachedImages.values) {
      cached.first.image.evict();
    }
    _cachedImages.clear();
  }

  void dispose() {
    clearCache();
  }

  @override
  Future<void> loadImages(Stream<TaggedImage> images) async {
    await for (final image in images) {
      await loadImage(image.path);
    }
  }

  @override
  Future<Digest> hashImage(String path) async {
    if (_cachedImages.containsKey(path)) {
      return _cachedImages[path]!.second;
    }

    if (_loadingImages.containsKey(path)) {
      return (await _loadingImages[path]!).second;
    }

    final future = _loadImage(path);

    _loadingImages[path] = future;

    final loaded = await future;

    _loadingImages.remove(path);

    return loaded.second;
  }
}