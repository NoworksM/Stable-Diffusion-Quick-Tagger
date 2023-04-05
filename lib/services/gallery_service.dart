import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:quick_tagger/data/directory_info.dart';
import 'package:quick_tagger/data/edit.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tagfile_type.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/services/image_service.dart';
import 'package:quick_tagger/services/tag_service.dart';
import 'package:quick_tagger/utils/file_utils.dart' as file_utils;
import 'package:quick_tagger/utils/tag_utils.dart' as tag_utils;

import '../data_structures/tuple.dart';

typedef PendingEdit = UnmodifiableSetView<Edit>;
typedef PendingEdits = UnmodifiableMapView<String, PendingEdit>;
typedef FilePendingEdit = MapEntry<String, Edit>;

abstract class IGalleryService {
  Future<void> loadImages(String path);

  UnmodifiableListView<TaggedImage> get galleryImages;

  Stream<List<TaggedImage>> get galleryImagesStream;

  Stream<UnmodifiableListView<TaggedImage>> getStreamForDirectory(DirectoryInfo directoryInfo);
  UnmodifiableListView<TaggedImage> getImagesForDirectory(DirectoryInfo directoryInfo);

  Stream<PendingEdits> get pendingEditsStream;

  PendingEdits get pendingEdits;

  Stream<DirectoryInfo> get directoryInfoStream;

  DirectoryInfo? get directoryInfo;

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
  Future<bool> saveChanges(TaggedImage image, HashSet<Edit> edits, {bool updateImageStream = true});

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

  Future<void> convertTagFiles(TagSeparator separator, TagSpaceCharacter spaceCharacter, TagPathFormat pathFormat,
      {List<TaggedImage>? images, bool deleteOld = true});
}

typedef _ImageDirectoryResults = Trio<DirectoryInfo, List<TaggedImage>, List<TagCount>>;

final _loraRepeatFolderSyntax = RegExp(r'^(\d+)_(.*)$');

@Singleton(as: IGalleryService)
class GalleryService implements IGalleryService {
  final ITagService _tagService;
  final IImageService _imageService;

  List<TaggedImage> _images = List.empty(growable: true);
  final StreamController<List<TaggedImage>> _imageStreamController = StreamController();
  late final Stream<List<TaggedImage>> _imageStream = _imageStreamController.stream.asBroadcastStream();

  final HashMap<DirectoryInfo, List<TaggedImage>> _directoryImages = HashMap();
  final HashMap<DirectoryInfo, StreamController<UnmodifiableListView<TaggedImage>>> _directoryImageStreamController = HashMap();
  final HashMap<DirectoryInfo, Stream<UnmodifiableListView<TaggedImage>>> _directoryImageStreams = HashMap();

  DirectoryInfo? _directoryInfo;
  final StreamController<DirectoryInfo> _directoryInfoStreamController = StreamController();
  late final Stream<DirectoryInfo> _directoryInfoStream = _directoryInfoStreamController.stream.asBroadcastStream();

  final HashMap<String, HashSet<Edit>> _pendingEdits = HashMap<String, HashSet<Edit>>();
  final StreamController<PendingEdits> _pendingEditsStreamController = StreamController<PendingEdits>();
  late final Stream<PendingEdits> _pendingEditsStream = _pendingEditsStreamController.stream.asBroadcastStream();
  final HashMap<String, Stream<PendingEdit>> _pendingImageEditsStreams = HashMap();

  final HashMap<String, StreamController<UnmodifiableSetView<String>>> _imageTagStreamControllers = HashMap();
  final HashMap<String, Stream<UnmodifiableSetView<String>>> _imageTagStreams = HashMap();

  GalleryService(this._tagService, this._imageService) {
    _imageStream.listen((images) {
      for (final image in images) {
        _imageTagStreamControllers[image.path]?.add(UnmodifiableSetView(image.tags));
      }
    });
  }

  @override
  Stream<PendingEdits> get pendingEditsStream => _pendingEditsStream;

  @override
  PendingEdits get pendingEdits => UnmodifiableMapView(_pendingEdits.map((key, value) => MapEntry(key, UnmodifiableSetView(value))));

  @override
  UnmodifiableListView<TaggedImage> get galleryImages => UnmodifiableListView(_images);

  void _clearGallery() {
    _imageService.clearCache();
    _pendingEdits.clear();
    _pendingEditsStreamController.add(pendingEdits);

    _images = List.empty(growable: true);
    _imageStreamController.add(_images);

    _directoryImageStreamController.clear();
    _directoryImageStreams.clear();
    _directoryImages.clear();
  }

