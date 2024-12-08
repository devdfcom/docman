import 'package:docman/docman.dart';
import 'package:docman_example/src/ui/widgets/expansion_tile_widget.dart';
import 'package:docman_example/src/ui/widgets/method_action_button.dart';
import 'package:docman_example/src/ui/widgets/method_api_widget.dart';
import 'package:docman_example/src/ui/widgets/param_chips_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/dialog_helper.dart';

class EventsDocumentFile extends StatefulWidget {
  const EventsDocumentFile({required this.document, required this.onResult, super.key});

  final DocumentFile document;
  final Function(List<MethodApiEntry>) onResult;

  @override
  State<EventsDocumentFile> createState() => _EventsDocumentFileState();
}

class _EventsDocumentFileState extends State<EventsDocumentFile> {
  ///List of documents parameters
  List<String> _listDocumentsMimeTypes = [];
  List<String> _listDocumentsExtensions = [];
  String? _listDocumentsNameFilter;
  final _exampleMimeTypes = ['application/pdf', 'image/*', 'text/plain', 'image/png', 'image/jpeg', 'directory'];
  final _exampleExtensions = ['pdf', 'txt', 'png', 'jpg'];

  DocumentFile get _document => widget.document;

  void _setListDocumentsMimeTypes(List<String> mimes) => setState(() => _listDocumentsMimeTypes = mimes);

  void _setListDocumentsExtensions(List<String> exts) => setState(() => _listDocumentsExtensions = exts);

  MethodApiEntry _exceptionEntry(Object e) => MethodApiEntry(
        title: '${e.runtimeType}: ${e is DocManException ? e.code : e is PlatformException ? e.code : ''}',
        subTitle: 'Exception caught while picking files',
        result: e is AssertionError ? e.message.toString() : e.toString(),
        isResultOk: false,
      );

  Future<void> _readAsString() async {
    final stream = _document.readAsString();
    int countChunks = 0;

    ///1. Send result about starting streaming
    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.readAsString(bufferSize: 8192)',
        subTitle: 'Buffer size is 8KB',
        title: 'Stream Started',
      )
    ]);
    //2. Stream listen
    stream.listen((event) {
      widget.onResult([MethodApiEntry(result: 'readAsString: Chunk $countChunks, length: ${event.length}')]);
      countChunks++;
    }, onDone: () {
      widget.onResult([MethodApiEntry(result: 'readAsString: Done. Total Chunks: $countChunks')]);
    }, onError: (e) {
      widget.onResult([_exceptionEntry(e)]);
    });
  }

  Future<void> _readAsBytes() async {
    final stream = _document.readAsBytes();
    int countChunks = 0;

    ///1. Send result about starting streaming
    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.readAsBytes(bufferSize: 8192)',
        subTitle: 'Buffer size is 8KB',
        title: 'Stream Started',
      )
    ]);
    //2. Stream listen
    stream.listen((event) {
      widget.onResult([MethodApiEntry(result: 'readAsBytes: Chunk $countChunks, length: ${event.length}')]);
      countChunks++;
    }, onDone: () {
      widget.onResult([MethodApiEntry(result: 'readAsBytes: Done. Total Chunks: $countChunks')]);
    }, onError: (e) {
      widget.onResult([_exceptionEntry(e)]);
    });
  }

  Future<void> _listDocuments() async {
    final listStream = _document.listDocumentsStream(
      mimeTypes: _listDocumentsMimeTypes,
      extensions: _listDocumentsExtensions,
      nameContains: _listDocumentsNameFilter,
    );

    int countChunks = 0;

    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.listDocumentsStream(mimeTypes: $_listDocumentsMimeTypes, '
            'extensions: $_listDocumentsExtensions, nameContains: $_listDocumentsNameFilter)',
        title: 'List Documents as Stream started',
      ),
    ]);

    listStream.listen((event) {
      widget.onResult([MethodApiEntry(result: event.toString())]);
      countChunks++;
    }, onDone: () {
      widget.onResult([MethodApiEntry(result: 'Stream is done. Total: $countChunks documents')]);
    }, onError: (e) {
      widget.onResult([_exceptionEntry(e)]);
    });
  }

  Widget get _listDocumentsWidget => ExpansionTileWidget(
        title: 'List Directory documents',
        subTitle: Text('Can be filtered by MimeTypes and Extensions'),
        actionTooltip: 'List Documents',
        action: _listDocuments,
        children: [
          ParamChipsSelector(
            title: 'MimeTypes',
            paramName: 'mimeTypes',
            available: _exampleMimeTypes,
            selected: _listDocumentsMimeTypes,
            onUpdate: _setListDocumentsMimeTypes,
          ),
          ParamChipsSelector(
            title: 'Extensions',
            paramName: 'extensions',
            available: _exampleExtensions,
            selected: _listDocumentsExtensions,
            onUpdate: _setListDocumentsExtensions,
          ),
          ListTile(
            title: Text('Filter Name by${_listDocumentsNameFilter != null ? ': $_listDocumentsNameFilter' : ''}'),
            subtitle: Text('Only documents with name containing the filter'),
            dense: true,
            onTap: () => DialogHelper()
                .input(
              header: 'File name contains',
              initValue: _listDocumentsNameFilter ?? '',
              leftIcon: Icons.text_snippet_outlined,
              customFilter: FilteringTextInputFormatter.deny(RegExp('[\\/:*?"<>|]')),
              canBeEmpty: true,
            )
                .then((value) {
              setState(() => _listDocumentsNameFilter = value?.isNotEmpty == true ? value : null);
            }),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_document.isFile)
            //1. Button activity actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8).copyWith(top: 5),
              child: Wrap(
                spacing: 5.0,
                runSpacing: 0.0,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  MethodActionButton(title: 'Read as String', onPressed: _readAsString, active: _document.canRead),
                  MethodActionButton(title: 'Read as Bytes', onPressed: _readAsBytes, active: _document.canRead),
                ],
              ),
            ),
          if (_document.isDirectory) Divider(height: 5),
          //2. Complex actions with panels
          if (_document.isDirectory) _listDocumentsWidget,
        ]),
      );
}
