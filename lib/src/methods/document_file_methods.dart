import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:docman/docman.dart';
import 'package:docman/src/channels/action_channel.dart';
import 'package:docman/src/channels/activity_channel.dart';
import 'package:docman/src/channels/events_channel.dart';
import 'package:flutter/services.dart';

/// A class that provides methods for a [DocumentFile].
class DocumentFileMethods {
  /// The [DocumentFile] instance.
  final DocumentFile doc;

  /// Constructs a [DocumentFileMethods] instance.
  const DocumentFileMethods(this.doc);

  String get _name => 'documentfile';

  Map<String, dynamic> _args(String action) => {
        'uri': doc.uri,
        'action': action,
      };

  Map<String, dynamic> _streamArgs(String event, {int? buffer, int start = 0}) => {
        'method': '${_name}event',
        'event': event,
        'uri': doc.uri,
        'buffer': buffer,
        'start': start,
      };

  /// Get DocumentFile from the uri.
  Future<DocumentFile?> get() async {
    assert(doc.uri.isNotEmpty, 'DocumentFile must have a uri, before calling get method.');
    //2. Call method
    final result = await _actionResult<Map<dynamic, dynamic>>(_args('get'));
    return result != null ? DocumentFile.fromMap(Map.from(result)) : null;
  }

  /// Get the permissions status for the file or directory.
  Future<PersistedPermission?> permissions() async {
    assert(doc.uri.isNotEmpty, 'DocumentFile must have a uri, before calling permissions method.');
    //2. Call method
    return DocMan.perms.status(doc.uri);
  }

  /// Read the document content as bytes.
  Future<Uint8List?> read() async {
    assert(doc.exists, 'DocumentFile must exist, before calling read method.');
    assert(doc.isFile, 'DocumentFile must be a file, before calling read method.');
    //If document canRead is false, then return null
    if (!doc.canRead) return null;
    //1. Collect args
    final args = _args('read');
    //2. Call method
    final result = await _actionResult<Uint8List>(args);
    return result ?? Uint8List(0);
  }

  /// Read the document content as string stream.
  Stream<String> readAsString(String charset, {int? bufferSize, int start = 0}) {
    assert(doc.exists, 'DocumentFile must exist, before calling readAsString method.');
    assert(doc.isFile, 'DocumentFile must be a file, before calling readAsString method.');

    //1. Collect args
    final args = _streamArgs('readAsString', buffer: bufferSize, start: start);
    args['charset'] = charset;
    //2. Call method
    return _streamResult(args).map<String>((line) => line as String);
  }

  /// Read the document content as bytes stream.
  Stream<Uint8List> readAsBytes({int? bufferSize, int start = 0}) {
    assert(doc.exists, 'DocumentFile must exist, before calling readAsBytes method.');
    assert(doc.isFile, 'DocumentFile must be a file, before calling readAsBytes method.');

    //1. Collect args
    final args = _streamArgs('readAsBytes', buffer: bufferSize, start: start);
    //2. Call method
    return _streamResult(args).map<Uint8List>((bytes) => bytes as Uint8List);
  }

  /// Create a directory in the directory.
  Future<DocumentFile?> createDirectory(String name) async {
    assert(doc.exists, 'DocumentFile must exist, before calling createDirectory method.');
    assert(doc.isDirectory, 'DocumentFile must be a directory, before calling createDirectory method.');
    //If document canCreate is false, then return null
    if (!doc.canCreate) return null;
    //1. Collect args
    final args = _args('createDirectory');
    args['name'] = name;
    //2. Call method
    final result = await _actionResult<Map<dynamic, dynamic>>(args);
    return result != null ? DocumentFile.fromMap(Map.from(result)) : null;
  }

  /// Create a file in the directory.
  Future<DocumentFile?> createFile({
    required String name,
    String? content,
    Uint8List? bytes,
  }) async {
    assert(doc.exists, 'DocumentFile must exist, before calling createFile method.');
    assert(doc.isDirectory, 'DocumentFile must be a directory, before calling createFile method.');
    assert(name.isNotEmpty, 'Name must not be empty.');
    assert(name.contains('.'), 'Name must contain an extension.');
    assert(content != null || bytes != null, 'Content or bytes must be provided.');
    //If document canCreate is false, then return null
    if (!doc.canCreate) return null;
    //1. Collect args
    final args = _args('createFile');
    args['name'] = name;
    args['content'] = bytes ?? Uint8List.fromList(content!.codeUnits);
    //2. Call method
    final result = await _actionResult<Map<dynamic, dynamic>>(args);
    return result != null ? DocumentFile.fromMap(Map.from(result)) : null;
  }

