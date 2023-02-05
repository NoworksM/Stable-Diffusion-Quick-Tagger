import 'package:flutter/material.dart';

class BackAction extends Action<BackIntent> {
  final BuildContext context;

  BackAction(this.context);

  @override
  Object? invoke(BackIntent intent) {
    Navigator.pop(context);
    return null;
  }

}

class BackIntent extends Intent {

}