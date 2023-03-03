import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quick_tagger/components/tag_autocomplete.dart';
import 'package:quick_tagger/components/tag_sidebar.dart';
import 'package:quick_tagger/data/edit.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tagfile_type.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/components/gallery.dart';
import 'package:quick_tagger/pages/options.dart';
import 'package:quick_tagger/services/gallery_service.dart';
import 'package:quick_tagger/utils/functional_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  configureDependencies();
  runApp(const MyApp());
}

const prefLastPath = "gallery.last_path";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Tagger',
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      home: const HomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TagSeparator tagSeparator = TagSeparator.lineBreak;
  TagSpaceCharacter tagSpaceCharacter = TagSpaceCharacter.space;
  String? folder;
  bool autoSaveTags = true;
  List<TaggedImage> _images = List.empty();
  final StreamController<List<TaggedImage>> _imageStreamController = StreamController();
  late final Stream<List<TaggedImage>> _imageStream = _imageStreamController.stream.asBroadcastStream();
  final StreamController<List<TagCount>> _tagCountStreamController = StreamController();
  late final Stream<List<TagCount>> _tagCountStream = _tagCountStreamController.stream.asBroadcastStream();
  String? hoveredTag;
  HashSet<String> includedTags = HashSet<String>.identity();
  HashSet<String> excludedTags = HashSet<String>.identity();
  final HashMap<String, HashSet<Edit>> pendingEdits = HashMap<String, HashSet<Edit>>();
  late final IGalleryService _galleryService;
  late final SharedPreferences _preferences;

  onPathChanged(path, {bool savePath = true}) async {
    setState(() {
      folder = path;
      includedTags.clear();
      excludedTags.clear();
    });

    if (savePath) {
      await _preferences.setString(prefLastPath, path);
    }

    await _galleryService.loadImages(path);
  }

  List<TaggedImage> get filteredImages {
    final filteredImages = List<TaggedImage>.empty(growable: true);

    for (final image in _images) {
      final set = image.tags.toSet();

      bool hasExcluded = false;

      for (final excluded in excludedTags) {
        if (set.contains(excluded)) {
          hasExcluded = true;
          break;
        }
      }

      if (hasExcluded) {
        continue;
      }

      if (set.containsAll(includedTags)) {
        filteredImages.add(image);
      }
    }

    return filteredImages;
  }

  List<TagCount> get filteredTagCounts {
    final tagCounts = List<TagCount>.empty(growable: true);

    for (final image in filteredImages) {
      for (final tag in image.tags) {
        bool isFilteredTag = false;

        for (final included in includedTags) {
          if (included == tag) {
            isFilteredTag = true;
            break;
          }
        }

        if (isFilteredTag) {
          continue;
        }

        for (final excluded in excludedTags) {
          if (excluded == tag) {
            isFilteredTag = true;
            break;
          }
        }

        if (isFilteredTag) {
          continue;
        }

        final tagCount = tagCounts.firstWhere((tc) => tc.tag == tag, orElse: () => TagCount(tag, 0));

        if (tagCount.count == 0) {
          tagCounts.add(tagCount);
        }

        tagCount.count++;
      }
    }

    return tagCounts;
  }

  _onIncludedTagSelected(String tag) {
    setState(() {
      if (includedTags.contains(tag)) {
        includedTags.remove(tag);
      } else {
        includedTags.add(tag);
      }
    });
    setState(() {
      _imageStreamController.add(filteredImages);
      _tagCountStreamController.add(filteredTagCounts);
    });
  }

  _onExcludedTagSelected(String tag) {
    setState(() {
      if (excludedTags.contains(tag)) {
        excludedTags.remove(tag);
      } else {
        excludedTags.add(tag);
      }
    });
    setState(() {
      _imageStreamController.add(filteredImages);
      _tagCountStreamController.add(filteredTagCounts);
    });
  }

  /// Callback for when a tag is added or removed from the selected images
  FutureOr<bool> _onTagSelected(String tag) async {
    final editingImages = filteredImages;

    int hasCount = 0;

    for (final image in editingImages) {
      if (image.tags.contains(tag) || (pendingEdits[image.path]?.contains(Edit(tag, EditType.add)) ?? false)) {
        hasCount++;
      }
    }

    EditType editType;

    if (hasCount != editingImages.length && hasCount != 0) {
      final add = await showDialog<bool>(context: context, builder: _buildMixedTagEditDialog(tag, hasCount, editingImages.length));

      if (add == null) {
        return false;
      }

      editType = add ? EditType.add : EditType.remove;
    } else if (hasCount == 0) {
      editType = EditType.add;
    } else {
      editType = EditType.remove;
    }

    setState(() {
      for (final image in editingImages) {
        bool hasTag = image.tags.contains(tag);
        bool hasEdit = pendingEdits[image.path]?.contains(Edit(tag, editType)) ?? false;
        bool hasInvertedEdit = pendingEdits[image.path]?.contains(Edit(tag, editType.invert())) ?? false;

        if (hasEdit) {
          continue;
        }

        if (hasInvertedEdit) {
          pendingEdits[image.path]!.remove(Edit(tag, editType.invert()));
        } else if (hasTag && editType == EditType.remove || !hasTag && editType == EditType.add) {
          final edits = pendingEdits.putIfAbsent(image.path, () => HashSet<Edit>());

          edits.add(Edit(tag, editType));
          edits.remove(Edit(tag, editType.invert()));
        }
      }
    });

    return true;
  }

  _buildMixedTagEditDialog(String tag, int hasCount, int total) {
    return (BuildContext context) {
      return AlertDialog(
          title: const Text('Mixed Tags'),
          content: SingleChildScrollView(
              child: ListBody(children: [
            Text('The selected $total images do not uniformly contain or lack the tag "$tag".'),
            Text('$hasCount images have are tagged with "$tag"'),
            Text('${total - hasCount} images are not tagged with "$tag"'),
            Container(margin: const EdgeInsetsDirectional.only(top: 8.0), child: Text('Would you like to add or remove "$tag" to the selected $total images?'))
          ])),
          actions: [
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            ElevatedButton(
              child: const Text('Remove'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ]);
    };
  }

  @override
  void initState() {
    super.initState();
    _galleryService = getIt.get<IGalleryService>();

    _galleryService.galleryStream.listen((images) {
      setState(() {
        _images = images;
        _imageStreamController.add(filteredImages);
        _tagCountStreamController.add(filteredTagCounts);
      });
    });

    getIt.getAsync<SharedPreferences>().then((p) {
      _preferences = p;

      if (_preferences.containsKey(prefLastPath)) {
        onPathChanged(_preferences.getString(prefLastPath));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Row(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Options(
                  tagSeparator: tagSeparator,
                  tagSpaceCharacter: tagSpaceCharacter,
                  autoSaveTags: autoSaveTags,
                  folder: folder,
                  onFolderChanged: onPathChanged,
                  onTagSeparatorChanged: (val) => setState(() {
                    tagSeparator = val ?? tagSeparator;
                  }),
                  onTagSpaceCharacterChanged: (val) => setState(() {
                    tagSpaceCharacter = val ?? tagSpaceCharacter;
                  }),
                  onAutoSaveTagsChanged: (val) => setState(() {
                    autoSaveTags = val ?? autoSaveTags;
                  }),
                ),
              ),
            ),
            Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsetsDirectional.symmetric(vertical: 8.0),
                        child: TagAutocomplete(
                          onTagSelected: _onTagSelected,
                        ),
                      ),
                      Expanded(
                        child: Gallery(
                          stream: _imageStream,
                          hoveredTag: hoveredTag,
                        ),
                      ),
                    ],
                  ),
                )),
            Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TagSidebar(
                    stream: _tagCountStream,
                    imageCount: filteredImages.length,
                    includedTags: includedTags.toList(),
                    excludedTags: excludedTags.toList(),
                    pendingEdits: pendingEdits.values.flatten().toList(growable: false),
                    onTagHover: (t) => setState(() {
                      hoveredTag = t;
                    }),
                    onIncludedTagSelected: _onIncludedTagSelected,
                    onExcludedTagSelected: _onExcludedTagSelected,
                  ),
                ))
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
