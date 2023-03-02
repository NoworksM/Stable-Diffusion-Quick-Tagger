import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_tagger/actions/back.dart';
import 'package:quick_tagger/actions/save_tags.dart';
import 'package:quick_tagger/components/tag_sidebar.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/services/tag_service.dart';

class TagEditor extends StatefulWidget {
  final TaggedImage image;

  const TagEditor({super.key, required this.image});

  @override
  State<StatefulWidget> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  final StreamController<List<TagCount>> _tagCountStreamController = StreamController();
  late TextEditingController _tagTextController;
  late final Stream<List<TagCount>> _tagCountStream = _tagCountStreamController.stream.asBroadcastStream();
  late FocusNode pageFocusNode;
  late FocusNode _textFocusNode;
  late final List<String> tags;
  final List<String> addedTags = List.empty(growable: true);
  final List<String> removedTags = List.empty(growable: true);
  late final ITagService _tagService;

  List<TagCount> editedTags = List<TagCount>.empty(growable: true);

  @override
  void initState() {
    super.initState();

    _tagService = getIt.get<ITagService>();

    pageFocusNode = FocusNode();

    tags = List.from(widget.image.tags, growable: true);

    _updateTagCounts();
  }

  @override
  void dispose() {
    pageFocusNode.dispose();
    _textFocusNode.dispose();

    super.dispose();
  }

  /// Update tag counts in the UI
  _updateTagCounts() => _tagCountStreamController.add(tags.map((t) => TagCount(t, 1)).toList());

  onTagSubmitted(String tag) {
    final tag = _tagTextController.value.text;

    _tagTextController.clear();

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

  onTagSelected(String tag) {
    final tag = _tagTextController.value.text;

    _tagTextController.clear();

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
        actions: <Type, Action<Intent>>{SaveTagsIntent: SaveTagsAction(widget.image, tags, onTagsSaved), BackIntent: BackAction(context)},
        child: Focus(
          autofocus: true,
          focusNode: pageFocusNode,
          onFocusChange: (hasFocus) {
            if (!hasFocus) pageFocusNode.requestFocus();
          },
          child: Listener(
            onPointerUp: (e) {
              if (e.buttons & kBackMouseButton == kBackMouseButton) {
                Actions.handler(context, BackIntent());
              }
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Autocomplete<String>(
                    fieldViewBuilder: (context, fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                      _tagTextController = fieldTextEditingController;
                      _textFocusNode = fieldFocusNode;

                      return TextField(
                        focusNode: _textFocusNode,
                        controller: _tagTextController,
                        onSubmitted: onTagSubmitted,
                      );
                    },
                    optionsBuilder: (v) => _tagService.suggestedTags(v.text),
                    onSelected: onTagSelected,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          flex: 8,
                          child: Center(
                              child: Image.file(
                            File(widget.image.path),
                            fit: BoxFit.fitHeight,
                          ))),
                      Flexible(
                          flex: 2,
                          child: TagSidebar(
                            stream: _tagCountStream,
                            excludedTags: removedTags,
                            includedTags: addedTags,
                          ))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
