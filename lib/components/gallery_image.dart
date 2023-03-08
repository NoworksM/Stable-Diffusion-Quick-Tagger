import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/pages/tag_editor_page.dart';
import 'package:quick_tagger/utils/collection_utils.dart';

class GalleryImage extends StatefulWidget {
  final TaggedImage image;
  final String? hoveredTag;
  final bool selected;
  final Function()? onSelected;
  final Function()? onTap;

  const GalleryImage({super.key, required this.image, this.hoveredTag, this.selected = false, this.onSelected, this.onTap});

  @override
  State<StatefulWidget> createState() => _GalleryImageState();
}

class _GalleryImageState extends State<GalleryImage> {
  @override
  Widget build(BuildContext context) {
    late final BoxDecoration? decoration;
    if (widget.hoveredTag != null && widget.image.tags.contains(widget.hoveredTag)) {
      decoration = BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 6));
    } else if (widget.selected) {
      decoration = BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primaryContainer, width: 6));
    } else {
      decoration = null;
    }

    return GestureDetector(
      onTap: () {
        if (widget.onSelected != null &&
            HardwareKeyboard.instance.logicalKeysPressed.containsAny([LogicalKeyboardKey.shift, LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight])) {
          widget.onSelected?.call();
        } else {
          widget.onTap?.call();
        }
      },
      onTertiaryTapUp: (_) => widget.onSelected?.call(),
      child: Stack(fit: StackFit.expand, children: [
        Image.file(
          File(widget.image.path),
          fit: BoxFit.cover,
        ),
        Column(
          children: [
            const Spacer(),
            Container(
              color: Theme.of(context).dialogBackgroundColor.withAlpha(200),
              padding: const EdgeInsets.all(8.0),
              child: Center(
                  child: Row(
                children: [
                  const Icon(Icons.sell),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text('${widget.image.tags.length} Tags'),
                  ),
                ],
              )),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          decoration: decoration,
        )
      ]),
    );
  }
}
