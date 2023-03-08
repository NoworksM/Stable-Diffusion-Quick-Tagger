import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_tagger/actions/back.dart';
import 'package:quick_tagger/actions/save_tags.dart';
import 'package:quick_tagger/components/gallery_image.dart';
import 'package:quick_tagger/components/tag_autocomplete.dart';
import 'package:quick_tagger/components/tag_sidebar.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/services/tag_service.dart';

const imageSize = 200.0;

class TagEditor extends StatefulWidget {
  final int initialIndex;
  final List<TaggedImage> images;

  const TagEditor({super.key, required this.images, this.initialIndex = 0});

  @override
  State<StatefulWidget> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  final StreamController<List<TagCount>> _tagCountStreamController = StreamController();
  late final Stream<List<TagCount>> _tagCountStream = _tagCountStreamController.stream.asBroadcastStream();
  late FocusNode _pageFocusNode;
  late FocusNode _textFocusNode;
  final List<String> addedTags = List.empty(growable: true);
  final List<String> removedTags = List.empty(growable: true);
  late final ITagService _tagService;
  late final ScrollController _galleryController;
  int _index = 0;
  bool initialized = false;
  final GlobalKey _galleryKey = GlobalKey();

  List<TagCount> editedTags = List<TagCount>.empty(growable: true);

  TaggedImage get image => widget.images[index];

  List<String> get tags => List.from(image.tags, growable: true);

  int get index => _index;

  set index(int value) {
    _index = value;
    _updateTagCounts();
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
    _tagService = getIt.get<ITagService>();

    _pageFocusNode = FocusNode();

    index = widget.initialIndex;

    _galleryController = ScrollController(initialScrollOffset: imagePosition);

    _updateTagCounts();

    initialized = true;
  }

  @override
  void dispose() {
    _pageFocusNode.dispose();

    super.dispose();
  }

  /// Update tag counts in the UI
  _updateTagCounts() => _tagCountStreamController.add(tags.map((t) => TagCount(t, 1)).toList());

  onTagSubmitted(String tag) {
    setState(() {
      if (tags.contains(tag)) {
        tags.remove(tag);

        if (addedTags.contains(tag)) {
          addedTags.remove(tag);
        } else {
          removedTags.add(tag);
        }
      } else {
        tags.add(tag);

        if (removedTags.contains(tag)) {
          removedTags.remove(tag);
        } else {
          addedTags.add(tag);
        }
      }

      _updateTagCounts();
    });

    _textFocusNode.requestFocus();
  }

  FutureOr<bool> onTagSelected(String tag) {
    setState(() {
      if (tags.contains(tag)) {
        tags.remove(tag);

        if (addedTags.contains(tag)) {
          addedTags.remove(tag);
        } else {
          removedTags.add(tag);
        }
      } else {
        tags.add(tag);

        if (removedTags.contains(tag)) {
          removedTags.remove(tag);
        } else {
          addedTags.add(tag);
        }
      }

      _updateTagCounts();
    });

    _textFocusNode.requestFocus();
    return true;
  }

  onTagsSaved() {
    setState(() {
      tags.addAll(addedTags);
      addedTags.clear();
      removedTags.clear();
    });
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
        actions: <Type, Action<Intent>>{SaveTagsIntent: SaveTagsAction(image, tags, onTagsSaved), BackIntent: BackAction(context)},
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
                        suggestionSearch: _tagService.suggestedGlobalTags,
                      ),
                    ),
                    Flexible(
                        flex: 8,
                        child: Center(
                            child: Image.file(
                          File(image.path),
                          fit: BoxFit.fitHeight,
                        ))),
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
                    stream: _tagCountStream,
                    pendingEdits: const [],
                    imageCount: 1,
                    excludedTags: removedTags,
                    includedTags: addedTags,
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
