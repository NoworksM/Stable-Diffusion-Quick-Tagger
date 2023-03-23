import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quick_tagger/components/tag_autocomplete.dart';
import 'package:quick_tagger/components/tag_sidebar.dart';
import 'package:quick_tagger/data/directory_info.dart';
import 'package:quick_tagger/data/edit.dart';
import 'package:quick_tagger/data/gallery_tab.dart';
import 'package:quick_tagger/data/tag_count.dart';
import 'package:quick_tagger/data/tagfile_type.dart';
import 'package:quick_tagger/data/tagged_image.dart';
import 'package:quick_tagger/ioc.dart';
import 'package:quick_tagger/pages/options.dart';
import 'package:quick_tagger/services/gallery_service.dart';
import 'package:quick_tagger/services/tag_service.dart';
import 'package:quick_tagger/utils/functional_utils.dart';
import 'package:quick_tagger/utils/tag_utils.dart' as tag_utils;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  configureDependencies();

  initTags();

  runApp(const MyApp());
}

void initTags() {
  final lines = File('tags.txt').readAsLinesSync();

  final tags = HashSet<String>.from(lines);

  final tagService = getIt.get<ITagService>();

  tagService.replaceGlobalTags(tags.toList(growable: false));
}

const prefLastPath = 'gallery.last_path';

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
      home: const HomePage(title: 'Quick Tagger'),
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
  TagPathFormat tagPathFormat = TagPathFormat.replaceExtension;
  String? folder;
  bool autoSaveTags = false;
  List<TaggedImage> _images = List.empty();
  final StreamController<List<TaggedImage>> _imageStreamController = StreamController();
  late final Stream<List<TaggedImage>> _imageStream = _imageStreamController.stream.asBroadcastStream();
  final StreamController<List<TagCount>> _tagCountStreamController = StreamController();
  late final Stream<List<TagCount>> _tagCountStream = _tagCountStreamController.stream.asBroadcastStream();
  String? hoveredTag;
  HashSet<String> includedTags = HashSet<String>.identity();
  HashSet<String> excludedTags = HashSet<String>.identity();
  late final IGalleryService _galleryService;
  late final ITagService _tagService;
  late final SharedPreferences _preferences;
  late final FocusNode _pageFocusNode;
  final Set<String> _selectedImagePaths = HashSet<String>();

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

  List<TaggedImage> get filteredImages => tag_utils.filterImagesForTagsAndEdits(_images, _galleryService.pendingEdits, includedTags, excludedTags);

  List<TaggedImage> get selectedImages {
    if (_selectedImagePaths.isEmpty) {
      return filteredImages;
    }

    final images = List<TaggedImage>.empty(growable: true);

    for (final image in filteredImages) {
      if (_selectedImagePaths.contains(image.path)) {
        images.add(image);
      }
    }

    return images;
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
    final pendingEdits = _galleryService.pendingEdits;
    final editingImages = selectedImages;
    final added = List<FilePendingEdit>.empty(growable: true);
    final removed = List<FilePendingEdit>.empty(growable: true);

    int hasCount = 0;
    int addedCount = 0;
    int removedCount = 0;
    bool anyWithoutTag = false;
    bool anyWithTag = false;
    bool anyHasAdded = false;
    bool anyHasRemoved = false;

    for (final image in editingImages) {
      final hasTag = image.tags.contains(tag);
      final hasAdded = pendingEdits[image.path]?.contains(Edit(tag, EditType.add)) ?? false;
      final hasRemoved = pendingEdits[image.path]?.contains(Edit(tag, EditType.remove)) ?? false;

      if (hasAdded) {
        anyHasAdded = true;
        addedCount++;
      }

      if (hasRemoved) {
        anyHasRemoved = true;
        removedCount++;
      }

      if (hasTag) {
        hasCount++;
      }

      if ((hasTag || hasAdded) && !hasRemoved) {
        anyWithTag = true;
      }
      if ((!hasTag || hasRemoved) && !hasAdded) {
        anyWithoutTag = true;
      }
    }

    EditType editType;

    if (anyHasAdded || anyHasRemoved) {
      if (anyHasAdded && anyHasRemoved) {
        final add = await showDialog<bool>(context: context, builder: _buildMixedEditsDialogBuilder(tag, addedCount, removedCount));

        if (add == null) {
          return false;
        }

        for (final pair in pendingEdits.entries) {
          final path = pair.key;
          // final edit = pair.value;

          if (add) {
            removed.add(MapEntry(path, Edit(tag, EditType.add.invert())));
          } else {
            removed.add(MapEntry(path, Edit(tag, EditType.remove.invert())));
          }
        }

        _galleryService.queueFileEdits(added);
        _galleryService.dequeueFileEdits(removed);

        return true;
      } else if (anyHasAdded) {
        final removeOnly =
            await showDialog<bool>(context: context, builder: _buildPendingEditsDialogBuilder(tag, addedCount, hasCount, editingImages.length, true));

        if (removeOnly == null) {
          return false;
        }

        final existingEdit = Edit(tag, EditType.add);

        for (final image in editingImages) {
          removed.add(MapEntry(image.path, existingEdit));

          if (!removeOnly && image.tags.contains(tag)) {
            added.add(MapEntry(image.path, Edit(tag, EditType.remove)));
          }
        }

        _galleryService.queueFileEdits(added);
        _galleryService.dequeueFileEdits(removed);

        return true;
      } else {
        final addOnly =
            await showDialog<bool>(context: context, builder: _buildPendingEditsDialogBuilder(tag, removedCount, hasCount, editingImages.length, false));

        if (addOnly == null) {
          return false;
        }

        final existingEdit = Edit(tag, EditType.remove);

        for (final image in editingImages) {
          removed.add(MapEntry(image.path, existingEdit));

          if (!addOnly && !image.tags.contains(tag)) {
            added.add(MapEntry(image.path, Edit(tag, EditType.add)));
          }
        }

        _galleryService.queueFileEdits(added);
        _galleryService.dequeueFileEdits(removed);

        return true;
      }
    }

    if (anyWithTag && anyWithoutTag) {
      // ignore: use_build_context_synchronously
      final add = await showDialog<bool>(context: context, builder: _buildMixedTagEditDialogBuilder(tag, hasCount + addedCount, editingImages.length));

      if (add == null) {
        return false;
      }

      editType = add ? EditType.add : EditType.remove;
    } else if (!anyWithTag) {
      editType = EditType.add;
    } else {
      editType = EditType.remove;
    }

    for (final image in editingImages) {
      bool hasTag = image.tags.contains(tag);
      bool hasEdit = pendingEdits[image.path]?.contains(Edit(tag, editType)) ?? false;
      bool hasInvertedEdit = pendingEdits[image.path]?.contains(Edit(tag, editType.invert())) ?? false;

      if (hasEdit) {
        continue;
      }

      if (hasInvertedEdit) {
        removed.add(MapEntry(image.path, Edit(tag, editType.invert())));
      } else if (hasTag && editType == EditType.remove || !hasTag && editType == EditType.add) {
        added.add(MapEntry(image.path, Edit(tag, editType)));
        removed.add(MapEntry(image.path, Edit(tag, editType.invert())));
      }
    }

    _galleryService.queueFileEdits(added);
    _galleryService.dequeueFileEdits(removed);

    _imageStreamController.add(filteredImages);

    return true;
  }

  _buildMixedTagEditDialogBuilder(String tag, int hasCount, int total) {
    return (BuildContext context) {
      return AlertDialog(
          title: const Text('Mixed Tags'),
          content: SingleChildScrollView(
              child: ListBody(children: [
            Text('The selected $total images do not uniformly contain or lack the tag "$tag".'),
            Text('$hasCount images are tagged with "$tag"'),
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

  _buildMixedEditsDialogBuilder(String tag, int addedCount, int removedCount) {
    return (BuildContext context) {
      return AlertDialog(
          title: const Text('Pending Edits'),
          content: SingleChildScrollView(
              child: ListBody(children: [
            Text('The tag "$tag" is currently pending being added to $addedCount images and removed from $removedCount images'),
            Container(
                margin: const EdgeInsetsDirectional.only(top: 8.0),
                child: Text('Would you like to remove "$tag" from the pending edits or add it to the pending removals?'))
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

  _buildPendingEditsDialogBuilder(String tag, int editCount, int existingCount, int total, bool adding) {
    return (BuildContext context) {
      return AlertDialog(
          title: const Text('Pending Edits'),
          content: SingleChildScrollView(
              child: ListBody(children: [
            Text('The tag "$tag" is currently pending being ${adding ? 'added to' : 'removed from'} $editCount images'),
            Container(
                margin: const EdgeInsetsDirectional.only(top: 8.0),
                child: Text('Would you like to ${adding ? 'remove' : 'add'} "$tag" pending edits or to all $total images?'))
          ])),
          actions: [
            ElevatedButton(
              child: const Text('All'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Pending'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ]);
    };
  }

  _saveChanges() async {
    await _galleryService.savePendingChanges();
  }

  _onRemoveTagSelected(String tag) {
    final pendingEdits = _galleryService.pendingEdits;

    final added = List<FilePendingEdit>.empty(growable: true);
    final removed = List<FilePendingEdit>.empty(growable: true);

    final addEdit = Edit(tag, EditType.add);
    final removeEdit = Edit(tag, EditType.remove);

    for (final image in selectedImages) {
      final imageEdits = pendingEdits[image.path] ?? UnmodifiableSetView(HashSet<Edit>());

      final hasAdded = imageEdits.contains(addEdit);
      final hasRemoved = imageEdits.contains(removeEdit);

      if (hasAdded) {
        removed.add(MapEntry(image.path, addEdit));
      } else if (!hasRemoved && image.tags.contains(tag)) {
        added.add(MapEntry(image.path, removeEdit));
      }
    }

    _galleryService.queueFileEdits(added);
    _galleryService.dequeueFileEdits(removed);
  }

  _onAddTagSelected(String tag) {
    final pendingEdits = _galleryService.pendingEdits;

    final added = List<FilePendingEdit>.empty(growable: true);
    final removed = List<FilePendingEdit>.empty(growable: true);

    final addEdit = Edit(tag, EditType.add);
    final removeEdit = Edit(tag, EditType.remove);

    for (final image in selectedImages) {
      final imageEdits = pendingEdits[image.path] ?? UnmodifiableSetView(HashSet<Edit>());

      final hasAdded = imageEdits.contains(addEdit);
      final hasRemoved = imageEdits.contains(removeEdit);

      if (hasRemoved) {
        removed.add(MapEntry(image.path, removeEdit));
      } else if (!hasAdded && !image.tags.contains(tag)) {
        added.add(MapEntry(image.path, addEdit));
      }
    }

    _galleryService.queueFileEdits(added);
    _galleryService.dequeueFileEdits(removed);
  }

  _onCancelPendingTagAddition(String tag) {
    final edit = Edit(tag, EditType.add);

    _galleryService.dequeueEditForImages(selectedImages, edit);
  }

  _onCancelPendingTagRemoval(String tag) {
    final edit = Edit(tag, EditType.remove);

    _galleryService.dequeueEditForImages(selectedImages, edit);
  }

  @override
  void initState() {
    super.initState();
    _galleryService = getIt.get<IGalleryService>();
    _tagService = getIt.get<ITagService>();

    _pageFocusNode = FocusNode();

    _galleryService.galleryImagesStream.listen((images) {
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
  void dispose() {
    super.dispose();

    _pageFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.keyS, control: true): _saveChanges},
      child: Scaffold(
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
                    tagPathFormat: tagPathFormat,
                    autoSaveTags: autoSaveTags,
                    folder: folder,
                    onFolderChanged: onPathChanged,
                    onTagSeparatorChanged: (val) => setState(() {
                      tagSeparator = val ?? tagSeparator;
                    }),
                    onTagSpaceCharacterChanged: (val) => setState(() {
                      tagSpaceCharacter = val ?? tagSpaceCharacter;
                    }),
                    onTagPathFormatChanged: (val) => setState(() {
                      tagPathFormat = val ?? tagPathFormat;
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          margin: const EdgeInsetsDirectional.symmetric(vertical: 8.0),
                          child:
                              TagAutocomplete(onTagSelected: _onTagSelected, suggestionSearch: _tagService.suggestedGlobalTags, hintText: 'Add or remove tags'),
                        ),
                        Expanded(
                          child: StreamBuilder<DirectoryInfo>(
                            initialData: _galleryService.directoryInfo,
                            stream: _galleryService.directoryInfoStream,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(
                                  child: GalleryTab(
                                    imageStream: _imageStream,
                                    selectedImagePaths: _selectedImagePaths,
                                    imageCount: _images.length,
                                    filteredImageCount: filteredImages.length,
                                    selectedImageCount: selectedImages.length,
                                    filteredTagCount: includedTags.length + excludedTags.length,
                                    hoveredTag: hoveredTag,
                                    includedTags: includedTags,
                                    excludedTags: excludedTags,
                                    onImageSelected: (i) {
                                      setState(() {
                                        if (_selectedImagePaths.contains(i.path)) {
                                          _selectedImagePaths.remove(i.path);
                                        } else {
                                          _selectedImagePaths.add(i.path);
                                        }
                                      });
                                    },
                                    onClearSelection: () => setState(() {
                                      _selectedImagePaths.clear();
                                    }),
                                    tagCount: _images.isNotEmpty ? _images.map((e) => e.tagFiles).flatten().map((i) => i.tags.length).reduce((v, e) => v + e) : 0,
                                  ),
                                );
                              } else {
                                final tabHeaders = <Widget>[];
                                tabHeaders.add(const Tab(text: 'All Images'));

                                final galleryTabs = <Widget>[];
                                galleryTabs.add(Center(
                                  child: GalleryTab(
                                    initialImages: _images,
                                    imageStream: _imageStream,
                                    selectedImagePaths: _selectedImagePaths,
                                    imageCount: _images.length,
                                    filteredImageCount: filteredImages.length,
                                    selectedImageCount: selectedImages.length,
                                    filteredTagCount: includedTags.length + excludedTags.length,
                                    hoveredTag: hoveredTag,
                                    includedTags: includedTags,
                                    excludedTags: excludedTags,
                                    onImageSelected: (i) {
                                      setState(() {
                                        if (_selectedImagePaths.contains(i.path)) {
                                          _selectedImagePaths.remove(i.path);
                                        } else {
                                          _selectedImagePaths.add(i.path);
                                        }
                                      });
                                    },
                                    onClearSelection: () => setState(() {
                                      _selectedImagePaths.clear();
                                    }), tagCount: _images.isNotEmpty ? _images.map((e) => e.tagFiles).flatten().map((i) => i.tags.length).reduce((v, e) => v + e) : 0,
                                  ),
                                ));

                                for (final dir in snapshot.data!.imageDirectories) {
                                  late final Tab dirTab;
                                  if (dir.type == DirectoryType.lora) {
                                    dirTab = Tab(text: '(${dir.repeats}) ${dir.name}');
                                  } else {
                                    dirTab = Tab(text: dir.name);
                                  }

                                  tabHeaders.add(dirTab);

                                  galleryTabs.add(GalleryTab(
                                    initialImages: _galleryService.getImagesForDirectory(dir),
                                    imageStream: _galleryService.getStreamForDirectory(dir),
                                    selectedImagePaths: _selectedImagePaths,
                                    imageCount: _images.length,
                                    filteredImageCount: filteredImages.length,
                                    selectedImageCount: selectedImages.length,
                                    filteredTagCount: includedTags.length + excludedTags.length,
                                    hoveredTag: hoveredTag,
                                    includedTags: includedTags,
                                    excludedTags: excludedTags,
                                    onImageSelected: (i) {
                                      setState(() {
                                        if (_selectedImagePaths.contains(i.path)) {
                                          _selectedImagePaths.remove(i.path);
                                        } else {
                                          _selectedImagePaths.add(i.path);
                                        }
                                      });
                                    },
                                    onClearSelection: () => setState(() {
                                      _selectedImagePaths.clear();
                                    }),
                                    tagCount: _images.isNotEmpty ? _images.map((e) => e.tagFiles).flatten().map((i) => i.tags.length).reduce((v, e) => v + e) : 0,
                                  ));
                                }

                                return DefaultTabController(
                                  length: galleryTabs.length,
                                  child: Column(
                                    children: [
                                      Container(alignment: Alignment.centerLeft, child: TabBar(tabs: tabHeaders)),
                                      Expanded(child: TabBarView(children: galleryTabs)),
                                    ],
                                  ),
                                );
                              }
                            },
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
                        tagsStream: _tagCountStream,
                        imageCount: filteredImages.length,
                        includedTags: includedTags.toList(),
                        excludedTags: excludedTags.toList(),
                        initialPendingEditCounts: tag_utils.transformEditsToCounts(_galleryService.pendingEdits),
                        pendingEditCountsStream: _galleryService.pendingEditsStream
                            .transform(StreamTransformer.fromHandlers(handleData: (d, s) => s.add(tag_utils.transformEditsToCounts(d)))),
                        onTagHover: (t) => setState(() {
                              hoveredTag = t;
                            }),
                        onIncludedTagSelected: _onIncludedTagSelected,
                        onExcludedTagSelected: _onExcludedTagSelected,
                        onRemoveTagSelected: _onRemoveTagSelected,
                        onCancelPendingTagAddition: _onCancelPendingTagAddition,
                        onCancelPendingTagRemoval: _onCancelPendingTagRemoval),
                  ))
            ],
          ),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}