  @override
  Future<void> loadImages(String path) async {
    _clearGallery();

    final directory = Directory(path);

    final List<TaggedImage> images = List.empty(growable: true);
    var tagCounts = List<TagCount>.empty(growable: true);

    final imageLoadStreamController = StreamController<TaggedImage>();
    final tagCountLoadStreamController = StreamController<List<TagCount>>();

    final imageLoadStream = imageLoadStreamController.stream.asBroadcastStream();

    imageLoadStream.listen((i) {
      images.add(i);
      _images = UnmodifiableListView(images);
      _imageStreamController.add(_images);
    });

    tagCountLoadStreamController.stream.listen((tc) {
      tagCounts = tag_utils.mergeTagCounts(tagCounts, tc);
      _tagService.replaceTagCounts(tagCounts);
    });

    final subDirs = await directory
        .list()
        .where((i) => i is Directory)
        .map((i) => i as Directory)
        .asyncMap((d) => _loadDirectoryInfo(d))
        .toList();

    final name = directory.path.split(Platform.pathSeparator).last;

    late final DirectoryType type;

    if (subDirs.isEmpty) {
      type = DirectoryType.normal;
    } else if (name == 'img' && subDirs.every((i) => i.type == DirectoryType.loraRepeat)) {
      type = DirectoryType.loraImg;
    } else if (subDirs.any((d) => d.name == 'img' && d.type == DirectoryType.loraImg)) {
      type = DirectoryType.lora;
    } else {
      type = DirectoryType.normal;
    }

    _directoryInfo = DirectoryInfo.imageLess(directory.path, name, type, subDirs);
    _directoryInfoStreamController.add(_directoryInfo!);

    final dirData = await _loadImagesForDirectory(_directoryInfo!, imageLoadStreamController, tagCountLoadStreamController);

    _directoryInfo = dirData.first;
    _directoryInfoStreamController.add(_directoryInfo!);

    _images.addAll(dirData.second);
    tagCounts = tag_utils.mergeTagCounts(tagCounts, dirData.third);

    _imageStreamController.add(_images);
    _tagService.replaceTagCounts(tagCounts);

    imageLoadStreamController.close();
    tagCountLoadStreamController.close();
  }

  /// Get directory info for a directory and it's subdirectories
  FutureOr<DirectoryInfo> _loadDirectoryInfo(Directory directory) async {
    late final DirectoryType type;
    late final int? repeats;
    var name = directory.path.split(Platform.pathSeparator).last;

    final subDirs = await directory
        .list()
        .where((i) => i is Directory)
        .map((i) => i as Directory)
        .asyncMap((d) => _loadDirectoryInfo(d))
        .toList();

    final match = _loraRepeatFolderSyntax.matchAsPrefix(name);

    if (match != null) {
      type = DirectoryType.loraRepeat;
      repeats = int.parse(match.group(1)!);
      name = match.group(2)!;
    } else if (subDirs.isEmpty) {
      type = DirectoryType.normal;
      repeats = null;
    } else if (name == 'img' && subDirs.every((i) => i.type == DirectoryType.loraRepeat)) {
      type = DirectoryType.loraImg;
      repeats = null;
    } else if (subDirs.any((d) => d.name == 'img' && d.type == DirectoryType.loraImg)) {
      type = DirectoryType.lora;
      repeats = null;
    } else {
      type = DirectoryType.normal;
      repeats = null;
    }

    return DirectoryInfo.imageLess(directory.path, name, type, subDirs, repeats: repeats);
  }

  Future<_ImageDirectoryResults> _loadImagesForDirectory(DirectoryInfo directory, StreamController<TaggedImage> imageStreamController, StreamController<List<TagCount>> tagCountsStreamController) async {
    List<DirectoryInfo> subDirectories = List.empty(growable: true);

    for (final subDir in directory.subDirectories) {
      final subDirData = await _loadImagesForDirectory(subDir, imageStreamController, tagCountsStreamController);
      subDirectories.add(subDirData.first);
    }

    final tags = HashSet<String>();
    final tagCounts = List<TagCount>.empty(growable: true);

    final controller = _directoryImageStreamController.putIfAbsent(directory, () => StreamController());
    _directoryImageStreams.putIfAbsent(directory, () => controller.stream.asBroadcastStream());
    final directoryImages = _directoryImages.putIfAbsent(directory, () => List.empty(growable: true));

    final newImages = List<TaggedImage>.empty(growable: true);
    await for (final file in Directory(directory.path).list()) {
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

        final digest = await _imageService.hashImage(file.path);

        final image = TaggedImage.file(file.path, fileTagInfo, digest);

        await _imageService.loadImage(image.path);

        newImages.add(image);
        directoryImages.add(image);
        controller.add(UnmodifiableListView(newImages));

        imageStreamController.add(image);
        tagCountsStreamController.add(tagCounts);
      }
    }

