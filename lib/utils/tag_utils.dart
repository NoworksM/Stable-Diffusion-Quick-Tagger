import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quick_tagger/data/edit.dart';
import 'package:quick_tagger/data/file_tag_info.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tag_grouped_counts.dart';
import 'package:quick_tagger/data/tagfile_type.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/services/gallery_service.dart';
import 'package:quick_tagger/utils/file_utils.dart' as file_utils;

TagFile parseTags(String path, String tagFileContents) {
  TagSeparator? separator;
  TagSpaceCharacter? spaceCharacter;

  final tags = List<String>.empty(growable: true);
  final builder = StringBuffer();

  for (final char in tagFileContents.characters) {
    if (char == ',' || char == '\n' || char == '\r' || char == '\r\n') {
      if (char == ',') {
        separator = TagSeparator.comma;
      } else if (char == '\n') {
        separator = TagSeparator.lineBreak;
      } else if (char == '\r\n') {
        separator = TagSeparator.carriageReturnLineBreak;
      }

      if (builder.toString().trim().isNotEmpty) {
        tags.add(builder.toString().trim());
        builder.clear();
      }
    } else {
      if (spaceCharacter == null && char == ' ') {
        spaceCharacter = TagSpaceCharacter.space;
      } else if (char == '_') {
        spaceCharacter = TagSpaceCharacter.underscore;
      }

      builder.write(char);
    }
  }

  if (builder.toString().trim().isNotEmpty) {
    tags.add(builder.toString().trim());
  }

  return TagFile(path, tags, separator ?? TagSeparator.lineBreak, spaceCharacter ?? TagSpaceCharacter.space);
}

Future<TagFile> readTagsFromFile(path) async {
  final file = File(path);

  final contents = await file.readAsString();

  return parseTags(path, contents);
}

TagFile readTagsFromFileSync(path) {
  final file = File(path);

  final contents = file.readAsStringSync();

  return parseTags(path, contents);
}

Future<FileTagInfo> getTagsForFile(path) async {
  final files = await file_utils.getTagFilesForImageFile(path);

  final tags = <String>{};
  final tagFiles = <TagFile>[];

  for (final path in files) {
    final tagFile = await readTagsFromFile(path);
    tagFiles.add(tagFile);

    for (final tag in tagFile.tags) {
      tags.add(tag);
    }
  }

  return FileTagInfo(HashSet<String>.from(tags), tagFiles);
}

FileTagInfo getTagsForFileSync(path) {
  final files = file_utils.getTagFilesForImageFileSync(path);

  final tags = <String>{};
  final tagFiles = <TagFile>[];

  for (final path in files) {
    final tagFile = readTagsFromFileSync(path);
    tagFiles.add(tagFile);

    for (final tag in tagFile.tags) {
      tags.add(tag);
    }
  }

  return FileTagInfo(HashSet<String>.from(tags), tagFiles);
}

Future<void> save(TagFile tagFile, Iterable<String> tags) async {
  final enumerated = tags.toList(growable: false);
  final builder = StringBuffer();

  for (var idx = 0; idx < enumerated.length; idx++) {
    final tag = enumerated[idx];

    builder.write(tagFile.spaceCharacter.format(tag));

    if (idx < tags.length - 1) {
      builder.write(tagFile.separator.value);
    }
  }

  await File(tagFile.path).writeAsString(builder.toString());
}

HashSet<String> buildEditedSetOfTagsForImage(TaggedImage image, Set<Edit> edits) {
  final editedTags = HashSet<String>();

  for (final tag in image.tags) {
    if (!edits.contains(Edit(tag, EditType.remove))) {
      editedTags.add(tag);
    }
  }

  for (final edit in edits) {
    if (edit.type == EditType.add) {
      editedTags.add(edit.value);
    }
  }

  return editedTags;
}

List<TaggedImage> filterImagesForTagsAndEdits(List<TaggedImage> images, Map<String, Set<Edit>> allEdits, Set<String> includedTags, Set<String> excludedTags) {
  final filteredImages = List<TaggedImage>.empty(growable: true);

  for (final image in images) {
    final edits = allEdits[image.path];

    late final HashSet<String> tags;
    if (edits != null) {
      tags = buildEditedSetOfTagsForImage(image, edits);
    } else {
      tags = image.tags;
    }

    bool hasExcluded = false;

    for (final excluded in excludedTags) {
      if (tags.contains(excluded)) {
        hasExcluded = true;
        break;
      }
    }

    if (hasExcluded) {
      continue;
    }

    if (tags.containsAll(includedTags)) {
      filteredImages.add(image);
    }
  }

  return filteredImages;
}

transformEditsToCounts(PendingEdits? edits) {
  if (edits == null) {
    return TagGroupedCounts(List.empty(), List.empty());
  }

  final added = HashMap<String, TagCount>.identity();
  final removed = HashMap<String, TagCount>.identity();

  for (final imageEdits in edits.values) {
    for (final edit in imageEdits) {
      late final TagCount count;
      switch (edit.type) {
        case EditType.add:
          count = added.putIfAbsent(edit.value, () => TagCount(edit.value, 0));
          break;
        case EditType.remove:
          count = removed.putIfAbsent(edit.value, () => TagCount(edit.value, 0));
          break;
        default:
          throw ArgumentError();
      }

      count.count++;
    }
  }

  return TagGroupedCounts(added.values.toList(), removed.values.toList());
}

transformImageEditsToCounts(PendingEdit? imageEdits) {
  if (imageEdits == null) {
    return TagGroupedCounts(List.empty(), List.empty());
  }

  final added = HashMap<String, TagCount>.identity();
  final removed = HashMap<String, TagCount>.identity();


  for (final edit in imageEdits) {
    late final TagCount count;
    switch (edit.type) {
      case EditType.add:
        count = added.putIfAbsent(edit.value, () => TagCount(edit.value, 0));
        break;
      case EditType.remove:
        count = removed.putIfAbsent(edit.value, () => TagCount(edit.value, 0));
        break;
      default:
        throw ArgumentError();
    }

    count.count++;
  }

  return TagGroupedCounts(added.values.toList(), removed.values.toList());
}

mergeTagCounts(List<TagCount> first, List<TagCount> second) {
  final merged = HashMap<String, TagCount>.identity();

  for (final count in first) {
    merged[count.tag] = count;
  }

  for (final count in second) {
    final existing = merged.putIfAbsent(count.tag, () => TagCount(count.tag, 0));

    existing.count += count.count;
  }

  return merged.values.toList();
}