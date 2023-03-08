import 'dart:async';

import 'package:flutter/material.dart';

class TagAutocomplete extends StatefulWidget {
  final FutureOr<bool> Function(String)? onTagSelected;
  final Function(FocusNode)? onFocusNodeUpdated;
  final Iterable<String> Function(String) suggestionSearch;

  const TagAutocomplete({super.key, this.onTagSelected, this.onFocusNodeUpdated, required this.suggestionSearch});

  @override
  State<StatefulWidget> createState() => _TagAutocompleteState();
}

class _TagAutocompleteState extends State<TagAutocomplete> {
  late TextEditingController _tagTextController;
  bool _hasSuggestions = false;

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

        final field = TextField(
          focusNode: fieldFocusNode,
          controller: _tagTextController,
          onSubmitted: (s) {
            if (_hasSuggestions) {
              onFieldSubmitted();
            } else {
              _onTagSelected(s);
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