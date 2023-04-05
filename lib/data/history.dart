import 'dart:collection';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:quick_tagger/data/snapshot.dart';

class History {
  final HashSet<Digest> _images;
  final List<Snapshot> _snapshots;

  History(this._images, this._snapshots);

  addSnapshot(Snapshot snapshot) {
    _snapshots.insert(0, snapshot);
  }

  History.fromJson(Map<String, dynamic> json)
      : _images = HashSet<Digest>.from(json['images'].map((e) => Digest(hex.decode(e)))),
        _snapshots = List<Snapshot>.from(json['snapshots'].map((e) => Snapshot.fromJson(e)));
  
  Map<String, dynamic> toJson() {
    return {
      'images': _images.map((e) => e.toString()).toList(),
      'snapshots': _snapshots.map((e) => e.toJson()).toList(),
    };
  }
}