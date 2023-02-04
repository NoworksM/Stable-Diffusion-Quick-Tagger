import 'package:flutter/material.dart';
import 'package:quick_tagger/components/tag_sidebar_item.dart';
import 'package:quick_tagger/data/tag_count.dart';

class TagSidebar extends StatefulWidget {
  final Stream<List<TagCount>> stream;
  final Function(String?)? onTagHover;
  final List<String> includedTags;
  final List<String> excludedTags;
  final Function(String)? onIncludedTagSelected;
  final Function(String)? onExcludedTagSelected;

  const TagSidebar(
      {super.key,
      required this.stream,
      this.onTagHover,
      required this.includedTags,
      required this.excludedTags,
      this.onIncludedTagSelected,
      this.onExcludedTagSelected});

  @override
  State<TagSidebar> createState() => _TagSidebarState();
}

enum _TagSort { count, alphabetical }

class _TagSidebarState extends State<TagSidebar> {
  _TagSort sort = _TagSort.count;
  String? hoveredTag;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        children: [
          IconButton(
              onPressed: () => setState(() {
                    sort = _TagSort.count;
                  }),
              icon: const Icon(Icons.sort),
              color: sort == _TagSort.count
                  ? Theme.of(context).colorScheme.secondary
                  : null),
          IconButton(
              onPressed: () => setState(() {
                    sort = _TagSort.alphabetical;
                  }),
              icon: const Icon(Icons.sort_by_alpha),
              color: sort == _TagSort.alphabetical
                  ? Theme.of(context).colorScheme.secondary
                  : null),
        ],
      ),
      Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.includedTags
              .map((t) => TagSelectedSidebarItem(
                    tag: t,
                    included: true,
                    onSelected: (t) => widget.onIncludedTagSelected?.call(t),
                  ))
              .toList()),
      Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.excludedTags
              .map((t) => TagSelectedSidebarItem(
                    tag: t,
                    included: false,
                    onSelected: (t) => widget.onExcludedTagSelected?.call(t),
                  ))
              .toList()),
      Expanded(
        child: StreamBuilder<List<TagCount>>(
          stream: widget.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No tags found'));
            } else {
              sort == _TagSort.count
                  ? snapshot.data!.sort((l, r) {
                      final countCompare = l.count.compareTo(r.count) * -1;

                      return countCompare == 0
                          ? l.tag.compareTo(r.tag)
                          : countCompare;
                    })
                  : snapshot.data!.sort((l, r) => l.tag.compareTo(r.tag));
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, idx) => TagSidebarItem(
                  tagCount: snapshot.data![idx],
                  onHover: (t) => widget.onTagHover?.call(t),
                  onInclude: (t) => widget.onIncludedTagSelected?.call(t),
                  onExclude: (t) => widget.onExcludedTagSelected?.call(t),
                ),
              );
            }
          },
        ),
      ),
    ]);
  }
}
