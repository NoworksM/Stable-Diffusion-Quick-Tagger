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
      Flexible(
        child: Row(
          children: [
            Flexible(
              child: TextFormField(
                enabled: false,
                initialValue: folder,
                decoration: const InputDecoration(labelText: 'Path'),
              ),
            ),
            Flexible(
              child: ElevatedButton(
                onPressed: selectFolder,
                child: const Text('Select Folder'),
              ),
            ),
          ],
        ),
      ),
      Flexible(
        child: CheckboxListTile(
          value: autoSaveTags,
          onChanged: (v) => onAutoSaveTagsChanged?.call(v),
        ),
      ),
      Flexible(
        child: DropdownButtonFormField<TagSeparator>(
          decoration: const InputDecoration(labelText: 'Tagfile Format'),
          value: tagSeparator,
          onChanged: (t) => onTagSeparatorChanged?.call(t),
          items: TagSeparator.values
              .map((t) => DropdownMenuItem<TagSeparator>(
            value: t,
            child: Text(t.userFriendly()),
          ))
              .toList(),
        ),
      ),
      Flexible(
          child: DropdownButtonFormField<TagSpaceCharacter>(
        decoration: const InputDecoration(labelText: 'Tagfile Format'),
        value: tagSpaceCharacter,
        onChanged: (t) => onTagSpaceCharacterChanged?.call(t),
        items: TagSpaceCharacter.values
            .map((t) => DropdownMenuItem<TagSpaceCharacter>(
                  value: t,
                  child: Text(t.userFriendly()),
                ))
            .toList(),
      ))
    ]);
  }
}
