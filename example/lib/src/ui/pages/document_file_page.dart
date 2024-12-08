import 'dart:async' show StreamController;

import 'package:docman/docman.dart';
import 'package:docman_example/src/ui/pages/documentfile/actions_document_file.dart';
import 'package:docman_example/src/ui/pages/documentfile/activity_document_file.dart';
import 'package:docman_example/src/ui/pages/documentfile/events_document_file.dart';
import 'package:docman_example/src/ui/pages/documentfile/init_document_file.dart';
import 'package:docman_example/src/ui/widgets/list_page.dart';
import 'package:docman_example/src/ui/widgets/list_tiles.dart';
import 'package:docman_example/src/ui/widgets/method_api_widget.dart';
import 'package:docman_example/src/ui/widgets/result_box_stream.dart';
import 'package:docman_example/src/ui/widgets/single_scroll_bar.dart';
import 'package:flutter/material.dart';

class DocumentFilePage extends StatefulWidget {
  const DocumentFilePage({super.key});

  @override
  State<DocumentFilePage> createState() => _DocumentFilePageState();
}

class _DocumentFilePageState extends State<DocumentFilePage> {
  DocumentFile? _document;

  bool _resetAll = false;

  final _streamController = StreamController<Widget>();

  ///State methods
  void _resetState() => setState(() {
        _document = null;
        _resetAll = !_resetAll;
      });

  ///Methods

  //Set document file
  void _onDocument(DocumentFile? doc) => setState(() => _document = doc);

  //Set result
  void _onResult(List<MethodApiEntry> entries) =>
      entries.map((e) => MethodApiWidget(e)).forEach(_streamController.add);

  void _onResultWidgets(List<Widget> widgets) =>
      widgets.forEach(_streamController.add);

  bool get _isFile => _document != null && _document!.isFile;

  ///Widgets

  /// Document Activity Actions
  List<Widget> get _activityActions => _isFile
      ? [
          ListTileHeaderDense(
              title: 'Document Activity Actions',
              icon: Icons.not_started_outlined),
          ActivityDocumentFile(
              document: _document,
              onDocument: _onDocument,
              onResult: _onResult),
        ]
      : [];

  /// Document Actions
  List<Widget> get _documentActions => _document != null
      ? [
          ListTileHeaderDense(
              title: 'Document Actions', icon: Icons.play_arrow),
          ActionsDocumentFile(
            document: _document,
            onDocument: _onDocument,
            onResult: _onResult,
            onResultWidgets: _onResultWidgets,
            resetAll: _resetAll,
          ),
        ]
      : [];

  /// Document Stream Actions
  List<Widget> get _streamActions => _document != null
      ? [
          ListTileHeaderDense(
              title: 'Document Stream Actions', icon: Icons.stream_outlined),
          EventsDocumentFile(document: _document!, onResult: _onResult)
        ]
      : [];

  @override
  Widget build(BuildContext context) => ListPage(
        title: 'DocumentFile',
        actions: [
          IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _resetState,
              tooltip: 'Reset Data')
        ],
        children: [
          Expanded(
            child: SingleChildScrollViewWithScrollBar(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ///1. Document Initialization
                  ListTileHeaderDense(
                      title: 'Init Document', icon: Icons.note_outlined),
                  InitDocumentFile(
                    document: _document,
                    onDocument: _onDocument,
                    onResult: _onResult,
                    resetAll: _resetAll,
                  ),

                  ///2. Actions
                  ..._activityActions,
                  ..._documentActions,
                  ..._streamActions,

                  ///3. No Document selected
                  if (_document == null)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTileDense(
                        title: 'No Document selected',
                        subTitle:
                            'Pick a directory or document to perform actions',
                      ),
                    )
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          ResultBoxStream(
              streamController: _streamController, resetAll: _resetAll),
        ],
      );
}
