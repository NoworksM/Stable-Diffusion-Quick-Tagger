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

class TagEditor extends StatefulWidget {
  final TaggedImage image;

  const TagEditor({super.key, required this.image});

  @override
  State<StatefulWidget> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  final StreamController<List<TagCount>> _tagCountStreamController =
      StreamController();
  final TextEditingController textController = TextEditingController();
  late final Stream<List<TagCount>> _tagCountStream =
      _tagCountStreamController.stream.asBroadcastStream();
  late FocusNode pageFocusNode;

  List<TagCount> editedTags = List<TagCount>.empty(growable: true);

  _save() {}

  @override
  void initState() {
    super.initState();

    pageFocusNode = FocusNode();

    _tagCountStreamController
        .add(widget.image.tags.map((t) => TagCount(t, 1)).toList());
  }

  @override
  void dispose() {
    pageFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            SaveTagsIntent(),
        const SingleActivator(LogicalKeyboardKey.goBack): BackIntent()
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveTagsIntent: SaveTagsAction(),
          BackIntent: BackAction(context)
        },
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
                            excludedTags: const [],
                            includedTags: const [],
                          ))
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(controller: textController),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
