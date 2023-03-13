import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 4.0, right: 4.0, bottom: 8.0),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const Divider()
        ]
      ),
    );
  }
}