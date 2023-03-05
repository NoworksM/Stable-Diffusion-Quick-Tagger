import 'package:flutter/material.dart';

class TagSectionHeader extends StatelessWidget {
  final String title;

  const TagSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title),
        const Divider()
      ],
    );
  }
}