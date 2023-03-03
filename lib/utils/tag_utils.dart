import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quick_tagger/data/file_tag_info.dart';
import 'package:quick_tagger/data/tagfile_type.dart';
import 'package:quick_tagger/utils/file_utils.dart' as futils;

TagFile parseTags(String path, String tagFileContents) {
  TagSeparator? separator;
  TagSpaceCharacter? spaceCharacter;

  final tags = List<String>.empty(growable: true);
  final builder = StringBuffer();

  for (final char in tagFileContents.characters) {
    if (char == ',' || char == '\n') {
      if (char == ',') {
        separator = TagSeparator.comma;
      } else if (char == '\n') {
        separator = TagSeparator.lineBreak;
      }

      tags.add(builder.toString().trim());
      builder.clear();
    } else {
      if (char == ' ') {
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
  final files = await futils.getTagFilesForImageFile(path);

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
  final files = futils.getTagFilesForImageFileSync(path);

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

Future<void> save(TagFile tagFile, List<String> tags) async {
  final builder = StringBuffer();

  for (var idx = 0; idx < tags.length; idx++) {
    final tag = tags[idx];

    builder.write(tagFile.spaceCharacter.format(tag));

    if (idx < tags.length - 1) {
      builder.write(tagFile.separator.value());
    }
  }

  await File(tagFile.path).writeAsString(builder.toString());
}