final _toSpacesRegex = RegExp(r'_+');
final _toUnderscoreRegex = RegExp(r'\w+');

enum TagSeparator {
  comma,
  lineBreak
}

enum TagSpaceCharacter {
  space,
  underscore
}

extension TagSeparatorExtensions on TagSeparator {
  String userFriendly() {
    switch (this) {
      case TagSeparator.comma:
        return ',';
      case TagSeparator.lineBreak:
        return '\n (Line Break)';
      default:
        throw ArgumentError.value(this);
    }
  }

  String value() {
    switch (this) {
      case TagSeparator.comma:
        return ',';
      case TagSeparator.lineBreak:
        return '\r\n';
      default:
        throw ArgumentError.value(this);
    }
  }
}

extension TagSpaceCharacterExtensions on TagSpaceCharacter {
  String userFriendly() {
    switch (this) {
      case TagSpaceCharacter.space:
        return '(Space)';
      case TagSpaceCharacter.underscore:
        return '_';
      default:
        throw ArgumentError.value(this);
    }
  }

  String value() {
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
        return tag.replaceAll(_toSpacesRegex, value());
      case TagSpaceCharacter.underscore:
        return tag.replaceAll(_toUnderscoreRegex, value());
    }
  }
}

class TagType {
  final TagSeparator separator;
  final TagSpaceCharacter spaceCharacter;

  TagType(this.separator, this.spaceCharacter);
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