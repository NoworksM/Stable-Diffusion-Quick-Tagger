import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:quick_tagger/components/tag_section_header.dart';
import 'package:quick_tagger/components/tag_sidebar_item.dart';
import 'package:quick_tagger/components/tag_sidebar_section.dart';
import 'package:quick_tagger/data/edit.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tag_sort.dart';

class TagSidebar extends StatefulWidget {
  final Stream<List<TagCount>> stream;
  final Function(String?)? onTagHover;
  final List<String> includedTags;
  final List<String> excludedTags;
  final List<Edit> pendingEdits;
  final Function(String)? onIncludedTagSelected;
  final Function(String)? onExcludedTagSelected;
  final bool selectable;
  final int imageCount;
  final bool searchable;

  const TagSidebar(
      {super.key,
      required this.stream,
      this.selectable = true,
      this.searchable = true,
      this.onTagHover,
      required this.imageCount,
      required this.includedTags,
      required this.excludedTags,
      required this.pendingEdits,
      this.onIncludedTagSelected,
      this.onExcludedTagSelected});

  _TagGroupedCounts get _editedGroupCounts {
    final added = HashMap<String, TagCount>.identity();
    final removed = HashMap<String, TagCount>.identity();

    for (final edit in pendingEdits) {
      late final TagCount count;
      switch (edit.type) {
        case EditType.add:
          count = added.putIfAbsent(edit.value, () => TagCount(edit.value, 0));
          break;
        case EditType.remove:
          count = removed.putIfAbsent(edit.value, () => TagCount(edit.value, 0));
          break;
        default:
          throw ArgumentError();
      }

      count.count++;
    }

    return _TagGroupedCounts(added.values.toList(), removed.values.toList());
  }

  @override
  State<TagSidebar> createState() => _TagSidebarState();
}

class _TagSidebarState extends State<TagSidebar> {
  TagSort sort = TagSort.count;
  String? hoveredTag;
  int totalTags = 0;
  String _tagSearch = '';
  final StreamController<List<TagCount>> _tagCountStreamController = StreamController();
  late final Stream<List<TagCount>> _tagCountStream;
  List<TagCount>? _tagCounts;

  String get tagSearch => _tagSearch;

  set tagSearch(String value) {
    _tagSearch = value;
    if (_tagCounts != null) {
      _tagCountStreamController.add(_tagCounts!);
    }
  }

  @override
  void initState() {
    super.initState();

    _tagCountStreamController.addStream(widget.stream);
  }

  @override
  Widget build(BuildContext context) {
    final groupedCounts = widget._editedGroupCounts;

    return Column(children: [
      Row(
        children: [
          IconButton(
              onPressed: () => setState(() {
                    sort = TagSort.count;
                  }),
              icon: const Icon(Icons.sort),
              color: sort == TagSort.count ? Theme.of(context).colorScheme.secondary : null),
          IconButton(
              onPressed: () => setState(() {
                    sort = TagSort.alphabetical;
                  }),
              icon: const Icon(Icons.sort_by_alpha),
              color: sort == TagSort.alphabetical ? Theme.of(context).colorScheme.secondary : null),
        ],
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: widget.pendingEdits.isNotEmpty
            ? TagSidebarSection(
                title: 'Editing',
                positive: groupedCounts.added,
                negative: groupedCounts.removed,
                sort: sort,
              )
            : const SizedBox.shrink(),
      ),
      AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: widget.includedTags.isNotEmpty || widget.excludedTags.isNotEmpty
              ? TagSidebarSection(
                  title: 'Filtered',
                  sort: sort,
                  positive: widget.includedTags.map((i) => TagCount(i, widget.imageCount)).toList(growable: false),
                  negative: widget.excludedTags.map((e) => TagCount(e, widget.imageCount)).toList(growable: false),
                  onPositiveSelected: widget.onIncludedTagSelected,
                  onNegativeSelected: widget.onExcludedTagSelected)
              : const SizedBox.shrink()),
      const TagSectionHeader(title: 'Tags'),
      AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: widget.searchable
              ? TextFormField(
                  onChanged: (v) => setState(() {
                        _tagSearch = v;
                      }))
              : const SizedBox.shrink()),
      Expanded(
        child: StreamBuilder<List<TagCount>>(
          stream: _tagCountStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No tags found'));
            } else {
              totalTags = snapshot.data!.length;

              final filtered = snapshot.data!.where((t) => t.tag.toLowerCase().contains(tagSearch.toLowerCase())).toList(growable: false);

              sort == TagSort.count
                  ? filtered.sort((l, r) {
                final countCompare = l.count.compareTo(r.count) * -1;

                return countCompare == 0 ? l.tag.compareTo(r.tag) : countCompare;
              })
                  : filtered.sort((l, r) => l.tag.compareTo(r.tag));

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, idx) => TagSidebarItem(
                  tag: filtered[idx].tag,
                  count: filtered[idx].count,
                  selectable: widget.selectable,
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

class _TagGroupedCounts {
  List<TagCount> added;
  List<TagCount> removed;

  _TagGroupedCounts(this.added, this.removed);
}
