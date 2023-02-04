import 'dart:io';

import 'package:flutter/material.dart';

import '../data/tagged_image.dart';

class GalleryImage extends StatefulWidget {
  final TaggedImage image;
  final String? hoveredTag;

  const GalleryImage({super.key, required this.image, this.hoveredTag});

  @override
  State<StatefulWidget> createState() => _GalleryImageState();
}

class _GalleryImageState extends State<GalleryImage> {
  @override
  Widget build(BuildContext context) {
    final decoration = widget.hoveredTag != null &&
            widget.image.tags.contains(widget.hoveredTag)
        ? BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.secondary, width: 6))
        : null;

    return Stack(fit: StackFit.expand, children: [
      Image.file(
        File(widget.image.path),
        fit: BoxFit.cover,
      ),
      Column(
        children: [
          const Expanded(child: Spacer()),
          Container(
            color: Theme.of(context).dialogBackgroundColor.withAlpha(155),
            padding: const EdgeInsets.all(4.0),
            child: Center(
                child: Row(
              children: [
                const Icon(Icons.sell),
                Text('${widget.image.tags.length} Tags'),
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
    ]);
  }
}
