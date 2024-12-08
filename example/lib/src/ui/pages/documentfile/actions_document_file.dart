import 'package:docman/docman.dart';
import 'package:docman_example/src/ui/widgets/expansion_tile_widget.dart';
import 'package:docman_example/src/ui/widgets/method_action_button.dart';
import 'package:docman_example/src/ui/widgets/method_api_widget.dart';
import 'package:docman_example/src/ui/widgets/method_param_input.dart';
import 'package:docman_example/src/ui/widgets/param_bool.dart';
import 'package:docman_example/src/ui/widgets/param_chips_selector.dart';
import 'package:docman_example/src/ui/widgets/thumb_result_widget.dart';
import 'package:docman_example/src/utils/dialog_helper.dart';
import 'package:docman_example/src/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, PlatformException, Uint8List, rootBundle;

class ActionsDocumentFile extends StatefulWidget {
  const ActionsDocumentFile({
    required this.document,
    required this.onDocument,
    required this.onResult,
    required this.onResultWidgets,
    this.resetAll = false,
    super.key,
  });

  final DocumentFile? document;
  final Function(DocumentFile?) onDocument;
  final Function(List<MethodApiEntry>) onResult;
  final Function(List<Widget>) onResultWidgets;
  final bool resetAll;

  @override
  State<ActionsDocumentFile> createState() => _ActionsDocumentFileState();
}

class _ActionsDocumentFileState extends State<ActionsDocumentFile> {
  ///List of documents parameters
  List<String> _listDocumentsMimeTypes = [];
  List<String> _listDocumentsExtensions = [];
  String? _listDocumentsNameFilter;
  final _exampleMimeTypes = ['application/pdf', 'image/*', 'text/plain', 'image/png', 'image/jpeg', 'directory'];
  final _exampleExtensions = ['pdf', 'txt', 'png', 'jpg'];

  ///Thumbnail parameters
  int _thumbWidth = 256;
  int _thumbHeight = 256;
  int _thumbQuality = 100;
  final _thumbFormats = ['jpeg', 'png', 'webp'];
  String _thumbFormat = 'jpeg';
  bool _thumbAsFile = false;

  DocumentFile? get _document => widget.document;

