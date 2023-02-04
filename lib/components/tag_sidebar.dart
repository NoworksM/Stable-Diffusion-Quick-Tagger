import 'package:flutter/material.dart';
import 'package:quick_tagger/data/tag_count.dart';

class TagSidebar extends StatefulWidget {
  final Stream<List<TagCount>> stream;

  const TagSidebar({super.key, required this.stream});

  @override
  State<TagSidebar> createState() => _TagSidebarState();
}

enum _TagSort {
  count,
  alphabetical
}

class _TagSidebarState extends State<TagSidebar> {
  _TagSort sort = _TagSort.count;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TagCount>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tags found'));
        } else {
          sort == _TagSort.count
            ? snapshot.data!.sort((l, r) => l.count.compareTo(r.count) * -1)
            : snapshot.data!.sort((l, r) => l.tag.compareTo(r.tag));
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, idx) {
              return Text(
                  '${snapshot.data![idx].tag} (${snapshot.data![idx].count})');
            },
          );
        }
      },
    );
  }

}