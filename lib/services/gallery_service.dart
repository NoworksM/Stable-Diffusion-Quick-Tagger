import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:quick_tagger/data/edit.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/services/tag_service.dart';
import 'package:quick_tagger/utils/file_utils.dart' as file_utils;
import 'package:quick_tagger/utils/tag_utils.dart' as tag_utils;

typedef PendingEdit = UnmodifiableSetView<Edit>;
typedef PendingEdits = UnmodifiableMapView<String, PendingEdit>;
typedef FilePendingEdit = MapEntry<String, Edit>;

abstract class IGalleryService {
  Future<void> loadImages(String path);

  UnmodifiableListView<TaggedImage> get galleryImages;

  Stream<List<TaggedImage>> get galleryImagesStream;

  Stream<PendingEdits> get pendingEditsStream;

  PendingEdits get pendingEdits;

  /// Get pending edits for an image
  PendingEdit getPendingEditForImage(TaggedImage image);

  /// Get stream of pending edits for an image
  Stream<PendingEdit> getPendingEditStreamForImage(TaggedImage image);

  /// Queue an edit for an image
  void queueEditForImage(TaggedImage image, Edit edit);

  /// Dequeue an edit for an image
  void dequeueEditForImage(TaggedImage image, Edit edit);

  /// Queue a set of edits for an image
  void queueEditsForImage(TaggedImage image, Set<Edit> edits);

  /// Dequeue a set of edits for an image
  void dequeueEditsForImage(TaggedImage image, Set<Edit> edits);

  /// Queue an edit for images
  void queueEditForImages(List<TaggedImage> images, Edit edit);

  /// Dequeue an edit for images
  void dequeueEditForImages(List<TaggedImage> images, Edit edit);

  /// Queue a set of edits for images
  void queueEditsForImages(List<TaggedImage> images, Set<Edit> edits);

  /// Dequeue a set of edits for images
  void dequeueEditsForImages(List<TaggedImage> images, Set<Edit> edits);

  /// Queue a sparse collection of file edits
  void queueFileEdits(Iterable<FilePendingEdit> edits);

  /// Dequeue a sparse collection of file edits
  void dequeueFileEdits(Iterable<FilePendingEdit> edits);

  /// Update the tags for an image
  void updateTagsForImage(TaggedImage image, Iterable<String> tags, {bool updateImageStream = true});

  /// Save changes for a single image from a set of edits
  Future<bool> saveChanges(TaggedImage image, HashSet<Edit> edits);

  /// Save changes for multiple images based on filenames and a set of edits
  Future<HashMap<String, HashSet<Edit>>> saveAllChanges(HashMap<String, HashSet<Edit>> edits);

  /// Save all pending changes
  Future<void> savePendingChanges();

  /// Save pending changes for an image
  Future<void> saveImagePendingChanges(TaggedImage image);

  /// Get stream of current tags for an image
  Stream<UnmodifiableSetView<String>> getTagStreamForImage(TaggedImage image);

  /// Get current tags for an image
  UnmodifiableSetView<String> getTagsForImage(TaggedImage image);
}

@Singleton(as: IGalleryService)
class GalleryService implements IGalleryService {
  final ITagService _tagService;

  List<TaggedImage> _images = List.empty(growable: false);
  final StreamController<List<TaggedImage>> _imageStreamController = StreamController();
  late final Stream<List<TaggedImage>> _imageStream = _imageStreamController.stream.asBroadcastStream();

  final HashMap<String, HashSet<Edit>> _pendingEdits = HashMap<String, HashSet<Edit>>();
  final StreamController<PendingEdits> _pendingEditsStreamController = StreamController<PendingEdits>();
  late final Stream<PendingEdits> _pendingEditsStream = _pendingEditsStreamController.stream.asBroadcastStream();
  final HashMap<String, Stream<PendingEdit>> _pendingImageEditsStreams = HashMap();

  final HashMap<String, StreamController<UnmodifiableSetView<String>>> _imageTagStreamControllers = HashMap();
  final HashMap<String, Stream<UnmodifiableSetView<String>>> _imageTagStreams = HashMap();

  GalleryService(this._tagService) {
    _imageStream.transform(StreamTransformer.fromHandlers(handleData: (images, sink) {
      for (final image in images) {
        _imageTagStreamControllers[image.path]?.add(UnmodifiableSetView(image.tags));
      }
    }));
  }

  @override
  Stream<PendingEdits> get pendingEditsStream => _pendingEditsStream;

  @override
  PendingEdits get pendingEdits => UnmodifiableMapView(_pendingEdits.map((key, value) => MapEntry(key, UnmodifiableSetView(value))));

  @override
  UnmodifiableListView<TaggedImage> get galleryImages => UnmodifiableListView(_images);

