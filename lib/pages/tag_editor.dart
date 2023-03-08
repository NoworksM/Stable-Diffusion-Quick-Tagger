import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_tagger/actions/back.dart';
import 'package:quick_tagger/actions/save_tags.dart';
import 'package:quick_tagger/components/tag_autocomplete.dart';
import 'package:quick_tagger/components/tag_sidebar.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/services/tag_service.dart';

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
  int index = 0;

  List<TagCount> editedTags = List<TagCount>.empty(growable: true);

  TaggedImage get image => widget.images[index];

  List<String> get tags => List.from(image.tags, growable: true);

  @override
  void initState() {
    super.initState();
    _tagService = getIt.get<ITagService>();

    _pageFocusNode = FocusNode();

    index = widget.initialIndex;

    _updateTagCounts();
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
          child: Listener(
            onPointerUp: (e) {
              if (e.buttons & kBackMouseButton == kBackMouseButton) {
                Actions.handler(context, BackIntent());
              }
            },
            child: Row(
              children: [
                Expanded(
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
                      Expanded(
                          child: Center(
                              child: Image.file(
                        File(image.path),
                        fit: BoxFit.fitHeight,
                      ))),
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
      ),
    );
  }
}