  @override
  void didUpdateWidget(covariant ActionsDocumentFile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetAll != widget.resetAll) {
      _resetState();
    }
  }

  void _resetState() => setState(() {
        _listDocumentsMimeTypes = _listDocumentsExtensions = [];
        _listDocumentsNameFilter = null;

        _thumbWidth = _thumbHeight = 256;
        _thumbQuality = 100;
        _thumbFormat = 'jpeg';
        _thumbAsFile = false;
      });

  void _setListDocumentsMimeTypes(List<String> mimes) => setState(() => _listDocumentsMimeTypes = mimes);

  void _setListDocumentsExtensions(List<String> exts) => setState(() => _listDocumentsExtensions = exts);

  void _setWidth(String? value) => setState(() {
        _thumbWidth = (int.tryParse(value?.trim() ?? '') ?? 256);
        if (_thumbWidth <= 0) _thumbWidth = 256;
      });

  void _setHeight(String? value) => setState(() {
        _thumbHeight = (int.tryParse(value?.trim() ?? '') ?? 256);
        if (_thumbHeight <= 0) _thumbHeight = 256;
      });

  void _setQuality(String? value) => setState(() {
        _thumbQuality = (int.tryParse(value?.trim() ?? '') ?? 100);
        if (_thumbQuality < 0 || _thumbQuality > 100) _thumbQuality = 100;
      });

  MethodApiEntry _exceptionEntry(Object e) => MethodApiEntry(
        title: '${e.runtimeType}: ${e is DocManException ? e.code : e is PlatformException ? e.code : ''}',
        subTitle: 'Exception was caught',
        result: e is AssertionError ? e.message.toString() : e.toString(),
        isResultOk: false,
      );

  Future<void> _permissions() async {
    PersistedPermission? perms;
    MethodApiEntry? exception;
    try {
      perms = await _document!.permissions();
    } catch (e) {
      exception = _exceptionEntry(e);
    }
    //1. Set the result
    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.permissions()',
        title: exception != null ? exception.title : 'Permissions for: ${_document?.name}',
        subTitle: exception?.subTitle,
        result: exception?.result ?? perms.toString(),
        isResultOk: exception == null && perms != null,
      ),
    ]);
  }

  Future<void> _read() async {
    MethodApiEntry? exception;
    Uint8List? content;

    try {
      content = await _document!.read();
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    //1. Set the result
    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.read()',
        title: exception != null ? exception.title : 'Content of ${_document?.name}',
        subTitle: exception?.subTitle ?? 'Returns the content of the document as `Uint8List`',
        result: exception?.result ?? 'Content Length: ${content?.length}',
        isResultOk: exception == null && content != null,
      )
    ]);
  }

  Future<void> _findFile() async {
    //1.Input directory name
    final name = await DialogHelper()
        .input(
          header: 'Input Document name',
          initValue: '',
          leftIcon: Icons.text_snippet_outlined,
        )
        .then((value) => value?.trim());
    //2. Check if name is invalid
    if (name == null || name.isEmpty) {
      ToastHelper.error(text: 'Document name cannot be empty');
      return;
    }
    final file = await _document!.find(name.trim());
    //1. Set the result
    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.findFile("$name")',
        title: 'Find Document by name (equals)',
        subTitle: 'Returns DocumentFile if found in the directory',
        result: file.toString(),
      ),
    ]);
  }

  Future<void> _createDirectory() async {
    DocumentFile? dir;
    MethodApiEntry? exception;
    //1.Input directory name
    final name = await DialogHelper()
        .input(
          header: 'Input Directory name',
          initValue: 'New Directory',
          leftIcon: Icons.folder_outlined,
        )
        .then((value) => value?.trim());
    //2. Check if name is invalid
    if (name == null || name.isEmpty) {
      ToastHelper.error(text: 'Directory name cannot be empty');
      return;
    }
    //3. Create directory
    try {
      dir = await _document!.createDirectory(name);
    } catch (e) {
      exception = _exceptionEntry(e);
    }
    //4. Update method result
    widget.onDocument(dir);
    //1. Set the result
    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.createDirectory($name)',
        title: exception != null ? exception.title : 'Create Directory',
        subTitle: exception?.subTitle ?? 'Returns the created directory as `DocumentFile`',
        result: exception?.result ?? dir.toString(),
        isResultOk: exception == null && dir != null,
      ),
    ]);
  }

  Future<void> _createFile(String name, {image = false}) async {
    DocumentFile? file;
    MethodApiEntry? exception;

    try {
      //1. Create a png image file
      if (image) {
        //1.1. Load image from assets
        final bytes = (await rootBundle.load('assets/images/png_example.png')).buffer.asUint8List();
        file = await _document?.createFile(name: name, bytes: bytes);
      } else {
        //1.2. Create a text file
        file = await _document?.createFile(name: name, content: 'Hello World');
      }
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    //2. Set the result
    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.createFile(name: $name, ${image ? 'bytes: Uint8List' : 'content: "Hello World"'},)',
        title: exception != null ? exception.title : 'Create File in ${_document?.name}',
        subTitle: exception?.subTitle ?? 'Returns the created file as `DocumentFile`',
        result: exception?.result ?? file.toString(),
        isResultOk: exception == null && file != null,
      ),
    ]);
  }

  Future<void> _listDocuments() async {
    final docs = await _document!.listDocuments(
      mimeTypes: _listDocumentsMimeTypes,
      extensions: _listDocumentsExtensions,
      nameContains: _listDocumentsNameFilter,
    );

    //1. Set the result
    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.listDocuments(mimeTypes: $_listDocumentsMimeTypes, '
            'extensions: $_listDocumentsExtensions, nameContains: $_listDocumentsNameFilter)',
        title: 'List Documents',
        subTitle: 'Returns list of documents in the directory',
      ),
      ...docs.map((doc) => MethodApiEntry(title: 'DocumentFile: ${doc.name}', result: doc.toString())),
    ]);
  }

  Future<void> _cache() async {
    int imageQuality = 100;
    //1. Show image quality dialog if document is an image
    if (_document?.type.startsWith('image/') == true) {
      imageQuality = await DialogHelper()
          .input(
            header: 'Input Image Quality',
            initValue: imageQuality.toString(),
            leftIcon: Icons.image_outlined,
            numbersOnly: true,
            maxLength: 3,
          )
          .then((value) => int.tryParse(value ?? '100') ?? 100);
    }
    //2. Cache the document
    final cache = await _document!.cache(imageQuality: imageQuality);
    //3. Set the result
    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.cache(imageQuality: $imageQuality)',
        title: 'Cache Document',
        subTitle: 'Copy the document to the cache directory',
        result: cache.toString(),
      ),
    ]);
  }

  Future<void> _copyMoveTo({bool deleteSource = false}) async {
    DocumentFile? file;
    MethodApiEntry? exception;
    //1. Get first directory in the list of persisted permissions
    final toPath = await _getDirectoryWithPerms(moveTo: deleteSource);
    //1.1. Show error when no directory is found
    if (toPath == null) return;

    //2. Try to copy / move the document
    try {
      file = deleteSource ? await _document!.moveTo(toPath) : await _document!.copyTo(toPath, name: 'copy custom name');
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    //2.1. After moving, current document is null
    if (deleteSource) widget.onDocument(null);

    //2.2. Set the method name, title, subtitle and result based on the operation
    final methodName = deleteSource ? 'moveTo' : 'copyTo';
    final params = deleteSource ? toPath : '$toPath, name: "copy custom name"';
    final title = deleteSource ? 'Move' : 'Copy';
    final returns = deleteSource ? 'moved' : 'copied';

    //3. Set the result
    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.$methodName($params)',
        title: exception != null ? exception.title : '$title Document to Directory Uri',
        subTitle: exception?.subTitle ?? 'Returns the $returns document as `DocumentFile`',
        result: exception?.result ?? file.toString(),
        isResultOk: exception == null && file != null,
      ),
    ]);
  }

  Future<String?> _getDirectoryWithPerms({moveTo = false}) async {
    final dir = await DocMan.perms
        .list(files: false)
        .then((perms) => perms.isNotEmpty ? perms.first.uri : null, onError: (e) => null);

    //1. Show error when no directory is found
    if (dir == null) {
      widget.onResult([
        MethodApiEntry(
          name: 'DocumentFile.${moveTo ? 'moveTo' : 'copyTo'}(null)',
          title: 'No directory found',
          subTitle: 'Persisted permissions list has no directories',
          result: 'First pick a directory, to grant the persisted permissions to it',
          isResultOk: false,
        ),
      ]);
      return null;
    }
    //2. Return the directory
    return dir;
  }

  Future<void> _delete() async {
    final isDeleted = await _document!.delete();
    //1. Update the document
    widget.onDocument(isDeleted ? null : _document);

    //1. Set the result
    widget.onResult([
      MethodApiEntry(
        name: 'DocumentFile.delete()',
        title: 'Delete Document',
        subTitle: 'Returns true if the document is deleted',
        result: isDeleted.toString(),
      ),
    ]);
  }

  // Future<void> rename() async {
  //   //1.Input new name
  //   final name = await DialogHelper()
  //       .input(
  //         header: 'Rename Document',
  //         initValue: _documentFile!.name,
  //         // leftIcon: Icons.edit_note_outlined,
  //       )
  //       .then((value) => value?.trim());
  //   //2. Check if name is invalid
  //   if (name == null || name.isEmpty || name == _documentFile!.name) {
  //     ToastHelper.error(text: 'Name cannot be empty, null or same');
  //     return;
  //   }
  //   //3. Rename the document
  //   final doc = await _documentFile!.rename(name);
  //   //4. Update method result
  //   setState(() {
  //     _documentFile = doc;
  //     //1. Set the result
  //     result = [
  //       MethodApiEntry(
  //         name: 'DocumentFile.rename($name)',
  //         title: 'Rename Document',
  //         subTitle: 'Returns the renamed document',
  //         result: doc.toString(),
  //       ),
  //       ...result
  //     ];
  //   });
  // }

  Future<void> _getThumbnail() async {
    //1. Set proper format
    final png = _thumbFormat == 'png';
    final webp = _thumbFormat == 'webp';
    //2. Get thumbnail
    if (_thumbAsFile) {
      final thumbFile = await _document!.thumbnailFile(
        width: _thumbWidth,
        height: _thumbHeight,
        quality: _thumbQuality,
        png: png,
        webp: webp,
      );
      widget.onResult([
        MethodApiEntry(
          name:
              'DocumentFile.thumbnailFile(width: $_thumbWidth, height: $_thumbHeight, quality: $_thumbQuality, png: $png, webp: $webp)',
          subTitle: 'Get thumbnail, save in cache & return `File`',
          result: thumbFile?.toString(),
        )
      ]);
    } else {
      //3. Set thumbnail widget to result
      widget.onResultWidgets([
        MethodApiWidget(
          MethodApiEntry(
              name:
                  'DocumentFile.thumbnail(width: $_thumbWidth, height: $_thumbHeight, quality: $_thumbQuality, png: $png, webp: $webp)',
              subTitle: 'Future intentionally delayed for 2 seconds'),
          endDivider: false,
        ),
        ThumbResultWidget(
          maxWidth: _thumbWidth,
          maxHeight: _thumbHeight,
          getThumb: _document!
              .thumbnail(width: _thumbWidth, height: _thumbHeight, quality: _thumbQuality, png: png, webp: webp),
        )
      ]);
    }
  }

  ///Widgets

  bool get _isFile => _document != null && _document!.isFile;

  bool get _isDirectory => _document != null && _document!.isDirectory;

  Widget get _createFileWidget => ExpansionTileWidget(
        title: 'Create DocumentFile',
        subTitle: Text('Create example files in the directory'),
        hideTrailing: true,
        children: [
          MethodActionButton(
            title: 'Create text file',
            onPressed: () => _createFile('sample.txt'),
            active: _document != null && _document!.isDirectory,
            description: Text('Create a file `sample.txt`, from `String` content in directory.',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
          MethodActionButton(
            title: 'Create text file with custom name',
            onPressed: () => _createFile('.txt'),
            active: _document != null && _document!.isDirectory,
            description: Text('Create a file `.txt` (basename will be generated), from `String` content in directory.',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
          MethodActionButton(
            title: 'Create image file',
            onPressed: () => _createFile('sample image.png', image: true),
            active: _document != null && _document!.isDirectory,
            description: Text('Create a file `sample image.png` from `Uint8List` content in directory.',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ],
      );

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

  Widget get _thumbOptions => ExpansionTileWidget(
        title: _thumbQuality == 100 ? 'Thumbnail Options' : 'Thumbnail Quality: $_thumbQuality',
        subTitle: Text(
          _thumbWidth == 256 && _thumbHeight == 256
              ? 'Customize width, height, quality, format'
              : 'Width: $_thumbWidth, Height: $_thumbHeight',
        ),
        action: _document!.canThumbnail ? _getThumbnail : null,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        children: [
          Row(children: [
            Expanded(
                child: MethodParamInput(
              fieldName: 'Width',
              initialValue: _thumbWidth.toString(),
              onSaved: _setWidth,
              numbersOnly: true,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) return '* Required';
                final imageWidth = int.tryParse(value);
                if (imageWidth == null || imageWidth <= 0) {
                  return 'Greater than 0';
                }
                return null;
              },
            )),
            SizedBox(width: 5),
            Expanded(
                child: MethodParamInput(
              fieldName: 'Height',
              initialValue: _thumbHeight.toString(),
              onSaved: _setHeight,
              numbersOnly: true,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) return '* Required';
                final imageHeight = int.tryParse(value);
                if (imageHeight == null || imageHeight <= 0) {
                  return 'Greater than 0';
                }
                return null;
              },
            )),
          ]),
          SizedBox(height: 10),
          MethodParamInput(
            fieldName: 'Quality',
            initialValue: _thumbQuality.toString(),
            onSaved: _setQuality,
            numbersOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Quality is required';
              final imageQuality = int.tryParse(value);
              if (imageQuality == null || imageQuality < 0 || imageQuality > 100) {
                return 'From 0 to 100';
              }
              return null;
            },
          ),
          SizedBox(height: 5),
          ParamChipsSelector(
            title: 'Thumbnail Format: $_thumbFormat',
            hideParam: true,
            available: _thumbFormats,
            selected: [_thumbFormat],
            onUpdate: (value) => setState(() => _thumbFormat = value.isNotEmpty ? value.last : 'jpeg'),
          ),
          ParamBool(
            title: 'as File',
            subTitle: 'Get the thumbnail as a file',
            value: _thumbAsFile,
            onUpdate: (value) => setState(() => _thumbAsFile = value),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //1. Button activity actions
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 5),
            child: Wrap(
              spacing: 5.0,
              runSpacing: 0.0,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                MethodActionButton(title: 'Permissions', onPressed: _permissions),
                Visibility(
                  visible: _isFile,
                  child: MethodActionButton(title: 'Read content', onPressed: _read, active: _document!.canRead),
                ),
                Visibility(visible: _isFile, child: MethodActionButton(title: 'Copy to Cache', onPressed: _cache)),
                Visibility(visible: _isFile, child: MethodActionButton(title: 'Copy to Dir', onPressed: _copyMoveTo)),
                Visibility(
                    visible: _isFile,
                    child: MethodActionButton(title: 'Move to Dir', onPressed: () => _copyMoveTo(deleteSource: true))),
                MethodActionButton(title: 'Delete', onPressed: _delete, active: _document!.canDelete),
                Visibility(
                    visible: _isDirectory, child: MethodActionButton(title: 'Find Document', onPressed: _findFile)),
                Visibility(
                    visible: _isDirectory,
                    child: MethodActionButton(title: 'Create Sub Directory', onPressed: _createDirectory)),

                // MethodActionButton(title: 'Rename', onPressed: rename, active: _documentFile != null),
              ],
            ),
          ),
          Divider(height: 5),
          //2. Complex actions with panels
          if (_isFile && _document!.canThumbnail) _thumbOptions,
          if (_isDirectory) _createFileWidget,
          if (_isDirectory) _listDocumentsWidget,
        ]),
      );
}
