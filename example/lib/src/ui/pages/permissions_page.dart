import 'dart:async' show StreamController;

import 'package:docman/docman.dart';
import 'package:docman_example/src/ui/widgets/list_page.dart';
import 'package:docman_example/src/ui/widgets/list_tiles.dart';
import 'package:docman_example/src/ui/widgets/method_action_button.dart';
import 'package:docman_example/src/ui/widgets/method_api_widget.dart';
import 'package:docman_example/src/ui/widgets/param_bool.dart';
import 'package:docman_example/src/ui/widgets/result_box_stream.dart';
import 'package:docman_example/src/ui/widgets/single_scroll_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _resultAsStream = false;
  bool _docsAsStream = false;

  ///List of permissions from list method
  List<PersistedPermission> _permissions = [];

  ///Result list of actions
  bool _resetAll = false;

  final _streamController = StreamController<Widget>();

  ///State methods
  void _resetState() => setState(() {
        _permissions.clear();
        _resultAsStream = _docsAsStream = false;
        _resetAll = !_resetAll;
      });

  ///Exception entry
  MethodApiEntry _exceptionEntry(Object e) => MethodApiEntry(
        title:
            '${e.runtimeType}: ${e is DocManException ? e.code : e is PlatformException ? e.code : ''}',
        subTitle: 'Exception caught while getting permissions',
        result: e is AssertionError ? e.message.toString() : e.toString(),
        isResultOk: false,
      );

  //Set result
  void _onResult(List<MethodApiEntry> entries) =>
      entries.map((e) => MethodApiWidget(e)).forEach(_streamController.add);

  void _setResultAsStream(bool value) =>
      setState(() => _resultAsStream = value);

  void _setDocsAsStream(bool value) => setState(() => _docsAsStream = value);

  Future<void> _pickDirectory() async {
    PersistedPermission? perm;
    MethodApiEntry? exception;
    try {
      perm = await DocMan.pick.directory().then((dir) => dir?.permissions());
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    setState(() {
      //1. Set the result
      _onResult([
        MethodApiEntry(
          name: 'DocMan.pick.directory() -> DocumentFile.permissions()',
          title: exception != null ? exception.title : 'Directory permissions',
          subTitle: exception?.subTitle,
          result: exception?.result ?? perm?.toString(),
          isResultOk: exception == null,
        )
      ]);
    });
  }

  Future<void> _listPerms({bool directories = true, bool files = true}) async {
    _permissions =
        await DocMan.perms.list(directories: directories, files: files);
    setState(() {
      //1. Set the result
      _onResult([
        MethodApiEntry(
          name: 'DocMan.perms.list(directories: $directories, files: $files)',
          title: (directories && files)
              ? 'List All Permissions'
              : directories
                  ? 'Permissions for Directories only'
                  : 'Permissions for Files only',
          subTitle: 'Returns list of persisted permissions',
          result: _permissions.isNotEmpty
              ? null
              : 'No persisted permissions were granted',
        ),
        ..._permissions.map((e) => MethodApiEntry(result: e.toString())),
      ]);
    });
  }

  Future<void> _listPermsStream(
      {bool directories = true, bool files = true}) async {
    final stream =
        DocMan.perms.listStream(directories: directories, files: files);
    int countChunks = 0;

    //1. Send result about starting streaming
    setState(() {
      _onResult([
        MethodApiEntry(
          name:
              'DocMan.perms.listStream(directories: $directories, files: $files)',
          title: 'Stream Started',
        )
      ]);
    });

    //2. Stream listen
    stream.listen((PersistedPermission event) {
      setState(() {
        _onResult([MethodApiEntry(result: event.toString())]);
        _permissions.add(event);
      });
      countChunks++;
    }, onDone: () {
      setState(() {
        _onResult(
            [MethodApiEntry(result: 'Done. Total Permissions: $countChunks')]);
      });
    }, onError: (e) {
      setState(() {
        _onResult([_exceptionEntry(e)]);
      });
    });
  }

  Future<void> _listDocuments(
      {bool directories = true, bool files = true}) async {
    final docs = await DocMan.perms
        .listDocuments(directories: directories, files: files);

    setState(() {
      //1. Set the result
      _onResult([
        MethodApiEntry(
          name:
              'DocMan.perms.listDocuments(directories: $directories, files: $files)',
          title: (directories && files)
              ? 'List All Documents'
              : directories
                  ? 'List Directories only'
                  : 'List Files only',
          subTitle: 'Returns list of documents with persisted permissions',
          result: docs.isNotEmpty ? null : 'No documents found',
        ),
        ...docs.map((doc) => MethodApiEntry(
            title: 'DocumentFile: ${doc.name}', result: doc.toString())),
      ]);
    });
  }

  Future<void> _listDocumentsAsStream(
      {bool directories = true, bool files = true}) async {
    final stream = DocMan.perms
        .listDocumentsStream(directories: directories, files: files);
    int countChunks = 0;

    //1. Send result about starting streaming
    setState(() => _onResult([
          MethodApiEntry(
            name:
                'DocMan.perms.listDocumentsStream(directories: $directories, files: $files)',
            title: 'Stream Started',
          )
        ]));

    //2. Stream listen
    stream.listen((event) {
      setState(() {
        _onResult([MethodApiEntry(result: event.toString())]);
      });
      countChunks++;
    }, onDone: () {
      setState(() {
        _onResult(
            [MethodApiEntry(result: 'Done. Total Documents: $countChunks')]);
      });
    }, onError: (e) {
      setState(() {
        _onResult([_exceptionEntry(e)]);
      });
    });
  }

  Future<void> _validateList() async {
    bool answer = false;
    MethodApiEntry? exception;

    try {
      answer = await DocMan.perms.validateList();
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    setState(() {
      //1. Set the result
      _onResult([
        MethodApiEntry(
          name: 'DocMan.perms.validateList()',
          title: exception != null ? exception.title : 'Validate List',
          subTitle: exception?.subTitle ??
              'Removes invalid permissions from the list',
          result: exception?.result ?? answer.toString(),
          isResultOk: exception == null,
        )
      ]);
    });
  }

  Future<void> _releaseAll() async {
    final answer = await DocMan.perms.releaseAll();
    setState(() {
      //1. Set the result
      _onResult([
        MethodApiEntry(
          name: 'DocMan.perms.releaseAll()',
          title: 'Release All',
          result: answer
              ? 'All permissions released'
              : 'Failed to release permissions',
        )
      ]);
    });
  }

  Future<void> _releaseOne() async {
    final answer = await DocMan.perms.release(_permissions.first.uri);
    setState(() {
      //1. Set the result
      _onResult([
        MethodApiEntry(
          name: 'DocMan.perms.release() || Permission.release()',
          title: 'Release first in list',
          result:
              answer ? 'Permission released' : 'Failed to release permission',
        )
      ]);
    });
  }

  Widget get _listPermissionsCard => Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 0.0,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              MethodActionButton(
                  title: 'All Permissions',
                  onPressed: _resultAsStream ? _listPermsStream : _listPerms),
              MethodActionButton(
                  title: 'Directories only',
                  onPressed: () => _resultAsStream
                      ? _listPermsStream(files: false)
                      : _listPerms(files: false)),
              MethodActionButton(
                  title: 'Files only',
                  onPressed: () => _resultAsStream
                      ? _listPermsStream(directories: false)
                      : _listPerms(directories: false)),
            ],
          ),
          ParamBool(
            title: 'Run as Stream',
            subTitle: 'Get permissions as a stream',
            value: _resultAsStream,
            onUpdate: _setResultAsStream,
          ),
          Divider(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                      child: const Text(
                          'Lists the persisted permissions, can be filtered by type. Can be run as stream')),
                ]),
          ),
        ]),
      );

  Widget get _listDocumentsCard => Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 0.0,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              MethodActionButton(
                  title: 'All Documents',
                  onPressed:
                      _docsAsStream ? _listDocumentsAsStream : _listDocuments),
              MethodActionButton(
                  title: 'List Directories',
                  onPressed: () => _docsAsStream
                      ? _listDocumentsAsStream(files: false)
                      : _listDocuments(files: false)),
              MethodActionButton(
                  title: 'List Files',
                  onPressed: () => _docsAsStream
                      ? _listDocumentsAsStream(directories: false)
                      : _listDocuments(directories: false)),
            ],
          ),
          ParamBool(
            title: 'Run as Stream',
            subTitle: 'Get documents as a stream',
            value: _docsAsStream,
            onUpdate: _setDocsAsStream,
          ),
          Divider(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                      child: const Text(
                          'Lists the documents with persisted permissions, can be filtered by type')),
                ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => ListPage(
        title: 'Persisted Permissions',
        actions: [
          IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _resetState,
              tooltip: 'Reset Data')
        ],
        children: [
          Expanded(
            child: SingleChildScrollViewWithScrollBar(
              child: Column(children: [
                ListTileHeaderDense(
                    title: 'Permissions', icon: Icons.security_outlined),
                _listPermissionsCard,
                ListTileHeaderDense(
                    title: 'Documents with permissions',
                    icon: Icons.rule_folder_outlined),
                _listDocumentsCard,
                ListTileHeaderDense(title: 'Actions', icon: Icons.play_arrow),
                MethodActionButton(
                  title: 'Validate List',
                  onPressed: _validateList,
                  description:
                      const Text('Removes invalid permissions from the list'),
                ),
                MethodActionButton(
                  title: "Release one permission",
                  onPressed: _releaseOne,
                  description:
                      const Text('Release first permission from list.'),
                  active: _permissions.isNotEmpty,
                ),
                MethodActionButton(
                    title: 'Release all',
                    onPressed: _releaseAll,
                    description:
                        const Text('Releases all the persisted permissions'),
                    active: _permissions.isNotEmpty),
                ListTileHeaderDense(
                    title: 'Test Actions', icon: Icons.folder_outlined),
                MethodActionButton(
                    title: 'Pick Directory',
                    onPressed: _pickDirectory,
                    description: const Text(
                        'Pick a directory to get its permissions, it will check status of permissions')),
              ]),
            ),
          ),
          SizedBox(height: 10),
          ResultBoxStream(
              streamController: _streamController, resetAll: _resetAll),
        ],
      );
}
