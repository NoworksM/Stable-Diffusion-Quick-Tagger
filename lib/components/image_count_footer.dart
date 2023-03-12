import 'package:flutter/material.dart';

class ImageCountFooter extends StatelessWidget {
  final int images;
  final int filtered;
  final int selected;
  final int filteredTags;
  final int totalTags;
  final Function()? onClearSelection;

  const ImageCountFooter(
      {super.key,
      required this.images,
      required this.filtered,
      required this.selected,
      required this.filteredTags,
      required this.totalTags,
      this.onClearSelection});

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
            child: Text(
              '$selected Selected out of $images Images',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    } else {
      textDisplay = Text(
        '$images Images',
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      );
    }

    return Row(
      children: [
        Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$images/${filtered != images ? filtered : 0}/${selected != images && selected != filtered ? selected : 0}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            )),
        Expanded(
          flex: 5,
          child: Center(child: textDisplay),
        ),
        Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                children: [
                  const Spacer(),
                  const Icon(Icons.sell),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(totalTags.toString(), style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
