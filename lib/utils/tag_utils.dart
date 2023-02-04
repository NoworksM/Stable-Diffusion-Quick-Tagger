import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quick_tagger/data/tagfile_type.dart';
import 'package:quick_tagger/utils/file_utils.dart' as futils;

parseTags(path, tagFileContents) {
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
    } else if (char != ' ') {
      if (char == ' ') {
        spaceCharacter = TagSpaceCharacter.space;
      } else if (char == '_') {
        spaceCharacter = TagSpaceCharacter.underscore;
      }

      builder.write(char);
    }

    if (builder.toString().trim().isNotEmpty) {
      tags.add(builder.toString().trim());
    }
  }

  return TagFile(path, tags, separator ?? TagSeparator.lineBreak, spaceCharacter ?? TagSpaceCharacter.space);
}

readTagsFromFile(path) async {
  final file = File(path);

  final contents = file.readAsString();

  return parseTags(path, contents);
}

readTagsFromFileSync(path) {
  final file = File(path);

  final contents = file.readAsStringSync();

  return parseTags(path, contents);
}

getTagsForFile(path) async {
  final files = await futils.getTagFilesForImageFile(path);

  final tags = <String>{};

  for (final path in files) {
    final tagFile = await readTagsFromFile(path);

    for (final tag in tagFile.tags) {
      tags.add(tag);
    }
  }

  return tags;
}

getTagsForFileSync(path) {
  final files = futils.getTagFilesForImageFileSync(path);

  final tags = <String>{};

  for (final path in files) {
    final fileTags = readTagsFromFileSync(path);

    for (final tag in fileTags) {
      tags.add(tag);
    }
  }

  return tags;
}
