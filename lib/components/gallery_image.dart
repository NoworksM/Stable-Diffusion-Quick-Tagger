import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_tagger/data/cached_image.dart';
import 'package:quick_tagger/data/tagfile_type.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/services/image_service.dart';
import 'package:quick_tagger/utils/collection_utils.dart';

class GalleryImage extends StatelessWidget {
  final TaggedImage image;
  final String? hoveredTag;
  final bool selected;
  final Function()? onSelected;
  final Function()? onTap;
  final IImageService _imageService;

  GalleryImage({super.key, required this.image, this.hoveredTag, this.selected = false, this.onSelected, this.onTap})
      : _imageService = getIt.get<IImageService>();

  @override
  Widget build(BuildContext context) {
    late final BoxDecoration? decoration;
    if (hoveredTag != null && image.tags.contains(hoveredTag)) {
      decoration = BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 6));
    } else if (selected) {
      decoration = BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primaryContainer, width: 6));
    } else {
      decoration = null;
    }

    return GestureDetector(
      onTap: () {
        if (onSelected != null &&
            HardwareKeyboard.instance.logicalKeysPressed.containsAny([LogicalKeyboardKey.shift, LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight])) {
          onSelected?.call();
        } else {
          onTap?.call();
        }
      },
      onTertiaryTapUp: (_) => onSelected?.call(),
      child: SizedBox.square(
        dimension: 200,
        child: Stack(fit: StackFit.expand, children: [
          FutureBuilder<CachedImage>(
            future: _imageService.loadImage(image),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              } else {
                final smallest = min(snapshot.data!.width, snapshot.data!.height);

                late int width;
                late int height;
                if (smallest > 300) {
                  final scale = 300 / smallest.toDouble();
                  width = (snapshot.data!.width * scale).toInt();
                  height = (snapshot.data!.height * scale).toInt();
                } else {
                  width = snapshot.data!.width;
                  height = snapshot.data!.height;
                }

                return Image(
                  image: ResizeImage(snapshot.data!.image, width: width, height: height),
                  fit: BoxFit.cover,
                );
              }
            },
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
                      child: Text('${image.tags.length} Tags'),
                    ),
                    const Spacer(),
                    Tooltip(
                        message: image.tagFiles.map((f) => '${f.spaceCharacter.userFriendly}, ${f.separator.userFriendly}').join('\n'),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text('${image.tagFiles.length}'),
                            ),
                            const Icon(Icons.description),
                          ],
                        )),
                  ],
                )),
              ),
            ],
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
            decoration: decoration,
          )
        ]),
      ),
    );
  }
}
