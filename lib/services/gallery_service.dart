import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:quick_tagger/data/tagged_image.dart';

abstract class IGalleryService {
  Future<void> loadImages(String path);

  Stream<List<TaggedImage>> get galleryStream;
}

@Singleton(as: IGalleryService)
class GalleryService implements IGalleryService {
  final StreamController<List<TaggedImage>> _imageController = StreamController();
  late final Stream<List<TaggedImage>> _imageStream = _imageController.stream.asBroadcastStream();

  @override
  Future<void> loadImages(String path) async {

  }

  @override
  Stream<List<TaggedImage>> get galleryStream => _imageStream;

}