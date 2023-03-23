class TagCount {
  final String tag;
  int count;

  TagCount(this.tag, this.count);

  @override
  bool operator ==(Object other) => identical(this, other) || other is TagCount && runtimeType == other.runtimeType && tag == other.tag;

  @override
  int get hashCode => tag.hashCode;
}