  /// Get list of documents in the directory.
  Future<List<DocumentFile>> list({
    List<String> mimeTypes = const [],
    List<String> extensions = const [],
    String? nameContains,
  }) async {
    assert(doc.exists, 'DocumentFile must exist, before calling list method.');
    assert(doc.isDirectory, 'DocumentFile must be a directory, before calling list method.');
    assert(nameContains == null || nameContains.isNotEmpty, 'nameContains must be valid string or null.');
    //If document canRead is false, then return empty list
    if (!doc.canRead) return [];
    //1. Collect args
    final args = _args('list');
    args['mimeTypes'] = mimeTypes;
    args['extensions'] = extensions;
    args['name'] = nameContains;
    //2. Call method
    final result = await _actionResult<List<dynamic>>(args);
    return result?.cast<Map<dynamic, dynamic>>().map((it) => DocumentFile.fromMap(Map.from(it))).toList() ?? [];
  }

  /// Get list of documents in the directory as stream.
  Stream<DocumentFile> listStream({
    List<String> mimeTypes = const [],
    List<String> extensions = const [],
    String? nameContains,
  }) {
    assert(doc.exists, 'DocumentFile must exist, before calling listStream method.');
    assert(doc.isDirectory, 'DocumentFile must be a directory, before calling listStream method.');
    assert(nameContains == null || nameContains.isNotEmpty, 'nameContains must be valid string or null.');
    //If document canRead is false, then return empty list
    if (!doc.canRead) return const Stream.empty();
    //1. Collect args
    final args = _streamArgs('listStream');
    args['mimeTypes'] = mimeTypes;
    args['extensions'] = extensions;
    args['name'] = nameContains;
    //2. Call method
    return _streamResult(args).map<DocumentFile>((it) => DocumentFile.fromMap(Map.from(it as Map<dynamic, dynamic>)));
  }

  /// Find a document in the directory by name.
  Future<DocumentFile?> find(String name) async {
    assert(doc.exists, 'DocumentFile must exist, before calling find method.');
    assert(doc.isDirectory, 'DocumentFile must be a directory, before calling find method.');
    assert(name.isNotEmpty, 'Name must not be empty.');
    //If document canRead is false, then return null
    if (!doc.canRead) return Future.value();
    //1. Collect args
    final args = _args('find');
    args['name'] = name;
    //2. Call method
    final result = await _actionResult<Map<dynamic, dynamic>>(args);
    return result != null ? DocumentFile.fromMap(Map.from(result)) : null;
  }

  /// Copy the document to the cache directory.
  Future<File?> cache({
    int imageQuality = 100,
  }) async {
    assert(doc.exists, 'DocumentFile must exist, before calling cache method.');
    assert(doc.isFile, 'DocumentFile must be a file, before calling cache method.');
    //If document canRead is false, then return null
    if (!doc.canRead) return Future.value();
    //1. Collect args
    final args = _args('cache');
    args['imageQuality'] = imageQuality;
    //2. Call method
    final cacheFilePath = await _actionResult<String>(args);
    return cacheFilePath != null ? File(cacheFilePath) : null;
  }

  ///Copy / Move the document to the directory.
  Future<DocumentFile?> saveToDirectory(
    String uri, {
    String? name,
    bool deleteSource = false,
  }) async {
    assert(doc.exists, 'DocumentFile must exist, before calling ${deleteSource ? 'moveTo' : 'copyTo'} method.');
    assert(doc.isFile, 'DocumentFile must be a file, before calling ${deleteSource ? 'moveTo' : 'copyTo'} method.');
    //canRead required both for copy and move operations
    //If this is a move operation and document canDelete is false, then return null
    if (!doc.canRead || (deleteSource && !doc.canDelete)) return Future.value();
    //1. Collect args
    final args = _args(deleteSource ? 'moveTo' : 'copyTo');
    args['to'] = uri;
    args['name'] = name;
    //2. Call method
    final result = await _actionResult<Map<dynamic, dynamic>>(args);
    return result != null ? DocumentFile.fromMap(Map.from(result)) : null;
  }

