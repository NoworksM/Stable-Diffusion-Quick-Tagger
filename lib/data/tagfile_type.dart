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