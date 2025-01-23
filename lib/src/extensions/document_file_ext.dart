import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:docman/docman.dart';
import 'package:docman/src/methods/document_file_methods.dart';

/// Contains all supported methods which use `Action` channel for [DocumentFile] class.
/// All methods can run in background.
/// {@category DocumentFile}
extension DocumentFileActionsExt on DocumentFile {
  /// Get DocumentFile from uri.
  ///
  /// `DocumentFile` [uri] must not be empty, before calling this method.
  ///
  /// [uri] - can be `Content Uri` saved from previous request with persisted permission,
  /// or it can be app local `File.path` or `Directory.path`.
  ///
  /// **Note:** `Uri` without persisted permissions will not work, or uris like `content://media/external/file/106`.
  ///
  /// **Note**: Or you can use static method `DocumentFile.fromUri(uri)` to get the `DocumentFile` instance.
  ///
  /// Returns [DocumentFile] for the [uri], or null if uri is not valid.
  Future<DocumentFile?> get() => DocumentFileMethods(this).get();

  /// Requests the permissions status for the file or directory.
  Future<PersistedPermission?> permissions() =>
      DocumentFileMethods(this).permissions();

  /// Read the document content as bytes.
  ///
  /// [DocumentFile] must exist & must be a file, before calling this method.
  ///
  /// Returns full content of the document as bytes.
  Future<Uint8List?> read() => DocumentFileMethods(this).read();

  /// Create a sub directory in current directory.
  ///
  /// Only works if the current document is a directory, and has permission to write, and
  /// if it has flag `canCreate` set to true.
  ///
  /// - [name] Directory name, must not be empty.
  /// Returns [DocumentFile] of the created directory, or null if something went wrong.
  Future<DocumentFile?> createDirectory(String name) =>
      DocumentFileMethods(this).createDirectory(name);

  /// Create a file in the current directory.
  ///
  /// Only works if the current document is a directory, and has permission to write, and
  /// if it has flag `canCreate` set to true.
  ///
  /// - [name] File name, must not be empty & must contain an extension with dot.
  /// On creation, it will try to set the mime type based on the extension.
  /// Throws an exception if the mime type is not detected.
  /// Example: `example file.jpg` or `test_document.pdf` or `.pdf`: base name will be generated.
  /// - [content] is optional and can be used to set the content of the file.
  /// It will be converted to bytes anyway.
  /// - [bytes] optional and can be used to set the bytes of the file.
  ///
  /// If both [content] and [bytes] are provided, [bytes] will be used.
  ///
  /// Returns [DocumentFile] of the created file, or null if something went wrong.
  Future<DocumentFile?> createFile(
          {required String name, String? content, Uint8List? bytes}) =>
      DocumentFileMethods(this)
          .createFile(name: name, content: content, bytes: bytes);

  /// List the documents in the directory.
  ///
  /// Can be used only if the current document is a directory.
  ///
  /// - [mimeTypes] parameter is optional and can be used to filter the documents based on MIME types.
  /// If the [mimeTypes] is empty, it will return all documents in the directory.
  /// [mimeTypes] can also contain `directory` to list only directories.
  /// - [extensions] parameter is optional and can be used to filter the documents based on file extensions.
  /// On run, [mimeTypes] & [extensions] will be combined to supported `mimeTypes` list to filter the documents.
  /// - [nameContains] parameter is optional and can be used to filter the documents based on name.
  /// It checks if the name contains the given string.
  ///
  /// Returns a list of [DocumentFile] instances in the directory, or empty list if none found.
  Future<List<DocumentFile>> listDocuments({
    List<String> mimeTypes = const [],
    List<String> extensions = const [],
    String? nameContains,
  }) =>
      DocumentFileMethods(this).list(
          mimeTypes: mimeTypes,
          extensions: extensions,
          nameContains: nameContains);

  /// Find the document in the directory.
  ///
  /// Search through the documents in the directory, with the given [name].
  ///
  /// [DocumentFile] must be a directory & must have permission to read, before calling this method.
  ///
  /// - [name] Name of the document to search. Example: `example.jpg` or `example.pdf` etc.
  /// Cannot be empty.
  ///
  /// Returns [DocumentFile] of the found document, or null if not found.
  Future<DocumentFile?> find(String name) =>
      DocumentFileMethods(this).find(name);

  /// Copy document to temporary cache directory.
  ///
  /// If file with same name already exists in cache, it will be overwritten.
  /// Works only if the document exists & has permission to read.
  ///
  /// - [imageQuality] parameter is optional and can be used to set the image quality.
  /// The value must be between 0 and 100.
  ///
  /// Returns cache [File] of the document, or null if the document is a directory,
  /// or if the file does not exist.
  /// First it will try to copy to external cache directory, if not available, then to internal cache directory.
  /// It's your responsibility to move the file to the permanent location if needed,
  /// otherwise, it will be deleted when the app is closed/destroyed.
  Future<File?> cache({int imageQuality = 100}) =>
      DocumentFileMethods(this).cache();

