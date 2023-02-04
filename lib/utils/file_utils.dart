import 'dart:io';

import 'package:path/path.dart' as p;

const _supportedExtensions = {'.jpg', '.jpeg', '.png'};

isSupportedFile(path) => _supportedExtensions.contains(p.extension(path));

getPossibleTagFilesForImageFile(path) {
  return [
    '$path.txt',
    '${p.basenameWithoutExtension(path)}.txt'
  ];
}

getTagFilesForImageFile(path) async {
  final tagFiles = List<String>.empty(growable: true);

  for (final tagPath in getPossibleTagFilesForImageFile(path)) {
    if (await File(tagPath).exists()) {
      tagFiles.add(tagPath);
    }
  }

  return tagFiles;
}

getTagFilesForImageFileSync(path) {
  final tagFiles = List<String>.empty(growable: true);

  for (final tagPath in getPossibleTagFilesForImageFile(path)) {
    if (File(tagPath).existsSync()) {
      tagFiles.add(tagPath);
    }
  }

  return tagFiles;
}