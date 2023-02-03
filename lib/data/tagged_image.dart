class TaggedImage {
  final String path;
  final List<String> tags;

  TaggedImage(this.path, this.tags);
  TaggedImage.noTags(this.path)
    : tags = List.empty(growable: false);
}