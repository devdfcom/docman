import 'dart:async' show StreamController;
import 'dart:io' show File, Platform;

import 'package:docman/docman.dart';
import 'package:docman_example/src/ui//widgets/method_param_input.dart';
import 'package:docman_example/src/ui/widgets/list_page.dart';
import 'package:docman_example/src/ui/widgets/list_tiles.dart';
import 'package:docman_example/src/ui/widgets/method_action_button.dart';
import 'package:docman_example/src/ui/widgets/method_api_widget.dart';
import 'package:docman_example/src/ui/widgets/param_bool.dart';
import 'package:docman_example/src/ui/widgets/param_chips_selector.dart';
import 'package:docman_example/src/ui/widgets/result_box_stream.dart';
import 'package:docman_example/src/ui/widgets/single_scroll_bar.dart';
import 'package:flutter/material.dart';

class PickerPage extends StatefulWidget {
  const PickerPage({super.key});

  @override
  State<PickerPage> createState() => _PickerPageState();
}

class _PickerPageState extends State<PickerPage> {
  ///Selected Index for the segmented button (params tabs)
  Set<int> _selectedIndex = {0};

  ///Example MimeTypes and Extensions
  final _exampleMimeTypes = [
    'image/*',
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
    'audio/*',
    'video/*',
    'application/pdf',
    'text/plain'
  ];
  final _exampleExtensions = [
    'jpg',
    'png',
    'gif',
    'webp',
    'pdf',
    'docx',
    'xlsx',
    'pptx',
    'txt',
    'mp3',
    'mp4',
    'apk'
  ];

  ///MimeTypes and Extensions selected by the user
  List<String> _mimeTypes = [];
  List<String> _extensions = [];

  ///LocalOnly
  bool _localOnly = false;

  ///Documents pick settings
  bool _grantPermissions = false;

  ///Limit controls
  int _limit = 1;
  bool _limitResultEmpty = false;
  bool _limitResultCancel = false;
  bool _limitResultRestart = false;
  String? _limitResultToast;

  ///Media Settings
  int _imageQuality = 100;
  bool _useVisualMediaPicker = true;

  ///Initial Directory for the picker, `Uri` string
  String? _initDir;

  ///Result list of the picker
  final _streamController = StreamController<Widget>();
  bool _resetAll = false;

  void _resetState() => setState(() {
        _initDir = null;
        _limit = 1;
        _limitResultEmpty = _limitResultCancel = _limitResultRestart = false;
        _imageQuality = 100;
        _useVisualMediaPicker = true;
        _localOnly = false;
        _grantPermissions = false;
        _resetAll = !_resetAll;
        _mimeTypes = _extensions = [];
      });

  //Set result
  void _onResult(List<MethodApiEntry> entries) =>
      entries.map((e) => MethodApiWidget(e)).forEach(_streamController.add);

  void _setLocalOnly(bool value) => setState(() => _localOnly = value);

  void _setGrantPermissions(bool value) =>
      setState(() => _grantPermissions = value);

  /// Picker Filter Params
  void _setMimeTypes(List<String> mimes) => setState(() => _mimeTypes = mimes);

  void _setExtensions(List<String> exts) => setState(() => _extensions = exts);

  /// Picker Limit Params
  void _setLimit(String? value) => setState(() {
        _limit = (int.tryParse(value?.trim() ?? '') ?? 1);
        if (_limit < 1) _limit = 1;
      });

  void _setLimitResultEmpty(bool value) => setState(() {
        _limitResultEmpty = value;
        _limitResultRestart = _limitResultCancel = false;
      });

  void _setLimitResultCancel(bool value) => setState(() {
        _limitResultCancel = value;
        _limitResultEmpty = _limitResultRestart = false;
      });

  void _setLimitResultRestart(bool value) => setState(() {
        _limitResultRestart = value;
        _limitResultEmpty = _limitResultCancel = false;
      });

