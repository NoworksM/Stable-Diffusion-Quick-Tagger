import 'package:path/path.dart' as p;

final _toSpacesRegex = RegExp(r'_+');
final _toUnderscoreRegex = RegExp(r'\w+');

enum TagSeparator {
  comma,
  lineBreak,
  carriageReturnLineBreak,
}

enum TagSpaceCharacter {
  space,
  underscore
}

extension TagSeparatorExtensions on TagSeparator {
  String get userFriendly {
    switch (this) {
      case TagSeparator.comma:
        return ',';
      case TagSeparator.lineBreak:
        return '(Line Break)';
      case TagSeparator.carriageReturnLineBreak:
        return '(Carriage Return + Line Break)';
      default:
        throw ArgumentError.value(this);
    }
  }

  String get value {
    switch (this) {
      case TagSeparator.comma:
        return ',';
      case TagSeparator.lineBreak:
        return '\n';
      case TagSeparator.carriageReturnLineBreak:
        return '\r\n';
      default:
        throw ArgumentError.value(this);
    }
  }
}

extension TagSpaceCharacterExtensions on TagSpaceCharacter {
  String get userFriendly {
    switch (this) {
      case TagSpaceCharacter.space:
        return '(Space)';
      case TagSpaceCharacter.underscore:
        return '_';
      default:
        throw ArgumentError.value(this);
    }
  }

  String get value {
    switch (this) {
      case TagSpaceCharacter.space:
        return ' ';
      case TagSpaceCharacter.underscore:
        return '_';
    }
  }

  String format(String tag) {
    switch (this) {
      case TagSpaceCharacter.space:
        return tag.replaceAll(_toSpacesRegex, value);
      case TagSpaceCharacter.underscore:
        return tag.replaceAll(_toUnderscoreRegex, value);
    }
  }
}

class TagType {
  final TagSeparator separator;
  final TagSpaceCharacter spaceCharacter;

  TagType(this.separator, this.spaceCharacter);
}

enum TagPathFormat {
  addTxt,
  replaceExtension
}

_buildTagFilePathAddTxt(String path) {
  return '$path.txt';
}

_buildTagFilePathReplaceExtension(String path) {
  return p.join(p.dirname(path), '${p.basenameWithoutExtension(path)}.txt');
}

extension TagPathFormatExtensions on TagPathFormat{
  String buildTagFilePathFromImagePath(String path) {
    switch (this) {
      case TagPathFormat.addTxt:
        return _buildTagFilePathAddTxt(path);
      case TagPathFormat.replaceExtension:
        return _buildTagFilePathReplaceExtension(path);
    }
  }

  String get userFriendly {
    switch (this) {
      case TagPathFormat.addTxt:
        return 'append .txt';
      case TagPathFormat.replaceExtension:
        return 'replace extension with .txt';
    }
  }
}

class TagFile {
  final String path;
  final TagSeparator separator;
  final TagSpaceCharacter spaceCharacter;
  final List<String> tags;

  TagFile(this.path, this.tags, this.separator, this.spaceCharacter);

  TagFile.fromTagType(this.path, this.tags, TagType tagType)
    : separator = tagType.separator,
      spaceCharacter = tagType.spaceCharacter;

  TagType get tagType => TagType(separator, spaceCharacter);
}