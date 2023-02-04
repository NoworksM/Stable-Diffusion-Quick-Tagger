import 'package:flutter/material.dart';
import 'package:quick_tagger/data/tag_count.dart';

class TagSidebarItem extends StatefulWidget {
  final TagCount tagCount;
  final Function(String)? onInclude;
  final Function(String)? onExclude;
  final Function(String?)? onHover;

  const TagSidebarItem({super.key, required this.tagCount, this.onInclude, this.onExclude, this.onHover});
  

  @override
  State<StatefulWidget> createState() => _TagSidebarItemState();
  
}

class _TagSidebarItemState extends State<TagSidebarItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = isHovered
        ? TextStyle(color: Theme.of(context).colorScheme.secondary)
        : null;
    final bgColor = isHovered
        ? Theme.of(context).dialogBackgroundColor
        : null;

    return GestureDetector(
      onTap: () => widget.onInclude?.call(widget.tagCount.tag),
      onTertiaryTapUp: (e) => widget.onExclude?.call(widget.tagCount.tag),
      child: MouseRegion(
        onEnter: (e) {
          setState(() {
            isHovered = true;
          });
          widget.onHover?.call(widget.tagCount.tag);
        },
        onExit: (e) {
          setState(() {
            isHovered = false;
          });
          widget.onHover?.call(null);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          decoration: BoxDecoration(color: bgColor),
          child: Text('${widget.tagCount.tag} (${widget.tagCount.count})', style: textStyle),
        ),
      ),
    );
  }
}

class TagSelectedSidebarItem extends StatelessWidget {
  final String tag;
  final bool included;
  final Function(String)? onSelected;

  const TagSelectedSidebarItem({super.key, required this.tag, required this.included, this.onSelected});

  @override
  Widget build(BuildContext context) {
    final color = included ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error;

    return GestureDetector(
        onTap: () => onSelected?.call(tag),
        onTertiaryTapUp: (e) => onSelected?.call(tag),
        child: Text(tag, style: TextStyle(color: color))
    );
  }
}