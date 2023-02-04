import 'dart:io';

import 'package:flutter/material.dart';

import '../data/tagged_image.dart';

class GalleryImage extends StatefulWidget {
  final TaggedImage image;

  const GalleryImage({super.key, required this.image});

  @override
  State<StatefulWidget> createState() => _GalleryImageState();
}

class _GalleryImageState extends State<GalleryImage> {
  @override
  Widget build(BuildContext context) {
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
            child: Center(child: Row(
              children: [
                const Icon(Icons.sell),
                Text('${widget.image.tags.length} Tags'),
              ],
            )),
          ),
        ],
      )
    ]);
  }
}
