import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_tagger/utils/collection_utils.dart';

class TagAutocomplete extends StatefulWidget {
  final FutureOr<bool> Function(String)? onTagSelected;
  final Function(FocusNode)? onFocusNodeUpdated;
  final Iterable<String> Function(String) suggestionSearch;
  final String? hintText;
  final bool autoRefocus;

  const TagAutocomplete({super.key, this.onTagSelected, this.onFocusNodeUpdated, required this.suggestionSearch, this.hintText, this.autoRefocus = true});

  @override
  State<StatefulWidget> createState() => _TagAutocompleteState();
}

class _TagAutocompleteState extends State<TagAutocomplete> {
  late TextEditingController _tagTextController;
  bool _hasSuggestions = false;
  FocusNode? _textFocus;

  _onTagSelected(String tag) async {
    final trimmed = tag.trim();

    if (trimmed.isNotEmpty) {
      final result = await widget.onTagSelected?.call(trimmed);

      if (result ?? false) {
        _tagTextController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      fieldViewBuilder: (context, fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
        _tagTextController = fieldTextEditingController;
        _textFocus = fieldFocusNode;

        final field = TextField(
          focusNode: fieldFocusNode,
          controller: _tagTextController,
          decoration: InputDecoration(hintText: widget.hintText),
          onSubmitted: (s) {
            if (_hasSuggestions &&
                !HardwareKeyboard.instance.logicalKeysPressed
                    .containsAny([LogicalKeyboardKey.control, LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight])) {
              onFieldSubmitted();
            } else {
              _onTagSelected(s);
            }

            if (widget.autoRefocus && _textFocus != null) {
              _textFocus!.requestFocus();
            }
          },
        );

        widget.onFocusNodeUpdated?.call(fieldFocusNode);

        return field;
      },
      optionsBuilder: (v) {
        final suggested = widget.suggestionSearch(v.text).toList(growable: false);

        _hasSuggestions = suggested.isNotEmpty;

        return suggested;
      },
      onSelected: (s) => _onTagSelected(s),
    );
  }
}
