import 'dart:io' show Directory, File, Platform;

import 'package:docman/docman.dart';
import 'package:docman_example/src/ui/widgets/expansion_tile_widget.dart';
import 'package:docman_example/src/ui/widgets/list_tiles.dart';
import 'package:docman_example/src/ui/widgets/method_action_button.dart';
import 'package:docman_example/src/ui/widgets/method_api_widget.dart';
import 'package:docman_example/src/ui/widgets/param_chips_selector.dart';
import 'package:docman_example/src/utils/app_dir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException, rootBundle;

class InitDocumentFile extends StatefulWidget {
  const InitDocumentFile({
    required this.document,
    required this.onDocument,
    required this.onResult,
    this.resetAll = false,
    this.pickDir = true,
    super.key,
  });

  final DocumentFile? document;
  final Function(DocumentFile?) onDocument;
  final Function(List<MethodApiEntry>) onResult;
  final bool resetAll;
  final bool pickDir;

  @override
  State<InitDocumentFile> createState() => _InitDocumentFileState();
}

class _InitDocumentFileState extends State<InitDocumentFile> {
  ///Parameters for local file initialization
  String? _localFileName;
  final exampleFileNames = [
    'sample.txt',
    'sample.png',
    'sample.jpg',
    'sample.webp',
    'sample.gif',
    'sample.pdf',
    'sample.mp4',
  ];

  ///Parameters for local file directory initialization
  String? _localDirectoryName;
  final _exampleDirectories = [
    'Cache Directory',
    'Data Directory',
    AppDir.filesExt != null ? 'External Files Directory' : null,
    AppDir.cacheExt != null ? 'External Cache Directory' : null
  ].nonNulls.toList();

  Directory _directoryFromString(String dir) => switch (dir) {
        'Data Directory' => AppDir.data,
        'External Files Directory' => AppDir.filesExt!,
        'External Cache Directory' => AppDir.cacheExt!,
        _ => AppDir.cache,
      };

  ///Initialization from local directory
  String? _localDirectoryInit;

