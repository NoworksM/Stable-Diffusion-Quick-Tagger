import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/tagfile_type.dart';

class Options extends StatelessWidget {
  final TagfileType tagfileType;
  final String? folder;
  final Function(String)? onFolderChanged;

  const Options({super.key, required this.tagfileType, this.folder, this.onFolderChanged});

  Future<void> selectFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      onFolderChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          enabled: false,
          initialValue: folder,
          decoration: const InputDecoration(
            labelText: 'Path'
          ),
        ),
        ElevatedButton(
          onPressed: selectFolder,
          child: const Text('Select Folder'),
        )
      ]
    );
  }
}