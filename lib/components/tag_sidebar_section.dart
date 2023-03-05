import 'package:flutter/material.dart';
import 'package:quick_tagger/components/tag_section_header.dart';
import 'package:quick_tagger/components/tag_sidebar_item.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tag_sort.dart';

class TagSidebarSection extends StatelessWidget {
  final String title;
  final List<TagCount>? positive;
  final List<TagCount>? negative;
  final List<TagCount>? neutral;
  final TagSort sort;
  final bool selectable;
  final Function(String)? onPositiveSelected;
  final Function(String)? onNegativeSelected;

  const TagSidebarSection(
      {super.key, required this.title, this.positive, this.negative, this.neutral, required this.sort, this.selectable = false, this.onPositiveSelected, this.onNegativeSelected});

  @override
  Widget build(BuildContext context) {
    final children = List<Widget>.empty(growable: true);

    children.add(TagSectionHeader(title: title));

    if (positive != null) {
      for (final tagCount in positive!) {
        children.add(TagSelectedSidebarItem(
          tag: tagCount.tag,
          count: tagCount.count,
          included: true,
          onSelected: onPositiveSelected,
        ));
      }
    }

    if (negative != null) {
      for (final tagCount in negative!) {
        children.add(TagSelectedSidebarItem(
          tag: tagCount.tag,
          count: tagCount.count,
          included: false,
          onSelected: onNegativeSelected,
        ));
      }
    }

    if (neutral != null) {
      for (final tagCount in neutral!) {
        children.add(TagSidebarItem(
          tag: tagCount.tag,
          count: tagCount.count,
          onInclude: onPositiveSelected,
          onExclude: onNegativeSelected,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
