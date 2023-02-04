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
          const Spacer(),
          Flexible(
            fit: FlexFit.loose,
            child: Container(
              color: Theme.of(context).dialogBackgroundColor.withAlpha(155),
              child: Center(child: Text('${widget.image.tags.length} Tags')),
            ),
          ),
        ],
      )
    ]);
  }
}