  /// Copy the document to directory.
  ///
  /// [DocumentFile] must be a file & exist & have flag `canRead` set to true.
  /// Works even with documents instantiated from `File.path`.
  ///
  /// - [uri] Directory uri (tree uri) must have persisted permission,
  /// otherwise, it will throw an exception, or it can be a `Directory.path`: local app directory.
  /// - [name] New name for the copied document, if not provided, it will use the current document name.
  /// It doesn't matter if the name contains an extension or not, system will decide based on the mime type.
  /// Example: `my Image.jpg` or `test_image` etc.
  ///
  /// Returns [DocumentFile] of the copied document, or null if something went wrong.
  /// Automatically deletes created document if the copy was not successful.
  Future<DocumentFile?> copyTo(String uri, {String? name}) =>
      DocumentFileMethods(this).saveToDirectory(uri, name: name);

  /// Move the document to directory.
  ///
  /// [DocumentFile] must be a file & exist & have flag `canRead` & `canDelete` set to true.
  /// Works even with documents instantiated from `File.path`.
  ///
  /// - [uri] Directory uri (tree uri) must have persisted permission,
  /// otherwise, it will throw an exception, or it can be a `Directory.path`: local app directory.
  /// - [name] New name for the copied document, if not provided, it will use the current document name.
  /// It doesn't matter if the name contains an extension or not, system will decide based on the mime type.
  /// Example: `example.jpg` or `example` etc.
  ///
  /// Returns [DocumentFile] of the moved document, or null if something went wrong.
  /// Automatically deletes created document if the move was not successful.
  /// Remember, after moving the document, the current document will delete itself.
  Future<DocumentFile?> moveTo(String uri, {String? name}) =>
      DocumentFileMethods(this)
          .saveToDirectory(uri, name: name, deleteSource: true);

  /// Delete the document (file or directory).
  ///
  /// Works only if the document exists & has permission to write & flag `canDelete` is set to true.
  ///
  /// If the document is a directory, it will delete all the documents in the directory too.
  /// Returns `true` if the document is deleted successfully, otherwise `false`.
  Future<bool> delete() => DocumentFileMethods(this).delete();

  /// Get the thumbnail of the document.
  ///
  /// [DocumentFile] must exist & must be a file, before calling this method.
  /// Has to have permission [canThumbnail] set to true.
  ///
  /// - [width] Width of the thumbnail, default is 256.
  /// - [height] Height of the thumbnail, default is 256.
  ///
  /// [width] & [height] must be greater than 0.
  ///
  /// - [quality] Quality of the thumbnail, default is 100. Must be between 0 and 100.
  /// - [png] Whether it will compress the thumbnail as PNG, otherwise as JPEG.
  /// - [webp] Whether it will compress the thumbnail as WebP, otherwise as JPEG.
  ///
  /// [png] & [webp] can't be true at the same time.
  ///
  /// Returns thumbnail as [DocumentThumbnail] or null if thumbnail is not available.
  /// Sometimes due to different document providers, thumbnail can have bigger dimensions, than requested.
  /// Some document providers may not support thumbnail generation.
  /// Added custom thumbnail generation for video & pdf & image files.
  Future<DocumentThumbnail?> thumbnail({
    int width = 256,
    int height = 256,
    int quality = 100,
    bool png = false,
    bool webp = false,
  }) =>
      DocumentFileMethods(this).getThumbnail<DocumentThumbnail>(
          width: width, height: height, quality: quality, png: png, webp: webp);

  /// Get the thumbnail file of the document.
  ///
  /// [DocumentFile] must exist & must be a file, before calling this method.
  /// Has to have permission [canThumbnail] set to true.
  ///
  /// - [width] Width of the thumbnail, default is 256.
  /// - [height] Height of the thumbnail, default is 256.
  ///
  /// [width] & [height] must be greater than 0.
  ///
  /// - [quality] Quality of the thumbnail, default is 100. Must be between 0 and 100.
  /// - [png] Whether it will save the thumbnail as PNG, otherwise as JPEG.
  /// - [webp] Whether it will save the thumbnail as WebP, otherwise as JPEG.
  ///
  /// [png] & [webp] can't be true at the same time.
  ///
  /// Returns [File] instance of the thumbnail or null if thumbnail is not available.
  /// First it will try to save to external cache directory, if not available, then to internal cache directory.
  /// It's your responsibility to move the file to the permanent location if needed,
  /// otherwise, it will be deleted when the app is closed/destroyed.
  /// Some document providers may not support thumbnail generation.
  /// Added custom thumbnail generation for video & pdf & image files.
  Future<File?> thumbnailFile({
    int width = 256,
    int height = 256,
    int quality = 100,
    bool png = false,
    bool webp = false,
  }) =>
      DocumentFileMethods(this).getThumbnail<File>(
          width: width, height: height, quality: quality, png: png, webp: webp);

// Rename the document (Directory or File).
//
// Very rarely works, due to different document providers & after renaming, the document may not be found.
// - [name] New name for the document.
//
// Returns [DocumentFile] of the renamed document, or null if something went wrong.
// Future<DocumentFile?> rename(String name) => DocumentFileMethods(this).rename(name);
}

