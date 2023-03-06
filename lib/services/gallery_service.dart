import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:quick_tagger/data/edit.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/services/tag_service.dart';
import 'package:quick_tagger/utils/file_utils.dart' as futils;
import 'package:quick_tagger/utils/tag_utils.dart' as tagutils;

abstract class IGalleryService {
  Future<void> loadImages(String path);

  Stream<List<TaggedImage>> get galleryStream;

  void updateTagsForImage(TaggedImage image, Iterable<String> tags, {bool updateImageStream = true});

  /// Save changes for a single image from a set of edits
  Future<bool> saveChanges(TaggedImage image, HashSet<Edit> edits);

  /// Save changes for multiple images based on filenames and a set of edits
  Future<HashMap<String, HashSet<Edit>>> saveAllChanges(HashMap<String, HashSet<Edit>> edits);
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

    // TODO: Add in code to modify for tags that don't exist
    // _tagService.replaceTags(tags.toList(growable: false));

    _images = newImages;
  }

  @override
  Stream<List<TaggedImage>> get galleryStream => _imageStream;

  @override
  void updateTagsForImage(TaggedImage image, Iterable<String> tags, {bool updateImageStream = true}) {
    final index = _images.indexOf(image);

    if (index == -1) {
      return;
    }

    _images[index] = TaggedImage(image.path, HashSet<String>.from(tags), image.tagFiles);

    if (updateImageStream) {
      _imageStreamController.add(_images);
    }
  }

  @override
  Future<bool> saveChanges(TaggedImage image, HashSet<Edit> edits) async {
    try {
      final updatedTags = HashSet<String>();

      for (final tag in image.tags) {
        if (edits.contains(Edit(tag, EditType.remove))) {
          continue;
        }

        updatedTags.add(tag);
      }

      for (final edit in edits) {
        if (edit.type == EditType.add) {
          updatedTags.add(edit.value);
        }
      }

      updateTagsForImage(image, updatedTags, updateImageStream: false);

      for (final tagFile in image.tagFiles) {
        await tagutils.save(tagFile, updatedTags);
        tagFile.tags.clear();
        tagFile.tags.addAll(updatedTags);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<HashMap<String, HashSet<Edit>>> saveAllChanges(HashMap<String, HashSet<Edit>> imageEdits) async {
    final unsaved = HashMap<String, HashSet<Edit>>();

    for (final pair in imageEdits.entries) {
      final path = pair.key;
      final edits = pair.value;

      try {
        final image = _images.firstWhere((i) => i.path == path);

        if (!await saveChanges(image, edits)) {
          unsaved[path] = edits;
        }
      } catch (_) {
        unsaved[path] = edits;
      }
    }

    _imageStreamController.add(_images);

    return unsaved;
  }
}