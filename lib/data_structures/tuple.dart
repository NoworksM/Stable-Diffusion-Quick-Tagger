class Pair<T1, T2> {
  final T1 first;
  final T2 second;

  Pair(this.first, this.second);

  @override
  String toString() {
    return 'Pair{first: $first, second: $second}';
  }
}

class Trio<T1, T2, T3> extends Pair<T1, T2> {
  final T3 third;

  Trio(super.first, super.second, this.third);

  @override
  String toString() {
    return 'Trio{first: $first, second: $second, third: $third}';
  }
}

class Quartet<T1, T2, T3, T4> extends Trio<T1, T2, T3> {
  final T4 fourth;

  Quartet(super.first, super.second, super.third, this.fourth);

  @override
  String toString() {
    return 'Trio{first: $first, second: $second, third: $third, fourth: $fourth}';
  }
}