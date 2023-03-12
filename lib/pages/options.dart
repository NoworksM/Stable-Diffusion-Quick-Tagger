import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/tagfile_type.dart';

class Options extends StatelessWidget {
  final TagSpaceCharacter tagSpaceCharacter;
  final TagSeparator tagSeparator;
  final String? folder;
  final Function(String)? onFolderChanged;
  final Function(TagSpaceCharacter?)? onTagSpaceCharacterChanged;
  final Function(TagSeparator?)? onTagSeparatorChanged;
  final Function(bool?)? onAutoSaveTagsChanged;
  final bool autoSaveTags;

  const Options(
      {super.key,
      required this.tagSpaceCharacter,
      required this.tagSeparator,
      required this.autoSaveTags,
      this.folder,
      this.onFolderChanged,
      this.onTagSpaceCharacterChanged,
      this.onTagSeparatorChanged,
      this.onAutoSaveTagsChanged});

  Future<void> selectFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      onFolderChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Tooltip(
                  message: folder,
                  child: TextFormField(
                    enabled: false,
                    initialValue: folder,
                    decoration: const InputDecoration(labelText: 'Path'),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selectFolder,
              child: const Text('Select Folder'),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: CheckboxListTile(
          title: const Text('Auto Save Tags'),
          value: autoSaveTags,
          onChanged: (v) => onAutoSaveTagsChanged?.call(v),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: DropdownButtonFormField<TagSeparator>(
          decoration: const InputDecoration(labelText: 'Tag Separator'),
          value: tagSeparator,
          onChanged: (t) => onTagSeparatorChanged?.call(t),
          items: TagSeparator.values
              .map((t) => DropdownMenuItem<TagSeparator>(
                    value: t,
                    child: Text(t.userFriendly),
                  ))
              .toList(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: DropdownButtonFormField<TagSpaceCharacter>(
          decoration: const InputDecoration(labelText: 'Tag Space Character'),
          value: tagSpaceCharacter,
          onChanged: (t) => onTagSpaceCharacterChanged?.call(t),
          items: TagSpaceCharacter.values
              .map((t) => DropdownMenuItem<TagSpaceCharacter>(
                    value: t,
                    child: Text(t.userFriendly),
                  ))
              .toList(),
        ),
      ),
    ]);
  }
}