  /// Delete the document, if it's possible.
  Future<bool> delete() async {
    assert(doc.exists, 'DocumentFile must exist, before calling delete method.');
    //If document canDelete is false, then return false
    if (!doc.canDelete) return false;
    //2. Call method
    final result = await _actionResult<bool>(_args('delete'));
    return result ?? false;
  }

  /// Rename the document.
  // Future<DocumentFile?> rename(String name) async {
  //   assert(doc.exists, 'DocumentFile must exist, before calling rename method.');
  //   assert(name.isNotEmpty, 'Name must not be empty.');
  //   //If document canRename is false, then return null
  //   if (!doc.canRename) return null;
  //   //1. Collect args
  //   final args = _args('rename');
  //   args['name'] = name;
  //   //2. Call method
  //   final result = await _actionResult<Map<dynamic, dynamic>>(args);
  //   return result != null ? DocumentFile.fromMap(Map.from(result)) : null;
  // }

  /// Open the document.
  Future<bool> open(String? title) async {
    assert(doc.exists, 'DocumentFile must exist, before calling openWith method.');
    assert(doc.isFile, 'DocumentFile must be a file, before calling openWith method.');
    //1. Collect args
    final args = _args('open');
    if (title != null) args['title'] = title;
    //2. Call method
    final result = await _activityResult<bool>(args);
    return result ?? false;
  }

  /// Share the document.
  Future<bool> share(String? title) async {
    assert(doc.exists, 'DocumentFile must exist, before calling share method.');
    assert(doc.isFile, 'DocumentFile must be a file, before calling share method.');
    //1. Collect args
    final args = _args('share');
    if (title != null) args['title'] = title;
    //2. Call method
    final result = await _activityResult<bool>(args);
    return result ?? false;
  }

  /// Save the document to the picked destination.
  Future<DocumentFile?> saveTo({
    String? initDir,
    bool localOnly = false,
    bool deleteSource = false,
  }) async {
    assert(doc.exists, 'DocumentFile must exist, before calling saveTo method.');
    assert(doc.isFile, 'DocumentFile must be a file, before calling saveTo method.');
    //1. Collect args
    final args = _args('saveTo');
    if (initDir != null) args['initDir'] = initDir;
    args['localOnly'] = localOnly;
    args['deleteSource'] = deleteSource & doc.canDelete;
    //2. Call method
    final result = await _activityResult<Map<dynamic, dynamic>>(args);
    return result != null ? DocumentFile.fromMap(Map.from(result)) : null;
  }

  /// Get the thumbnail of the document
  Future<T?> getThumbnail<T>({
    int width = 256,
    int height = 256,
    int quality = 100,
    bool png = false,
    bool webp = false,
  }) async {
    assert(doc.exists, 'DocumentFile must exist, before calling getThumbnail method.');
    assert(doc.isFile, 'DocumentFile must be a file, before calling getThumbnail method.');
    assert(width > 0 && height > 0, 'Width and height must be greater than 0.');
    assert(quality >= 0 && quality <= 100, 'Quality must be between 0 and 100.');
    assert(!png || !webp, 'Only one of png or webp can be true.');
    //1. Check if canThumbnail
    if (!doc.canThumbnail) return Future.value();
    //2. Collect args
    final args = <String, dynamic>{
      ..._args(T == File ? 'thumbnailFile' : 'thumbnail'),
      'width': width,
      'height': height,
      'quality': quality,
      'png': png,
      'webp': webp,
    };

    return (T == File ? await _getThumbnailFile(args) : await _getDocumentThumbnail(args)) as T?;
  }

  Future<DocumentThumbnail?> _getDocumentThumbnail([dynamic args]) async {
    final result = await _actionResult<Map<dynamic, dynamic>>(args);
    return result != null ? DocumentThumbnail.fromMap(Map.from(result)) : null;
  }

  Future<File?> _getThumbnailFile([dynamic args]) async {
    final result = await _actionResult<String>(args);
    return result != null ? File(result) : null;
  }

  Future<T?> _activityResult<T>([dynamic args]) => ActivityChannel.instance.call<T>('${_name}activity', args);

  Future<T?> _actionResult<T>([dynamic args]) => ActionChannel.instance.call<T>('${_name}action', args);

  Stream<dynamic> _streamResult([dynamic args]) => EventsChannel.instance.listen(args);
}
