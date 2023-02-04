import 'package:flutter/material.dart';

import '../components/gallery_image.dart';
import '../data/tagged_image.dart';

class Gallery extends StatelessWidget {
  final List<TaggedImage> images;

  const Gallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: images.length,
      itemBuilder: (ctx, idx) => GalleryImage(image: images[idx]),
    );
  }

}