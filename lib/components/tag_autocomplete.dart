import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/services/tag_service.dart';

class TagAutocomplete extends StatefulWidget {
  final FutureOr<bool> Function(String)? onTagSelected;
  final Function(FocusNode)? onFocusNodeUpdated;

  const TagAutocomplete({super.key, this.onTagSelected, this.onFocusNodeUpdated});

  @override
  State<StatefulWidget> createState() => _TagAutocompleteState();
}

class _TagAutocompleteState extends State<TagAutocomplete> {
  final ITagService _tagService;
  late TextEditingController _tagTextController;
  bool _hasSuggestions = false;

  _TagAutocompleteState()
    : _tagService = getIt.get<ITagService>();

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
        final suggested = _tagService.suggestedTags(v.text).toList(growable: false);

        _hasSuggestions = suggested.isNotEmpty;

        return suggested;
      },
      onSelected: (s) => _onTagSelected(s),
    );
  }

}