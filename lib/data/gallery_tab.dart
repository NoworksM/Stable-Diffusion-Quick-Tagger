import 'package:flutter/material.dart';
import 'package:quick_tagger/components/gallery.dart';
import 'package:quick_tagger/components/image_count_footer.dart';
import 'package:quick_tagger/data/tagged_image.dart';

class GalleryTab extends StatelessWidget {
  final List<TaggedImage>? initialImages;
  final Stream<List<TaggedImage>> imageStream;
  final String? hoveredTag;
  final Set<String> selectedImagePaths;
  final int imageCount;
  final int filteredImageCount;
  final int selectedImageCount;
  final int filteredTagCount;
  final int tagCount;
  final Set<String> includedTags;
  final Set<String> excludedTags;
  final Function(TaggedImage)? onImageSelected;
  final Function()? onClearSelection;

  const GalleryTab({super.key,
    this.initialImages,
    required this.imageStream,
    this.hoveredTag,
    required this.selectedImagePaths,
    required this.imageCount,
    required this.filteredImageCount,
    required this.selectedImageCount,
    required this.filteredTagCount,
    required this.tagCount,
    required this.includedTags,
    required this.excludedTags,
    this.onImageSelected,
    this.onClearSelection});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Gallery(
              initialImages: initialImages,
              stream: imageStream,
              hoveredTag: hoveredTag,
              selectedImages: selectedImagePaths,
              includedTags: includedTags,
              excludedTags: excludedTags,
              onImageSelected: (i) => onImageSelected?.call(i)),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: ImageCountFooter(
            images: imageCount,
            filtered: filteredImageCount,
            selected: selectedImageCount,
            filteredTags: filteredTagCount,
            totalTags: tagCount,
            onClearSelection: () => onClearSelection?.call(),
          ),
        ),
      ],
    );
  }
}
