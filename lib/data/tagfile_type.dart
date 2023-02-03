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