import 'dart:collection';

class DirectoryInfo {
  final String path;
  final DirectoryType type;
  final UnmodifiableListView<DirectoryInfo> subDirectories;

  DirectoryInfo(this.path, this.type, this.subDirectories);

  DirectoryInfo.single(this.path, this.type)
    : subDirectories = UnmodifiableListView(List.empty());
}

enum DirectoryType {
  normal,
  loraRepeat,
  lora,
  unknown
}