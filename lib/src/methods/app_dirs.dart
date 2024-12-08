import 'dart:io';

import 'package:docman/src/channels/action_channel.dart';

/// Enum class that provides access to the application directories.
///
/// The application directories are:
/// - `cache`: The directory for storing temporary cache files.
/// Example: /data/user/0/com.example.app/cache
/// - `files`: The directory for storing files, rarely used.
/// Example: /data/user/0/com.example.app/files
/// - `data`: Default Directory for storing data files of the app.
/// Example: /data/user/0/com.example.app/app_flutter
/// - `cacheExt`: The directory for storing temporary cache files on external storage.
/// Example: /storage/emulated/0/Android/data/com.example.app/cache
/// - `filesExt`: The directory for storing files on external storage.
/// Example: /storage/emulated/0/Android/data/com.example.app/files
enum AppDir {
  /// The directory for storing temporary cache files.
  cache,

  /// The directory for storing files, rarely used.
  files,

  /// Default Directory for storing data files of the app.
  data,

  /// The directory for storing temporary cache files on external storage.
  cacheExt,

  /// The directory for storing files on external storage.
  filesExt;

  /// Get AppDir from a string value, if not found, return [AppDir.cache].
  static AppDir fromString(String value) =>
      AppDir.values.firstWhere((e) => e.name.toLowerCase() == value, orElse: () => AppDir.cache);

  /// Get Path of the AppDir.
  Future<String?> getPath() => _onMethodResult<String>(_args('path'));

  /// Clear Directory.
  ///
  /// Currently, only the `cache` directory can be cleared, others will not do anything.
  /// Call as `AppDir.cache.clear()` - this will not clear entire cache directory,
  /// only the temp directories created by the plugin like `docManMedia` and `docMan`
  /// in external & internal cache directories if exists.
  ///
  /// Returns `true` if the directory was cleared successfully, otherwise `false`.
  Future<bool> clear() async => await _onMethodResult<bool>(_args('clear')) ?? false;

  /// Get [Directory] by path
  Future<Directory?> asDir() async {
    final path = await getPath();
    return path != null ? Directory(path) : null;
  }

  String get _methodName => 'appdirs';

  Map<String, dynamic> _args(String action) => <String, dynamic>{'dir': name.toLowerCase(), 'action': action};

  Future<T?> _onMethodResult<T>([dynamic args]) => ActionChannel.instance.call<T>(_methodName, args);
}
