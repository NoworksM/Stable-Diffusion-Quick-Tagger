import 'package:quick_tagger/data/tagfile_type.dart';

class TagFileInfo {
  final String path;
  final TagSeparator separator;
  final TagSpaceCharacter spaceCharacter;

  TagFileInfo(this.path, this.separator, this.spaceCharacter);
}