/// Contains all supported methods which use `Activity` channel for [DocumentFile] class.
/// {@category DocumentFile}
extension DocumentFileActivityExt on DocumentFile {
  /// Open the document with the default application.
  ///
  /// [DocumentFile] must exist & must be a file, before calling this method.
  ///
  /// - [title] Title of the dialog to show when opening the document.
  /// Title is used on Intent chooser dialog on Android, depends on os version & device,
  /// so it may not be shown on all devices.
  ///
  /// Returns `true` if the document is opened successfully, otherwise `false`.
  Future<bool> open({String? title}) => DocumentFileMethods(this).open(title);

  /// Share the document with other apps.
  ///
  /// [DocumentFile] must exist & must be a file, before calling this method.
  ///
  /// - [title] Title of the dialog to show when sharing the document.
  /// Title is used on Intent chooser dialog on Android, depends on os version & device,
  /// so it may not be shown on all devices.
  ///
  /// Returns `true` if the document is shared successfully, otherwise `false`.
  Future<bool> share({String? title}) => DocumentFileMethods(this).share(title);

  /// Save the document to the selected location.
  ///
  /// [DocumentFile] must exist & must be a file, before calling this method.
  ///
  /// - [initDir] Tree Uri of Initial directory to start from.
  /// If not provided, it will try to use the default directory based on the [DocumentFile] mimeType.
  /// - [localOnly] Whether it will only show local directories, no cloud directories.
  /// - [deleteSource] Whether it will delete this [DocumentFile] after saving it to the selected location.
  ///
  /// Returns [DocumentFile] of the saved document, or null if something went wrong.
  Future<DocumentFile?> saveTo({
    String? initDir,
    bool localOnly = false,
    bool deleteSource = false,
  }) =>
      DocumentFileMethods(this).saveTo(
          initDir: initDir, localOnly: localOnly, deleteSource: deleteSource);
}

/// Contains all supported methods which use `Events` channel (Streams) for [DocumentFile] class.
/// {@category DocumentFile}
extension DocumentFileEventsExt on DocumentFile {
  /// Read the document content as string stream.
  ///
  /// [DocumentFile] must exist & must be a file, before calling this method.
  ///
  /// - [charset] Used to set the charset for reading the file, default is 'UTF-8'.
  /// Can be any charset supported by the platform like ex: 'UTF-8', 'ISO-8859-1', 'UTF-16' etc.
  /// - [bufferSize] Used to set the buffer size for reading the file, default is used from kotlin
  /// `DEFAULT_BUFFER_SIZE` = 8 * 1024 (8KB).
  /// - [start] Sets the start position of the file to read from, default is 0.
  ///
  /// Returns a stream of strings
  Stream<String> readAsString({
    int? bufferSize,
    int start = 0,
    String charset = 'UTF-8',
  }) =>
      DocumentFileMethods(this)
          .readAsString(charset, bufferSize: bufferSize, start: start);

  /// Read the document content as bytes stream.
  ///
  /// [DocumentFile] must exist & must be a file, before calling this method.
  ///
  /// - [bufferSize] Used to set the buffer size for reading the file, default is used from kotlin
  /// `DEFAULT_BUFFER_SIZE` = 8 * 1024 (8KB).
  /// - [start] Sets the start position of the file to read from, default is 0.
  ///
  /// Returns a stream of bytes
  Stream<Uint8List> readAsBytes({int? bufferSize, int start = 0}) =>
      DocumentFileMethods(this)
          .readAsBytes(bufferSize: bufferSize, start: start);

  /// List the documents in the directory.
  ///
  /// Same as [DocumentFileActionsExt.listDocuments] but as a stream.
  Stream<DocumentFile> listDocumentsStream({
    List<String> mimeTypes = const [],
    List<String> extensions = const [],
    String? nameContains,
  }) =>
      DocumentFileMethods(this).listStream(
          mimeTypes: mimeTypes,
          extensions: extensions,
          nameContains: nameContains);
}