  /// Picker Media Settings
  void _setImageQuality(String? value) => setState(() {
        _imageQuality = (int.tryParse(value?.trim() ?? '') ?? 100);
        if (_imageQuality < 0 || _imageQuality > 100) _imageQuality = 100;
      });

  void _setUseVisualMediaPicker(bool value) =>
      setState(() => _useVisualMediaPicker = value);

  Future<void> _pickDirectory() async {
    final dir = await DocMan.pick.directory(initDir: _initDir);
    setState(() {
      //1. Set the result
      _onResult([
        MethodApiEntry(
          name: 'DocMan.pick.directory(initDir: $_initDir)',
          title: 'Pick Directory',
          subTitle: 'Returns the picked directory as a `DocumentFile`',
          result: dir?.toString(),
        )
      ]);
      //2. Set the initial directory for the next picker
      _initDir = dir?.uri;
    });
  }

  Future<void> _pickDocuments() async {
    var docs = <DocumentFile>[];
    MethodApiEntry? exception;
    try {
      docs = await DocMan.pick.documents(
        initDir: _initDir,
        mimeTypes: _mimeTypes,
        extensions: _extensions,
        localOnly: _localOnly,
        grantPermissions: _grantPermissions,
        limit: _limit,
        limitResultEmpty: _limitResultEmpty,
        limitResultCancel: _limitResultCancel,
        limitResultRestart: _limitResultRestart,
        limitRestartToastText: _limitResultToast,
      );
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    //1. Build Picker Method entry
    final methodEntry = MethodApiEntry(
      name:
          'DocMan.pick.documents(initDir: $_initDir, mimeTypes: $_mimeTypes, extensions: $_extensions, '
          'localOnly: $_localOnly, grantPermissions: $_grantPermissions, limit: $_limit)',
      title: exception != null ? exception.title : 'Pick Documents',
      subTitle: exception != null
          ? exception.subTitle
          : 'Returns the picked documents as a list of `DocumentFile`',
      result: exception?.result ?? (_limitResultEmpty ? '[]' : null),
      isResultOk: exception == null,
    );

    final List<MethodApiEntry> docsEntries = docs
        .map((doc) => MethodApiEntry(
            title: 'DocumentFile: ${doc.name}', result: doc.toString()))
        .toList();

    //2. Set the result
    setState(() => _onResult([methodEntry, ...docsEntries]));
  }

  Future<void> _pickFiles() async {
    var files = <File>[];
    MethodApiEntry? exception;

    try {
      files = await DocMan.pick.files(
        initDir: _initDir,
        mimeTypes: _mimeTypes,
        extensions: _extensions,
        localOnly: _localOnly,
        limit: _limit,
        limitResultEmpty: _limitResultEmpty,
        limitResultCancel: _limitResultCancel,
        limitResultRestart: _limitResultRestart,
        limitRestartToastText: _limitResultToast,
      );
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    //1. Build Picker Method entry
    final methodEntry = MethodApiEntry(
      name:
          'DocMan.pick.files(initDir: $_initDir, mimeTypes: $_mimeTypes, extensions: $_extensions, localOnly: $_localOnly, limit: $_limit)',
      title: exception != null ? exception.title : 'Pick Files',
      subTitle: exception != null
          ? exception.subTitle
          : 'Returns the picked files as a list of `File`, it copies Documents to app cache directory',
      result: exception?.result,
      isResultOk: exception == null,
    );
    //2. Convert list of files to list of MethodApiEntry
    final List<MethodApiEntry> filesEntries = files
        .map((file) => MethodApiEntry(
            title: 'File: ${file.path.split(Platform.pathSeparator).last}',
            result: _fileString(file)))
        .toList();
    //3. Set the result
    setState(() => _onResult([methodEntry, ...filesEntries]));
  }

  Future<void> _pickMedia() async {
    var files = <File>[];
    MethodApiEntry? exception;
    try {
      files = await DocMan.pick.visualMedia(
        initDir: _initDir,
        mimeTypes: _mimeTypes,
        extensions: _extensions,
        localOnly: _localOnly,
        limit: _limit,
        limitResultEmpty: _limitResultEmpty,
        limitResultCancel: _limitResultCancel,
        limitResultRestart: _limitResultRestart,
        limitRestartToastText: _limitResultToast,
        imageQuality: _imageQuality,
        useVisualMediaPicker: _useVisualMediaPicker,
      );
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    //1. Build Picker Method entry or exception entry
    final methodEntry = MethodApiEntry(
      name:
          'DocMan.pick.visualMedia(initDir: $_initDir, mimeTypes: $_mimeTypes, extensions: $_extensions, localOnly: $_localOnly, limit: $_limit, imageQuality: $_imageQuality, useVisualMediaPicker: $_useVisualMediaPicker)',
      title: exception != null ? exception.title : 'Pick Visual Media',
      subTitle: exception != null
          ? exception.subTitle
          : 'Returns the picked media files as a list of `File`',
      result: exception?.result,
      isResultOk: exception == null,
    );
    //3. Convert list of files to list of MethodApiEntry
    final List<MethodApiEntry> filesEntries = files
        .map((file) => MethodApiEntry(
            title: 'File: ${file.path.split(Platform.pathSeparator).last}',
            result: _fileString(file)))
        .toList();
    //4. Set the result
    setState(() => _onResult([methodEntry, ...filesEntries]));
  }

  String _fileString(File file) {
    final String fileName = file.path.split('/').last;
    return 'File(name: $fileName, path: ${file.path}, size: ${file.lengthSync()} bytes, lastModified: ${file.lastModifiedSync()})';
  }

  MethodApiEntry _exceptionEntry(Object e) => MethodApiEntry(
        title: '${e.runtimeType}: ${e is DocManException ? e.code : ''}',
        subTitle: 'Exception caught while picking files',
        result: e is AssertionError ? e.message.toString() : e.toString(),
        isResultOk: false,
      );

  bool get _activeDirectoryButton =>
      _limit == 1 &&
      !_limitResultEmpty &&
      !_limitResultCancel &&
      !_limitResultRestart &&
      _imageQuality == 100 &&
      _mimeTypes.isEmpty &&
      _extensions.isEmpty &&
      !_grantPermissions;

  Widget _filterTab(BuildContext context) => Column(children: [
        ListTileHeaderDense(
            title: 'Picker Filter Params', icon: Icons.settings),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            ParamBool(
              title: 'localOnly',
              subTitle:
                  'If true, only local files will be shown, no cloud files.',
              value: _localOnly,
              onUpdate: _setLocalOnly,
            ),
            ParamBool(
              title: 'grantPermissions',
              subTitle: 'Grant persisted permissions to the documents',
              value: _grantPermissions,
              onUpdate: _setGrantPermissions,
            ),
            ParamChipsSelector(
              title: 'MimeTypes',
              paramName: 'mimeTypes',
              available: _exampleMimeTypes,
              selected: _mimeTypes,
              onUpdate: _setMimeTypes,
            ),
            ParamChipsSelector(
              title: 'Extensions',
              paramName: 'extensions',
              available: _exampleExtensions,
              selected: _extensions,
              onUpdate: _setExtensions,
            )
          ]),
        )
      ]);

