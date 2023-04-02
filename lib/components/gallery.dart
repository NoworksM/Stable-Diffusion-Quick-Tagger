import 'package:flutter/material.dart';
import 'package:quick_tagger/components/gallery_image.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/pages/tag_editor_page.dart';

class Gallery extends StatelessWidget {
  final List<TaggedImage> images;
  final String? hoveredTag;
  final Set<String>? selectedImages;
  final Function(TaggedImage)? onImageSelected;

  const Gallery({super.key, required this.images, this.hoveredTag, this.selectedImages, this.onImageSelected});

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
      itemBuilder: (ctx, idx) => GalleryImage(
          image: images[idx],
          hoveredTag: hoveredTag,
          selected: selectedImages?.contains(images[idx].path) ?? false,
          onSelected: () => onImageSelected?.call(images[idx]),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TagEditorPage(initialIndex: idx, images: images)))),
    );
  }
}
