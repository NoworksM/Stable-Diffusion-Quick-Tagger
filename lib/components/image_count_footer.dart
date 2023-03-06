import 'package:flutter/material.dart';

class ImageCountFooter extends StatelessWidget {
  final int images;
  final int filtered;
  final int selected;
  final int filteredTags;
  final Function()? onClearSelection;

  const ImageCountFooter({super.key, required this.images, required this.filtered, required this.selected, required this.filteredTags, this.onClearSelection});

  @override
  Widget build(BuildContext context) {
    late final Widget textDisplay;
    if (filtered != images) {
      if (selected != filtered) {
        textDisplay = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => onClearSelection?.call(),
              child: const Text('Clear Selection'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('$selected Selected out of $filtered Filtered Images'),
            ),
          ],
        );
      } else {
        textDisplay = Text('$filtered Images Filtering on $filteredTags Tag${filteredTags > 1 ? 's' : ''}');
      }
    } else if (selected > 0 && selected != images) {
      textDisplay = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => onClearSelection?.call(),
            child: const Text('Clear Selection'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text('$selected Selected out of $images Images'),
          ),
        ],
      );
    } else {
      textDisplay = Text('$images Images');
    }

    return Row(
      children: [
        const Spacer(flex: 1),
        Expanded(
          flex: 5,
          child: Center(child: textDisplay),
        ),
        Flexible(
            flex: 1,
            child: Align(
                alignment: Alignment.centerRight,
                child: Text('${selected != images && selected != filtered ? selected : 0}/${filtered != images ? filtered : 0}/$images')))
      ],
    );
  }
}
