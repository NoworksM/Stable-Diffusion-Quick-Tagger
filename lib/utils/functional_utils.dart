import 'dart:collection';

typedef Grouper<K, V> = K Function(V value);

extension FunctionalIteration<V> on Iterable<V> {
  List<Grouping<G, V>> groupBy<G>(Grouper<G, V> predicate) {
    final data = HashMap<G, List<V>>();

    for (final item in this) {
      final key = predicate(item);

      final list = data.putIfAbsent(key, () => List<V>.empty(growable: true));

      list.add(item);
    }

    return data.entries.map((p) => Grouping<G, V>(p.key, p.value)).toList(growable: false);
  }

  List<Grouping<G, V>> groupSortedBy<G>(Grouper<G, V> predicate) {
    // ignore: prefer_collection_literals
    final data = LinkedHashMap<G, List<V>>();

    for (final item in this) {
      final key = predicate(item);

      final list = data.putIfAbsent(key, () => List<V>.empty(growable: true));

      list.add(item);
    }

    return data.entries.map((p) => Grouping<G, V>(p.key, p.value)).toList(growable: false);
  }
}

class Grouping<TKey, TItem> {
  final TKey key;
  final List<TItem> items;

  Grouping(this.key, this.items);
}

extension IterableExtensions<T> on Iterable<Iterable<T>> {
  Iterable<T> flatten() sync* {
    for (final iterable in this) {
      yield* iterable;
    }
  }
}