  @override
  void didUpdateWidget(covariant InitDocumentFile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetAll != widget.resetAll) {
      resetState();
    }
  }

  void resetState() => setState(() => _localFileName = _localDirectoryName = _localDirectoryInit = null);

  MethodApiEntry _exceptionEntry(Object e) => MethodApiEntry(
        title: '${e.runtimeType}: ${e is DocManException ? e.code : e is PlatformException ? e.code : ''}',
        subTitle: 'Exception caught while picking files',
        result: e is AssertionError ? e.message.toString() : e.toString(),
        isResultOk: false,
      );

  Future<void> _pickDirectory() async {
    DocumentFile? dir;
    MethodApiEntry? exception;

    try {
      dir = await DocMan.pick.directory();
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    setState(() {
      widget.onDocument(dir);
      widget.onResult([
        MethodApiEntry(
          name: 'DocMan.pick.directory()',
          title: exception != null
              ? exception.title
              : (dir != null ? 'Directory: ${dir.name}' : 'Directory was not picked'),
          subTitle: exception?.subTitle,
          isResultOk: exception == null && dir != null,
          result: exception?.result ?? dir?.toString(),
        ),
      ]);
    });
  }

  Future<void> _pickDocument() async {
    DocumentFile? doc;
    MethodApiEntry? exception;

    try {
      doc = await DocMan.pick.documents().then((list) => list.isNotEmpty ? list.first : null, onError: (e) => null);
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    setState(() {
      widget.onDocument(doc);
      widget.onResult([
        MethodApiEntry(
          name: 'DocMan.pick.documents()',
          title: exception != null
              ? exception.title
              : doc != null
                  ? 'DocumentFile: ${doc.name}'
                  : 'Document was not picked',
          subTitle: exception?.subTitle,
          result: exception?.result ?? doc?.toString(),
          isResultOk: exception == null && doc != null,
        )
      ]);
    });
  }

  Future<String> _getFilePath() async {
    final filePath = [_directoryFromString(_localDirectoryName!).path, _localFileName].join(Platform.pathSeparator);
    final file = File(filePath);
    if (!(await file.exists())) {
      if (_localFileName == 'sample.txt') {
        file.writeAsStringSync('Sample Hello world');
      } else {
        final assetsPath = switch (_localFileName) {
          'sample.jpg' => 'assets/images/jpeg_example.jpg',
          'sample.webp' => 'assets/images/webp_example.webp',
          'sample.gif' => 'assets/images/gif_example.gif',
          'sample.pdf' => 'assets/pdf/example.pdf',
          'sample.mp4' => 'assets/video/video_sample.mp4',
          _ => 'assets/images/png_example.png',
        };
        final bytes = (await rootBundle.load(assetsPath)).buffer.asUint8List();
        await file.writeAsBytes(bytes);
      }
    }

    return filePath;
  }

  Future<void> _fromFilePath() async {
    DocumentFile? doc;
    MethodApiEntry? exception;
    //1. Get file path
    final filePath = await _getFilePath();
    //2. Create DocumentFile from file path
    try {
      doc = await DocumentFile(uri: filePath).get();
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    setState(() {
      //3. Update the document
      widget.onDocument(doc);
      //4. Update the result
      widget.onResult([
        MethodApiEntry(
          name: 'DocumentFile(uri: $filePath).get()',
          title: exception != null ? exception.title : 'DocumentFile: ${doc?.name}',
          subTitle: exception?.subTitle,
          result: exception?.result ?? doc?.toString(),
          isResultOk: exception == null && doc != null,
        )
      ]);
    });
  }

  Future<void> _fromLocalDirectory() async {
    DocumentFile? doc;
    MethodApiEntry? exception;
    //1. Get directory path
    final dirPath = _directoryFromString(_localDirectoryInit!).path;
    //2. Create DocumentFile from directory path
    try {
      doc = await DocumentFile(uri: dirPath).get();
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    setState(() {
      //3. Update the document
      widget.onDocument(doc);
      //4. Update the result
      widget.onResult([
        MethodApiEntry(
          name: 'DocumentFile(uri: $dirPath).get()',
          title: exception != null ? exception.title : 'DocumentFile: ${doc?.name}',
          subTitle: exception?.subTitle,
          result: exception?.result ?? doc?.toString(),
          isResultOk: exception == null && doc != null,
        )
      ]);
    });
  }

  ///Pick Document or Directory
  Widget get _pickerPanel => ListTileDense(
        title: 'Pick',
        subTitle: widget.pickDir ? 'Directory or Document' : 'Document',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.pickDir)
              MethodActionButton(
                iconButton: Icons.folder_open_outlined,
                iconColor: Theme.of(context).primaryColor,
                onPressed: _pickDirectory,
                title: 'Directory',
              ),
            if (widget.pickDir) SizedBox(width: 15),
            MethodActionButton(
              title: 'Document',
              iconButton: Icons.sticky_note_2_outlined,
              iconColor: Theme.of(context).colorScheme.primary,
              onPressed: _pickDocument,
            ),
          ],
        ),
      );

  Widget get _fromFilePanel => ExpansionTileWidget(
        title: _localFileName != null ? 'From file $_localFileName' : 'From local file',
        subTitle: Text(
            _localDirectoryName != null ? 'Initialized from $_localDirectoryName' : 'Initialize from local file path'),
        action: _localFileName != null && _localDirectoryName != null ? _fromFilePath : null,
        children: [
          ParamChipsSelector(
            title: _localDirectoryName != null ? 'From: $_localDirectoryName' : 'Select Directory',
            hideParam: true,
            available: _exampleDirectories,
            selected: _localDirectoryName != null ? [_localDirectoryName!] : [],
            onUpdate: (value) => setState(() => _localDirectoryName = value.isNotEmpty ? value.last : null),
          ),
          ParamChipsSelector(
            title: _localFileName != null ? 'File: $_localFileName' : 'Select File type',
            hideParam: true,
            available: exampleFileNames,
            selected: _localFileName != null ? [_localFileName!] : [],
            onUpdate: (value) => setState(() => _localFileName = value.isNotEmpty ? value.last : null),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            //1. Init Document - pick directory or file
            _pickerPanel,
            Divider(height: 5),
            //2. Init Document - from file path
            _fromFilePanel,
            Divider(height: 5),
            //3. Init Document - from Local directory
            ParamChipsSelector(
              title: _localDirectoryInit != null ? 'From: $_localDirectoryInit' : 'From App Directory',
              subTitle: Text(_localDirectoryInit != null
                  ? 'Initialized from $_localDirectoryInit path'
                  : 'Initialize as local directory'),
              action: _localDirectoryInit != null ? _fromLocalDirectory : null,
              hideParam: true,
              available: _exampleDirectories,
              selected: _localDirectoryInit != null ? [_localDirectoryInit!] : [],
              onUpdate: (value) => setState(() => _localDirectoryInit = value.isNotEmpty ? value.last : null),
            ),
          ],
        ),
      );
}