  Widget _limitTab(BuildContext context) => Column(children: [
        ListTileHeaderDense(title: 'Picker Limit Params', icon: Icons.numbers),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.all(10),
                child: MethodParamInput(
                  fieldName: 'Limit - max number of items',
                  initialValue: _limit.toString(),
                  onSaved: _setLimit,
                  numbersOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Limit is required';
                    }
                    final limit = int.tryParse(value);
                    if (limit == null || limit < 1) {
                      return 'Limit must be a positive number';
                    }
                    return null;
                  },
                )),
            ParamBool(
              title: 'limitResultEmpty',
              subTitle: 'Finish with empty list, if items > limit',
              value: _limitResultEmpty,
              onUpdate: _setLimitResultEmpty,
              disabled: _limit == 1,
            ),
            ParamBool(
              title: 'limitResultCancel',
              subTitle: 'Returns error, where message is count of picked items',
              value: _limitResultCancel,
              onUpdate: _setLimitResultCancel,
              disabled: _limit == 1,
            ),
            ParamBool(
              title: 'limitResultRestart',
              subTitle: 'Restart picker with toast message, if items > limit',
              value: _limitResultRestart,
              onUpdate: _setLimitResultRestart,
              disabled: _limit == 1,
            ),
          ]),
        ),
      ]);

  Widget _mediaTab(BuildContext context) => Column(children: [
        ListTileHeaderDense(
            title: 'Visual Picker Media Params', icon: Icons.image),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.all(10),
                child: MethodParamInput(
                  fieldName: 'Image Quality',
                  initialValue: _imageQuality.toString(),
                  onSaved: _setImageQuality,
                  numbersOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'ImageQuality is required';
                    final imageQuality = int.tryParse(value);
                    if (imageQuality == null ||
                        imageQuality < 0 ||
                        imageQuality > 100) {
                      return 'Quality must be between 0 and 100';
                    }
                    return null;
                  },
                )),
            ParamBool(
              title: 'useVisualMediaPicker',
              subTitle: 'use Android PhotoPicker if available',
              value: _useVisualMediaPicker,
              onUpdate: _setUseVisualMediaPicker,
            ),
          ]),
        ),
      ]);

  @override
  Widget build(BuildContext context) => ListPage(
        title: 'Picker Demo',
        actions: [
          IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _resetState,
              tooltip: 'Reset Picker')
        ],
        children: [
          Expanded(
            child: SingleChildScrollViewWithScrollBar(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTileHeaderDense(
                        title: 'Pick Actions', icon: Icons.play_arrow),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: Column(children: [
                          Row(children: [
                            Expanded(
                              child: Wrap(
                                spacing: 5.0,
                                runSpacing: 0.0,
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                children: [
                                  MethodActionButton(
                                      title: 'Directory',
                                      onPressed: _pickDirectory,
                                      active: _activeDirectoryButton),
                                  MethodActionButton(
                                      title: 'Documents',
                                      onPressed: _pickDocuments,
                                      active: _imageQuality == 100),
                                  MethodActionButton(
                                    title: 'Files',
                                    onPressed: _pickFiles,
                                    active: _imageQuality == 100 &&
                                        !_grantPermissions,
                                  ),
                                  MethodActionButton(
                                      title: 'VisualMedia',
                                      onPressed: _pickMedia,
                                      active: !_grantPermissions),
                                ],
                              ),
                            )
                          ])
                        ]),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton(
                        segments: [
                          ButtonSegment(
                              value: 0,
                              label: Text('Filters'),
                              icon: Icon(Icons.filter_alt_outlined)),
                          ButtonSegment(
                              value: 1,
                              label: Text('Limit'),
                              icon: Icon(Icons.numbers)),
                          ButtonSegment(
                              value: 2,
                              label: Text('Media'),
                              icon: Icon(Icons.image)),
                        ],
                        showSelectedIcon: false,
                        selected: _selectedIndex,
                        onSelectionChanged: (value) =>
                            setState(() => _selectedIndex = value),
                      ),
                    ),
                    Builder(
                        builder: (__) => switch (_selectedIndex.first) {
                              1 => _limitTab(context),
                              2 => _mediaTab(context),
                              _ => _filterTab(context)
                            })
                  ]),
            ),
          ),
          SizedBox(height: 10),
          ResultBoxStream(
              streamController: _streamController, resetAll: _resetAll),
        ],
      );
}
