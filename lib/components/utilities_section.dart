import 'package:flutter/material.dart';
import 'package:quick_tagger/components/section_header.dart';
import 'package:quick_tagger/data/tagfile_type.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/services/gallery_service.dart';

class UtilitiesSection extends StatelessWidget {
  final TagSpaceCharacter spaceCharacter;
  final TagSeparator separator;
  final TagPathFormat tagPathFormat;
  final IGalleryService _galleryService;

  UtilitiesSection({super.key, required this.spaceCharacter, required this.separator, required this.tagPathFormat})
    : _galleryService = getIt.get<IGalleryService>();


  _confirmTagConversion(BuildContext context) {
      return () async {
        final result = await showDialog<bool>(context: context, builder: (context) {
          return AlertDialog(
              title: const Text('Mixed Tags'),
              content: SingleChildScrollView(
                  child: Text('Are you sure you want to convert all tag files to ${spaceCharacter.userFriendly} ${separator.userFriendly} ${tagPathFormat.userFriendly}? This action cannot be reversed.')),
              actions: [
                ElevatedButton(
                  child: const Text('Yes'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                ElevatedButton(
                  child: const Text('No'),
                  onPressed: () => Navigator.of(context).pop(false),
                )
              ]);
        });

        if (result ?? false) {
          await _convertTags();
        }
      };
  }

  _convertTags() async {
    await _galleryService.convertTagFiles(separator, spaceCharacter, tagPathFormat);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: 'Utilities'),
        ActionRow(text: 'Convert Tag File Formats', buttonText: 'Convert', action: _confirmTagConversion(context)),
      ],
    );
  }
}

class ActionRow extends StatelessWidget {
  final String text;
  final String buttonText;
  final Function()? action;

  const ActionRow({super.key, required this.text, this.action, required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(
        text,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const Spacer(),
      ElevatedButton(onPressed: action, child: Text(buttonText))
    ]);
  }
}
