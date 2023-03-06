import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlobalShortcutListener {
  final HashMap<ShortcutActivator, Function()> _activators;

  GlobalShortcutListener(this._activators);

  void onKeyEvent(RawKeyEvent event) {
    for (final activator in _activators.keys) {
      if (activator.accepts(event, RawKeyboard.instance)) {
        _activators[activator]?.call();
      }
    }
  }

  void suspend() {
    RawKeyboard.instance.removeListener(onKeyEvent);
  }

  void resume() {
    RawKeyboard.instance.addListener(onKeyEvent);
  }

  void dispose() {
    RawKeyboard.instance.removeListener(onKeyEvent);
  }
}