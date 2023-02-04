class TaggedImage {
  final String path;
  final Set<String> tags;

  TaggedImage(this.path, this.tags);
  TaggedImage.noTags(this.path)
    : tags = Set.identity();
}