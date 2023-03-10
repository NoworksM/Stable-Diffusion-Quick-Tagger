import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_tagger/components/tag_section_header.dart';
import 'package:quick_tagger/components/tag_sidebar_item.dart';
import 'package:quick_tagger/components/tag_sidebar_section.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tag_grouped_counts.dart';
import 'package:quick_tagger/data/tag_sort.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/utils/collection_utils.dart';

class TagSidebar extends StatefulWidget {
  final Stream<List<TagCount>> tagsStream;
  final List<TagCount>? initialTags;
  final Function(String?)? onTagHover;
  final List<String>? includedTags;
  final List<String>? excludedTags;
  final Stream<TagGroupedCounts> pendingEditCountsStream;
  final TagGroupedCounts? initialPendingEditCounts;
  final Function(String)? onIncludedTagSelected;
  final Function(String)? onExcludedTagSelected;
  final Function(String)? onRemoveTagSelected;
  final Function(String)? onCancelPendingTagAddition;
  final Function(String)? onCancelPendingTagRemoval;
  final bool selectable;
  final int imageCount;
  final bool searchable;
  final TaggedImage? image;

  const TagSidebar({super.key,
    required this.tagsStream,
    this.initialTags,
    this.selectable = true,
    this.searchable = true,
    this.onTagHover,
    required this.imageCount,
    this.includedTags,
    this.excludedTags,
    this.initialPendingEditCounts,
    required this.pendingEditCountsStream,
    this.onIncludedTagSelected,
    this.onExcludedTagSelected,
    this.onRemoveTagSelected,
    this.onCancelPendingTagAddition,
    this.onCancelPendingTagRemoval,
    this.image});

  @override
  State<TagSidebar> createState() => _TagSidebarState();
}

class _TagSidebarState extends State<TagSidebar> {
  TagSort sort = TagSort.count;
  String? hoveredTag;
  int totalTags = 0;
  String _tagSearch = '';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        children: [
          IconButton(
              onPressed: () =>
                  setState(() {
                    sort = TagSort.count;
                  }),
              icon: const Icon(Icons.sort),
              color: sort == TagSort.count ? Theme
                  .of(context)
                  .colorScheme
                  .secondary : null),
          IconButton(
              onPressed: () =>
                  setState(() {
                    sort = TagSort.alphabetical;
                  }),
              icon: const Icon(Icons.sort_by_alpha),
              color: sort == TagSort.alphabetical ? Theme
                  .of(context)
                  .colorScheme
                  .secondary : null),
        ],
      ),
      StreamBuilder<TagGroupedCounts>(
          key: widget.image != null ? Key('imageTagCounts:${widget.image!.path}') : null,
          stream: widget.pendingEditCountsStream,
          initialData: widget.initialPendingEditCounts,
          builder: (context, snapshot) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: (snapshot.data?.added.isNotEmpty ?? false) || (snapshot.data?.removed.isNotEmpty ?? false)
                  ? TagSidebarSection(
                title: 'Editing',
                positive: snapshot.data!.added,
                negative: snapshot.data!.removed,
                sort: sort,
                selectable: true,
                onPositiveSelected: widget.onCancelPendingTagAddition,
                onNegativeSelected: widget.onCancelPendingTagRemoval,
              )
                  : const SizedBox.shrink(),
            );
          }),
      AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: (widget.includedTags?.isNotEmpty ?? false) || (widget.excludedTags?.isNotEmpty ?? false)
              ? TagSidebarSection(
              title: 'Filtered',
              sort: sort,
              positive: widget.includedTags!.map((i) => TagCount(i, widget.imageCount)).toList(growable: false),
              negative: widget.excludedTags!.map((e) => TagCount(e, widget.imageCount)).toList(growable: false),
              onPositiveSelected: widget.onIncludedTagSelected,
              onNegativeSelected: widget.onExcludedTagSelected)
              : const SizedBox.shrink()),
      const TagSectionHeader(title: 'Tags'),
      AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: widget.searchable
              ? TextFormField(
            onChanged: (v) =>
                setState(() {
                  _tagSearch = v;
                }),
            decoration: const InputDecoration(hintText: 'Filter tags'),
          )
              : const SizedBox.shrink()),
      Expanded(
        child: StreamBuilder<List<TagCount>>(
          key: widget.image != null ? Key('imageTags:${widget.image!.path}') : null,
          stream: widget.tagsStream,
          initialData: widget.initialTags,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No tags found'));
            } else {
              totalTags = snapshot.data!.length;

              final filtered = snapshot.data!.where((t) => t.tag.toLowerCase().contains(_tagSearch.toLowerCase())).toList(growable: false);

              sort == TagSort.count
                  ? filtered.sort((l, r) {
                final countCompare = l.count.compareTo(r.count) * -1;

                return countCompare == 0 ? l.tag.compareTo(r.tag) : countCompare;
              })
                  : filtered.sort((l, r) => l.tag.compareTo(r.tag));

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, idx) =>
                    TagSidebarItem(
                      tag: filtered[idx].tag,
                      count: filtered[idx].count,
                      selectable: widget.selectable,
                      onHover: (t) => widget.onTagHover?.call(t),
                      onInclude: (t) => widget.onIncludedTagSelected?.call(t),
                      onExclude: (t) {
                        if (widget.onRemoveTagSelected != null && HardwareKeyboard.instance.logicalKeysPressed
                            .containsAny([LogicalKeyboardKey.shift, LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight])) {
                          widget.onRemoveTagSelected!.call(t);
                        } else {
                          widget.onExcludedTagSelected?.call(t);
                        }
                      },
                    ),
              );
            }
          },
        ),
      ),
    ]);
  }
}
