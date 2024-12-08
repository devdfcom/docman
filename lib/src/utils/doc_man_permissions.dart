import 'package:docman/docman.dart';
import 'package:docman/src/channels/action_channel.dart';
import 'package:docman/src/channels/events_channel.dart';

/// A class that provides methods for managing persisted permissions.
///
/// Persisted permissions are permissions that are persisted across app restarts / device reboots.
/// {@category Permissions}
/// {@category DocMan}
class DocManPermissionManager {
  ///Build a map of arguments for the method call.
  Map<String, dynamic> _args(
    String action,
    String? uri, {
    bool dirs = true,
    bool files = true,
  }) =>
      {'action': action, 'uri': uri, 'dirs': dirs, 'files': files};

  Map<String, dynamic> _streamArgs(String action, {bool dirs = true, bool files = true}) =>
      {'method': 'permissionsevent', 'action': action, 'dirs': dirs, 'files': files};

  /// Release a persisted permission for the given [uri].
  Future<bool> release(String uri) async {
    final result = await _methodCall<bool>(_args('release', uri));
    return result ?? false;
  }

  /// Get the permissions status for the DocumentFile [uri].
  Future<PersistedPermission?> status(String uri) async {
    final result = await _methodCall<Map<dynamic, dynamic>>(_args('status', uri));
    return (result is Map) ? PersistedPermission.fromMap(Map.from(result)) : null;
  }

  /// List all persisted permissions.
  ///
  /// [directories] - Whether to include directories in the list.
  /// [files] - Whether to include files in the list.
  Future<List<PersistedPermission>> list({bool directories = true, bool files = true}) async {
    final result = await _methodCall<List<dynamic>>(_args('list', null, dirs: directories, files: files));

    return (result is List)
        ? result.cast<Map<dynamic, dynamic>>().map((it) => PersistedPermission.fromMap(Map.from(it))).toList()
        : [];
  }

  /// List all persisted permissions as a stream.
  ///
  /// Same as [list], but returns a stream of [PersistedPermission] instead of a list.
  Stream<PersistedPermission> listStream({bool directories = true, bool files = true}) =>
      _streamResult(_streamArgs('listStream', dirs: directories, files: files))
          .map((it) => PersistedPermission.fromMap(Map.from(it as Map<dynamic, dynamic>)));

  /// List all DocumentFiles with persisted permissions.
  ///
  /// [directories] - Whether to list directories.
  /// [files] - Whether to list files.
  ///
  /// This method also removes the persisted permissions for the files/directories that no longer exist.
  ///
  /// Returns a list of [DocumentFile] with persisted permissions, or an empty list if
  /// something went wrong.
  Future<List<DocumentFile>> listDocuments({bool directories = true, bool files = true}) async {
    final result = await _methodCall<List<dynamic>>(_args('listDocuments', null, dirs: directories, files: files));

    return (result is List)
        ? result.cast<Map<dynamic, dynamic>>().map((it) => DocumentFile.fromMap(Map.from(it))).toList()
        : [];
  }

  /// List all DocumentFiles with persisted permissions as a stream.
  ///
  /// Same as [listDocuments], but returns a stream of [DocumentFile] instead of a list.
  Stream<DocumentFile> listDocumentsStream({bool directories = true, bool files = true}) =>
      _streamResult(_streamArgs('listDocumentsStream', dirs: directories, files: files))
          .map((it) => DocumentFile.fromMap(Map.from(it as Map<dynamic, dynamic>)));

  /// Validate the persisted permissions list.
  ///
  /// This method checks each persisted permission and removes the ones that are no longer valid.
  /// It converts each persisted permission to a [DocumentFile] and checks if the file/directory exists.
  ///
  /// Returns `true` if the list was validated successfully, otherwise throws an error.
  Future<bool> validateList() async {
    final result = await _methodCall<bool>(_args('validateList', null));
    return result ?? false;
  }

  /// Release all persisted permissions.
  Future<bool> releaseAll() async {
    final result = await _methodCall<bool>(_args('releaseAll', null));
    return result ?? false;
  }

  Future<T?> _methodCall<T>([dynamic args]) => ActionChannel.instance.call<T>('permissions', args);

  Stream<dynamic> _streamResult([dynamic args]) => EventsChannel.instance.listen(args);
}
