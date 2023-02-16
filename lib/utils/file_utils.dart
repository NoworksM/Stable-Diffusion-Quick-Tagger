import 'dart:io';

import 'package:path/path.dart' as p;

const _supportedExtensions = {'.jpg', '.jpeg', '.png'};

isSupportedFile(path) => _supportedExtensions.contains(p.extension(path));

List<String> getPossibleTagFilesForImageFile(path) {
  return [
    '$path.txt',
    '${p.join(p.dirname(path), p.basenameWithoutExtension(path))}.txt'
  ];
}

Future<List<String>> getTagFilesForImageFile(path) async {
  final tagFiles = List<String>.empty(growable: true);

  for (final tagPath in getPossibleTagFilesForImageFile(path)) {
    if (await File(tagPath).exists()) {
      tagFiles.add(tagPath);
    }
  }

  return tagFiles;
}

List<String> getTagFilesForImageFileSync(path) {
  final tagFiles = List<String>.empty(growable: true);

  for (final tagPath in getPossibleTagFilesForImageFile(path)) {
    if (File(tagPath).existsSync()) {
      tagFiles.add(tagPath);
    }
  }

  return tagFiles;
}