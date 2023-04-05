import 'dart:collection';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:quick_tagger/data/edit.dart';

class Snapshot {
  final DateTime createdAt;
  final UnmodifiableMapView<Digest, UnmodifiableListView<Edit>> edits;
  final UnmodifiableMapView<Digest, String> imagePaths;
  final UnmodifiableSetView<Digest> addedHashes;

  Snapshot(this.edits, this.imagePaths, this.addedHashes, this.createdAt);

  Snapshot.now(this.edits, this.imagePaths, this.addedHashes)
    : createdAt = DateTime.now();

  Snapshot.fromJson(Map<String, dynamic> json)
    : edits = UnmodifiableMapView(Map<Digest, UnmodifiableListView<Edit>>.fromEntries(
        json['edits'].map((e) => MapEntry(Digest(hex.decode(e['hash'])), UnmodifiableListView(List<Edit>.from(e['edits'].map((e) => Edit.fromJson(e)))))))),
      imagePaths = UnmodifiableMapView(Map<Digest, String>.fromEntries(
        json['imagePaths'].map((e) => MapEntry(Digest(hex.decode(e['hash'])), e['path'])))),
      addedHashes = UnmodifiableSetView(HashSet<Digest>.from(json['addedHashes'].map((e) => Digest(hex.decode(e))))),
      createdAt = DateTime.parse(json['createdAt']);

  Map<String, dynamic> toJson() {
    return {
      'edits': edits.entries.map((e) => {
        'hash': e.key.toString(),
        'edits': e.value.map((e) => e.toJson()).toList(),
      }).toList(),
      'imagePaths': imagePaths.entries.map((e) => {
        'hash': e.key.toString(),
        'path': e.value,
      }).toList(),
      'addedHashes': addedHashes.map((e) => e.toString()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}