  @override
  Future<void> loadImages(String path) async {
    final tags = HashSet<String>();
    final tagCounts = List<TagCount>.empty(growable: true);

    final newImages = List<TaggedImage>.empty(growable: true);
    await for (final file in Directory(path).list()) {
      if (file_utils.isSupportedFile(file.path)) {
        final fileTagInfo = await tag_utils.getTagsForFile(file.path);

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

    _tagService.replaceDatasetTags(tags.toList(growable: false));

    _images = newImages;
  }

  @override
  Stream<List<TaggedImage>> get galleryImagesStream => _imageStream;

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
        await tag_utils.save(tagFile, updatedTags);
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

  @override
  Future<void> savePendingChanges() async {
    final results = await saveAllChanges(_pendingEdits);

    _pendingEdits.clear();

    for (final key in results.keys) {
      if (results.containsKey(key)) {
        _pendingEdits[key] = results[key]!;
      }
    }

    _pendingEditsStreamController.add(pendingEdits);
  }

  @override
  void queueEditForImage(TaggedImage image, Edit edit) {
    final imageEdits = _pendingEdits.putIfAbsent(image.path, () => HashSet<Edit>());

    imageEdits.add(edit);

    _pendingEditsStreamController.add(pendingEdits);
  }

  @override
  void queueEditForImages(List<TaggedImage> images, Edit edit) {
    for (final image in images) {
      final imageEdits = _pendingEdits.putIfAbsent(image.path, () => HashSet<Edit>());

      imageEdits.add(edit);
    }

    _pendingEditsStreamController.add(pendingEdits);
  }

  @override
  void queueEditsForImage(TaggedImage image, Set<Edit> edits) {
    final imageEdits = _pendingEdits.putIfAbsent(image.path, () => HashSet<Edit>());

    imageEdits.addAll(edits);

    _pendingEditsStreamController.add(pendingEdits);
  }

  @override
  void queueEditsForImages(List<TaggedImage> images, Set<Edit> edits) {
    for (final image in images) {
      final imageEdits = _pendingEdits.putIfAbsent(image.path, () => HashSet<Edit>());

      imageEdits.addAll(edits);
    }

    _pendingEditsStreamController.add(pendingEdits);
  }

  @override
  void dequeueEditForImage(TaggedImage image, Edit edit) {
    final imageEdits = _pendingEdits.putIfAbsent(image.path, () => HashSet<Edit>());

    imageEdits.remove(edit);

    _pendingEditsStreamController.add(pendingEdits);
  }

  @override
  void dequeueEditForImages(List<TaggedImage> images, Edit edit) {
    for (final image in images) {
      final imageEdits = _pendingEdits.putIfAbsent(image.path, () => HashSet<Edit>());

      imageEdits.remove(edit);
    }

    _pendingEditsStreamController.add(pendingEdits);
  }

  @override
  void dequeueEditsForImage(TaggedImage image, Set<Edit> edits) {
    final imageEdits = _pendingEdits.putIfAbsent(image.path, () => HashSet<Edit>());

    imageEdits.removeAll(edits);

    _pendingEditsStreamController.add(pendingEdits);
  }

  @override
  void dequeueEditsForImages(List<TaggedImage> images, Set<Edit> edits) {
    for (final image in images) {
      final imageEdits = _pendingEdits.putIfAbsent(image.path, () => HashSet<Edit>());

      imageEdits.removeAll(edits);
    }

    _pendingEditsStreamController.add(pendingEdits);
  }

  @override
  Stream<UnmodifiableSetView<Edit>> getPendingEditStreamForImage(TaggedImage image) {
    return _pendingImageEditsStreams.putIfAbsent(image.path, () => _pendingEditsStream.transform<PendingEdit>(StreamTransformer<PendingEdits, PendingEdit>.fromHandlers(handleData: (data, sink) {
      final imageEdits = data[image.path];

      if (imageEdits == null) {
        sink.add(UnmodifiableSetView(HashSet<Edit>()));
      } else {
        sink.add(imageEdits);
      }
    })));
  }

  @override
  PendingEdit getPendingEditForImage(TaggedImage image) {
    final imageEdits = _pendingEdits[image.path];

    return UnmodifiableSetView<Edit>(imageEdits ?? HashSet<Edit>());
  }

  @override
  void queueFileEdits(Iterable<FilePendingEdit> edits) {
    for (final edit in edits) {
      _pendingEdits.putIfAbsent(edit.key, () => HashSet<Edit>()).add(edit.value);
    }

    _pendingEditsStreamController.add(pendingEdits);
  }

  @override
  void dequeueFileEdits(Iterable<FilePendingEdit> edits) {
    for (final edit in edits) {
      _pendingEdits[edit.key]?.remove(edit.value);
    }

    _pendingEditsStreamController.add(pendingEdits);
  }

  @override
  Stream<UnmodifiableSetView<String>> getTagStreamForImage(TaggedImage image) {
    final controller = _imageTagStreamControllers.putIfAbsent(image.path, () => StreamController());
    return _imageTagStreams.putIfAbsent(image.path, () => controller.stream.asBroadcastStream());
  }

  @override
  Future<void> saveImagePendingChanges(TaggedImage image) async {
    if (_pendingEdits.containsKey(image.path)) {
      await saveChanges(image, _pendingEdits[image.path]!);
      _pendingEdits.remove(image.path);

      _pendingEditsStreamController.add(pendingEdits);
    }
  }

  @override
  UnmodifiableSetView<String> getTagsForImage(TaggedImage image) {
    for (final i in _images) {
      if (i.path == image.path) {
        return UnmodifiableSetView(i.tags);
      }
    }

    return UnmodifiableSetView(HashSet<String>());
  }
}
