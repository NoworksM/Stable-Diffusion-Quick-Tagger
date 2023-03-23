import 'package:flutter/material.dart';
import 'package:quick_tagger/components/gallery_image.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/pages/tag_editor_page.dart';
import 'package:quick_tagger/services/gallery_service.dart';
import 'package:quick_tagger/utils/tag_utils.dart' as tag_utils;

class Gallery extends StatelessWidget {
  final List<TaggedImage>? initialImages;
  final Stream<List<TaggedImage>> stream;
  final String? hoveredTag;
  final Set<String>? selectedImages;
  final Set<String> includedTags;
  final Set<String> excludedTags;
  final Function(TaggedImage)? onImageSelected;
  final _galleryService = getIt.get<IGalleryService>();

  Gallery({super.key, this.initialImages, required this.stream, required this.includedTags, required this.excludedTags, this.hoveredTag, this.selectedImages, this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: initialImages,
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        } else {
          final images = tag_utils.filterImagesForTagsAndEdits(snapshot.data!, _galleryService.pendingEdits, includedTags, excludedTags);

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
      },
    );
  }
}
