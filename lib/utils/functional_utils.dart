
import 'dart:collection';

typedef Grouper<K, V> = K Function(V value);

// extension FunctionalIteration<V> on Iterable<V> {
//   List<Grouping<G, V>> groupBy<G>(Iterable<V> items, Grouper<G, V> predicate) {
//     final data = <G, V>{};
//
//     for (final item in items) {
//       final key = predicate(item);
//
//       if (data.containsKey(key)) {
//
//       } else {
//         data.p
//       }
//     }
//
//     return data.entries.map((p) => Grouping<G, V>(p.key, p.value)).toList();
//   }
// }

class Grouping<TKey, TItem> {
  final TKey key;
  final List<TItem> items;

  Grouping(this.key, this.items);
}