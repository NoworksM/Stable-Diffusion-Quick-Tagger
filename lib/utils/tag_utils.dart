import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quick_tagger/data/tagfile_type.dart';

detectTagFileType(File tagFile) async {
  final contents = await tagFile.readAsString();

  var hasUnderscore = false;
  var hasSpaces = false;
  var hasLineBreaks = false;

  for (final char in contents.characters) {
    switch (char) {
      case '_':
        hasUnderscore = true;
        break;
      case ' ':
        hasSpaces = true;
        break;
      case '\n':
        hasLineBreaks = true;
        break;
    }
  }

  throw UnimplementedError();

  // if (hasLineBreaks && hasUnderscore && !hasSpaces) {
  //   return TagfileType.danbooru;
  // } else if (hasLineBreaks && hasSpaces) {
  //   return TagfileType.hydrusRepo;
  // } else if (hasLineBreaks) {
  //   return TagfileType.stableDiffusion
  // }
}

parseStableDiffusionTags(tagFile) {
  throw UnimplementedError();
}

parseDanbooruTags(tagFile) {
  throw UnimplementedError();
}

parseTags(tagFile) {
  throw UnimplementedError();
}