import 'package:flutter/material.dart';
import 'package:quick_tagger/components/section_header.dart';

class UtilitiesSection extends StatelessWidget {
  const UtilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SectionHeader(title: 'Utilities'),
        ActionRow(text: 'Convert Tag File Formats', buttonText: 'Convert'),
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
