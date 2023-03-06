import 'package:flutter/material.dart';

class ImageCountFooter extends StatelessWidget {
  final int images;
  final int filtered;
  final int selected;
  final int filteredTags;

  const ImageCountFooter({super.key, required this.images, required this.filtered, required this.selected, required this.filteredTags});

  @override
  Widget build(BuildContext context) {
    late final Widget textDisplay;
    if (filtered != images) {
      if (selected != filtered) {
        textDisplay = Text('$selected Selected Out of $filtered Filtered Images');
      } else {
        textDisplay = Text('$filtered Images Filtering on $filteredTags Tag${filteredTags > 1 ? 's' : ''}');
      }
    } else if (selected > 0 && selected != images) {
      textDisplay = Text('$selected Selected Out of $images Images');
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
              child: Text('${selected != images && selected != filtered ? selected : 0}/${filtered != images ? filtered : 0}/$images'))
        )
      ],
    );
  }
}