    return Trio(DirectoryInfo.withChildren(directory, subDirectories, newImages), newImages, tagCounts);
  }

  @override
  Stream<List<TaggedImage>> get galleryImagesStream => _imageStream;

  @override
  void updateTagsForImage(TaggedImage image, Iterable<String> tags, {bool updateImageStream = true}) {
    final index = _images.indexWhere((i) => i.path == image.path);

    if (index == -1) {
      return;
    }

    final updatedImages = List<TaggedImage>.from(_images, growable: true);

    updatedImages[index] = TaggedImage(image.path, HashSet<String>.from(tags), image.tagFiles, image.digest);

    _images = UnmodifiableListView(updatedImages);

    if (updateImageStream) {
      _imageStreamController.add(_images);
    }
  }

  @override
  Future<bool> saveChanges(TaggedImage image, HashSet<Edit> edits, {bool updateImageStream = false}) async {
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

      updateTagsForImage(image, updatedTags, updateImageStream: updateImageStream);

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

        if (!await saveChanges(image, edits, updateImageStream: false)) {
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
    return _pendingImageEditsStreams.putIfAbsent(
        image.path,
        () => _pendingEditsStream.transform<PendingEdit>(StreamTransformer<PendingEdits, PendingEdit>.fromHandlers(handleData: (data, sink) {
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
      await saveChanges(image, _pendingEdits[image.path]!, updateImageStream: true);
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

  _convertTagFileForImageIndex(int index, TagSeparator separator, TagSpaceCharacter spaceCharacter, TagPathFormat pathFormat, bool deleteOld) async {
    final image = _images[index];

    final newTagFile = TagFile(pathFormat.buildTagFilePathFromImagePath(image.path), image.tags.toList(growable: true), separator, spaceCharacter);
    final tagFiles = List<TagFile>.empty(growable: true);
    tagFiles.add(newTagFile);

    if (!deleteOld) {
      tagFiles.addAll(image.tagFiles.where((f) => f.path != newTagFile.path));
    }

    await tag_utils.save(newTagFile, image.tags);
    _images[index] = TaggedImage(image.path, image.tags, tagFiles, image.digest);

    if (deleteOld) {
      for (final tagFile in image.tagFiles) {
        if (tagFile.path == newTagFile.path) {
          continue;
        }

        await File(tagFile.path).delete();
      }
    }

    _imageStreamController.add(_images);
  }

  @override
  Future<void> convertTagFiles(TagSeparator separator, TagSpaceCharacter spaceCharacter, TagPathFormat pathFormat,
      {List<TaggedImage>? images, bool deleteOld = true}) async {
    if (images == null) {
      for (int idx = 0; idx < _images.length; idx++) {
        await _convertTagFileForImageIndex(idx, separator, spaceCharacter, pathFormat, deleteOld);
      }
    } else {
      for (final image in images) {
        int index = _images.indexWhere((i) => i.path == image.path);
        if (index != -1) {
          await _convertTagFileForImageIndex(index, separator, spaceCharacter, pathFormat, deleteOld);
        }
      }
    }
  }

  @override
  DirectoryInfo? get directoryInfo => _directoryInfo;

  @override
  Stream<DirectoryInfo> get directoryInfoStream => _directoryInfoStream;

  @override
  Stream<UnmodifiableListView<TaggedImage>> getStreamForDirectory(DirectoryInfo directory) {
    final controller = _directoryImageStreamController.putIfAbsent(directory, () => StreamController());
    return _directoryImageStreams.putIfAbsent(directory, () => controller.stream.asBroadcastStream());
  }

  @override
  UnmodifiableListView<TaggedImage> getImagesForDirectory(DirectoryInfo directoryInfo) {
    return UnmodifiableListView(_directoryImages.putIfAbsent(directoryInfo, () => List<TaggedImage>.empty(growable: true)));
  }
}
