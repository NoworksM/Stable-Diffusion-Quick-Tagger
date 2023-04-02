import 'package:flutter/material.dart';
import 'package:quick_tagger/components/gallery.dart';
import 'package:quick_tagger/components/image_count_footer.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/services/gallery_service.dart';
import 'package:quick_tagger/utils/tag_utils.dart' as tag_utils;

class GalleryTab extends StatelessWidget {
  final List<TaggedImage>? initialImages;
  final Stream<List<TaggedImage>> imageStream;
  final String? hoveredTag;
  final Set<String> selectedImagePaths;
  final int tagCount;
  final Set<String> includedTags;
  final Set<String> excludedTags;
  final Function(TaggedImage)? onImageSelected;
  final Function()? onClearSelection;
  final _galleryService = getIt.get<IGalleryService>();

  GalleryTab({super.key,
    this.initialImages,
    required this.imageStream,
    this.hoveredTag,
    required this.selectedImagePaths,
    required this.tagCount,
    required this.includedTags,
    required this.excludedTags,
    this.onImageSelected,
    this.onClearSelection});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaggedImage>>(
      initialData: initialImages,
      stream: imageStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData){
          return const Center(child: CircularProgressIndicator());
        } else {
          final images = tag_utils.filterImagesForTagsAndEdits(snapshot.data!, _galleryService.pendingEdits, includedTags, excludedTags);

          final selected = images.where((i) => selectedImagePaths.contains(i.path)).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Gallery(
                    images: images,
                    hoveredTag: hoveredTag,
                    selectedImages: selectedImagePaths,
                    onImageSelected: (i) => onImageSelected?.call(i)),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: ImageCountFooter(
                  images: snapshot.data!.length,
                  filtered: images.length,
                  selected: selected,
                  filteredTags: includedTags.length + excludedTags.length,
                  totalTags: tagCount,
                  onClearSelection: () => onClearSelection?.call(),
                ),
              ),
            ],
          );
        }
      }
    );
  }
}
