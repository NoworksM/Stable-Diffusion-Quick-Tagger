import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/services/tag_service.dart';
import 'package:quick_tagger/utils/file_utils.dart' as futils;
import 'package:quick_tagger/utils/tag_utils.dart' as tagutils;

abstract class IGalleryService {
  Future<void> loadImages(String path);

  Stream<List<TaggedImage>> get galleryStream;

  void updateTagsForImage(TaggedImage image, List<String> tags);
}

@Singleton(as: IGalleryService)
class GalleryService implements IGalleryService {
  final StreamController<List<TaggedImage>> _imageStreamController = StreamController();
  late final Stream<List<TaggedImage>> _imageStream = _imageStreamController.stream.asBroadcastStream();
  final ITagService _tagService;
  List<TaggedImage> _images = List.empty(growable: false);

  GalleryService(this._tagService);

  @override
  Future<void> loadImages(String path) async {
    final tags = HashSet<String>();
    final tagCounts = List<TagCount>.empty(growable: true);

    final newImages = List<TaggedImage>.empty(growable: true);
    await for (final file in Directory(path).list()) {
      if (futils.isSupportedFile(file.path)) {
        final fileTagInfo = await tagutils.getTagsForFile(file.path);

        for (final tag in fileTagInfo.tags) {
          tags.add(tag);
          final tagCount = tagCounts.firstWhere((tc) => tc.tag == tag, orElse: () => TagCount(tag, 0));

          if (tagCount.count == 0) {
            tagCounts.add(tagCount);
          }

          tagCount.count++;
        }

        newImages.add(TaggedImage.file(file.path, fileTagInfo));

        _imageStreamController.add(newImages);
        _tagService.replaceTagCounts(tagCounts);
      }
    }

    _tagService.replaceTags(tags.toList(growable: false));

    _images = newImages;
  }

  @override
  Stream<List<TaggedImage>> get galleryStream => _imageStream;

  @override
  void updateTagsForImage(TaggedImage image, List<String> tags) {
    final index = _images.indexOf(image);

    if (index == -1) {
      return;
    }

    _images[index] = TaggedImage(image.path, HashSet<String>.from(tags), image.tagFiles);

    _imageStreamController.add(_images);
  }

}