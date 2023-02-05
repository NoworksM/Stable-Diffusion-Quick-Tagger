import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
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

  List<TagCount> editedTags = List<TagCount>.empty(growable: true);


  @override
  void initState() {
    super.initState();

    _tagCountStreamController.add(widget.image.tags.map((t) => TagCount(t, 1)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    stream: _tagCountStreamController.stream.asBroadcastStream(),
                    excludedTags: const [],
                    includedTags: const [],
                  ))
            ],
          ),
        ),
      ],
    );
  }
}
