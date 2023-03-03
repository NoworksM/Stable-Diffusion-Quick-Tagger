import 'package:flutter/material.dart';
import 'package:quick_tagger/components/gallery_image.dart';
import 'package:quick_tagger/data/tagged_image.dart';


class Gallery extends StatelessWidget {
  final Stream<List<TaggedImage>> stream;
  final String? hoveredTag;

  const Gallery({super.key, required this.stream, this.hoveredTag});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        } else {
          final images = snapshot.data!;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 1,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemCount: images.length,
            itemBuilder: (ctx, idx) =>
                GalleryImage(image: images[idx], hoveredTag: hoveredTag),
          );
        }
      },
    );
  }
}