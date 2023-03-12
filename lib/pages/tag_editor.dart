import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_tagger/actions/back.dart';
import 'package:quick_tagger/actions/save_tags.dart';
import 'package:quick_tagger/components/gallery_image.dart';
import 'package:quick_tagger/components/tag_autocomplete.dart';
import 'package:quick_tagger/components/tag_sidebar.dart';
import 'package:quick_tagger/data/cached_image.dart';
import 'package:quick_tagger/data/edit.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/services/gallery_service.dart';
import 'package:quick_tagger/services/image_service.dart';
import 'package:quick_tagger/services/tag_service.dart';
import 'package:quick_tagger/utils/tag_utils.dart' as tag_utils;

const imageSize = 200.0;

class TagEditor extends StatefulWidget {
  final int initialIndex;
  final List<TaggedImage> images;

  const TagEditor({super.key, required this.images, this.initialIndex = 0});

  @override
  State<StatefulWidget> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  late FocusNode _pageFocusNode;
  late FocusNode _textFocusNode;
  late final IGalleryService _galleryService;
  late final IImageService _imageService;
  late final ITagService _tagService;
  late final ScrollController _galleryController;
  int _index = 0;
  bool initialized = false;
  final GlobalKey _galleryKey = GlobalKey();
  int? _width;
  int? _height;

  List<TagCount> editedTags = List<TagCount>.empty(growable: true);

  TaggedImage get image => widget.images[index];

  int get index => _index;

  set index(int value) {
    _index = value;
    if (initialized) {
      _scrollToCurrent();
    }
  }

  double get imagePosition => index * (imageSize + 8);

  _scrollToCurrent() {
    final renderBox = _galleryKey.currentContext?.findRenderObject() as RenderBox?;

    double position = imagePosition;

    if (renderBox != null) {
      position -= renderBox.size.width / 2;
    }

    _galleryController.animateTo(position, duration: const Duration(milliseconds: 500), curve: Curves.easeInOutQuad);
  }

  @override
  void initState() {
    super.initState();
    _galleryService = getIt.get<IGalleryService>();
    _imageService = getIt.get<IImageService>();
    _tagService = getIt.get<ITagService>();

    _pageFocusNode = FocusNode();

    index = widget.initialIndex;

    _galleryController = ScrollController(initialScrollOffset: imagePosition);

    initialized = true;
  }

  @override
  void dispose() {
    _pageFocusNode.dispose();

    super.dispose();
  }

  onTagSubmitted(String tag) {
    final tags = _galleryService.getTagsForImage(image);
    final pendingEdits = _galleryService.getPendingEditForImage(image);

    if (tags.contains(tag)) {
      final edit = Edit(tag, EditType.remove);

      if (pendingEdits.contains(edit)) {
        _galleryService.dequeueEditForImage(image, edit);
      } else {
        _galleryService.queueEditForImage(image, edit);
      }
    } else {
      final edit = Edit(tag, EditType.add);

      if (pendingEdits.contains(edit)) {
        _galleryService.dequeueEditForImage(image, edit);
      } else {
        _galleryService.queueEditForImage(image, edit);
      }
    }

    _textFocusNode.requestFocus();
  }

  _onCancelPendingTagAddition(String tag) {
    _galleryService.dequeueEditForImage(image, Edit(tag, EditType.add));
  }

  _onCancelPendingTagRemoval(String tag) {
    _galleryService.dequeueEditForImage(image, Edit(tag, EditType.remove));
  }

  FutureOr<bool> onTagSelected(String tag) {
    onTagSubmitted(tag);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): SaveTagsIntent(),
        const SingleActivator(LogicalKeyboardKey.goBack): BackIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): BackIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{SaveTagsIntent: SaveTagsAction(image), BackIntent: BackAction(context)},
        child: Focus(
          autofocus: true,
          focusNode: _pageFocusNode,
          onFocusChange: (hasFocus) {
            if (!hasFocus) _pageFocusNode.requestFocus();
          },
          child: Row(
            children: [
              Flexible(
                flex: 8,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TagAutocomplete(
                        onTagSelected: onTagSelected,
                        onFocusNodeUpdated: (n) => _textFocusNode = n,
                        suggestionSearch: _tagService.suggestedDatasetTags,
                        hintText: 'Add or remove tags',
                      ),
                    ),
                    Flexible(
                        flex: 8,
                        child: Center(
                          child: FutureBuilder<CachedImage>(
                            key: Key('imageView:${image.path}'),
                            future: _imageService.loadImage(image),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              } else {
                                if (_width != null && _height != null) {
                                  return Image(
                                    image: ResizeImage(snapshot.data!.image, width: _width!, height: _height!),
                                    fit: BoxFit.cover,
                                  );
                                } else {
                                  return Image(
                                    image: snapshot.data!.image,
                                    fit: BoxFit.cover
                                  );
                                }
                              }
                            },
                          ),
                        )),
                    SizedBox(
                      height: imageSize,
                      child: ListView.builder(
                          key: _galleryKey,
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.images.length,
                          controller: _galleryController,
                          itemBuilder: (context, idx) => Padding(
                                padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 4.0),
                                child: GalleryImage(
                                    image: widget.images[idx],
                                    selected: index == idx,
                                    onTap: () => setState(() {
                                          index = idx;
                                        })),
                              )),
                    ),
                  ],
                ),
              ),
              Flexible(
                  flex: 2,
                  child: TagSidebar(
                      tagsStream: _galleryService
                          .getTagStreamForImage(image)
                          .asyncMap((d) => d.toList(growable: false))
                          .asyncMap((d) => d.map((e) => TagCount(e, 1)).toList(growable: false)),
                      initialTags: image.tags.map((e) => TagCount(e, 1)).toList(growable: false),
                      initialPendingEditCounts: tag_utils.transformImageEditsToCounts(_galleryService.getPendingEditForImage(image)),
                      pendingEditCountsStream: _galleryService.getPendingEditStreamForImage(image).asyncMap((d) => tag_utils.transformImageEditsToCounts(d)),
                      imageCount: 1,
                      image: image,
                      onRemoveTagSelected: (t) => _galleryService.queueEditForImage(image, Edit(t, EditType.remove)),
                    onCancelPendingTagAddition: _onCancelPendingTagAddition,
                    onCancelPendingTagRemoval: _onCancelPendingTagRemoval,
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
