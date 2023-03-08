import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/pages/tag_editor.dart';

class TagEditorPage extends StatelessWidget {
  final int initialIndex;
  final List<TaggedImage> images;

  const TagEditorPage({super.key, required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text('Edit: ${p.basename(images[initialIndex].path)}')
        ),
        body: TagEditor(images: images, initialIndex: initialIndex),
    );
  }
}
