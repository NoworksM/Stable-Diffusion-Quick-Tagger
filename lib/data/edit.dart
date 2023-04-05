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

  Edit.fromJson(Map<String, dynamic> json)
    : type = EditType.fromJson(json['type']),
      value = json['value'];

  toJson() {
    return {
      'type': type.toJson(),
      'value': value,
    };
  }
}

enum EditType {
  add,
  remove;

  static EditType fromJson(String json) {
    switch (json) {
      case 'add':
        return EditType.add;
      case 'remove':
        return EditType.remove;
      default:
        throw ArgumentError();
    }
  }

  String toJson() {
    switch (this) {
      case EditType.add:
        return 'add';
      case EditType.remove:
        return 'remove';
      default:
        throw ArgumentError();
    }
  }

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