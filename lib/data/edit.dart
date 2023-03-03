class Edit {
  final EditType type;
  final String value;

  Edit(this.value, this.type);

  @override
  bool operator ==(Object other) => identical(this, other) || other is Edit && runtimeType == other.runtimeType && type == other.type && value == other.value;

  @override
  int get hashCode => type.hashCode ^ value.hashCode;

  @override
  String toString() {
    return 'Edit{type: $type, value: $value}';
  }
}

enum EditType {
  add,
  remove
}

extension EditTypeExtensions on EditType {
  EditType invert() {
    switch (this) {
      case EditType.add:
        return EditType.remove;
      case EditType.remove:
        return EditType.add;
      default:
        throw ArgumentError();
    }
  }
}