import 'package:flutter/material.dart';

class TagSidebarItem extends StatefulWidget {
  final String tag;
  final int? count;
  final bool selectable;
  final Function(String)? onInclude;
  final Function(String)? onExclude;
  final Function(String?)? onHover;

  const TagSidebarItem({super.key, required this.tag, this.count, this.selectable = true, this.onInclude, this.onExclude, this.onHover});
  

  @override
  State<StatefulWidget> createState() => _TagSidebarItemState();
  
}

class _TagSidebarItemState extends State<TagSidebarItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = isHovered && widget.selectable
        ? TextStyle(color: Theme.of(context).colorScheme.secondary)
        : null;
    final bgColor = isHovered && widget.selectable
        ? Theme.of(context).dialogBackgroundColor
        : null;

    return GestureDetector(
      onTap: () { if (widget.selectable) widget.onInclude?.call(widget.tag); },
      onTertiaryTapUp: (e) { if (widget.selectable) widget.onExclude?.call(widget.tag); },
      child: MouseRegion(
        onEnter: (e) {
          if (widget.selectable) {
            setState(() {
              isHovered = true;
            });
            widget.onHover?.call(widget.tag);
          }
        },
        onExit: (e) {
          if (widget.selectable) {
            setState(() {
              isHovered = false;
            });
            widget.onHover?.call(null);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          decoration: BoxDecoration(color: bgColor),
          child: widget.count != null
            ? Text('${widget.tag} (${widget.count})', style: textStyle)
            : Text(widget.tag, style: textStyle),
        ),
      ),
    );
  }
}

class TagSelectedSidebarItem extends StatelessWidget {
  final String tag;
  final int? count;
  final bool included;
  final Function(String)? onSelected;

  const TagSelectedSidebarItem({super.key, required this.tag, required this.included, this.count, this.onSelected});

  @override
  Widget build(BuildContext context) {
    final color = included ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error;

    return GestureDetector(
        onTap: () => onSelected?.call(tag),
        onTertiaryTapUp: (e) => onSelected?.call(tag),
        child: count != null
            ? Text('$tag ($count)', style: TextStyle(color: color))
            : Text(tag, style: TextStyle(color: color))
    );
  }
}