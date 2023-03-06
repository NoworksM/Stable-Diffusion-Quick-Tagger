extension SetExtensions<T> on Set<T> {
  bool containsAny(Iterable<T> values) {
    for (final value in values) {
      if (contains(value)) {
        return true;
      }
    }

    return false;
  }
}