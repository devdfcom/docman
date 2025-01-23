import 'dart:io' show Directory;

import 'package:docman/src/methods/app_dirs.dart';

/// Entry point for getting application directories,
/// like `cache`, `files`, `data`, `cacheExt`, and `filesExt`.
/// {@category DocMan}
class DocManAppDirs {
  /// Get Application Cache Directory.
  ///
  /// The directory for storing temporary cache files.
  /// Returns [Directory] with proper path.
  /// Path Example: `/data/user/0/devdf.plugins.docman_example/cache`
  Future<Directory?> cache() => AppDir.cache.asDir();

  /// Get Application Files Directory.
  ///
  /// The directory for storing files, rarely used.
  /// Returns [Directory] with proper path.
  /// Path Example: `/data/user/0/devdf.plugins.docman_example/files`
  Future<Directory?> files() => AppDir.files.asDir();

  /// Get Application Data Directory.
  ///
  /// Default Directory for storing data files of the app.
  /// Returns [Directory] with proper path.
  /// Path Example: `/data/user/0/devdf.plugins.docman_example/app_flutter`
  Future<Directory?> data() => AppDir.data.asDir();

  /// Get Application Cache External Directory.
  ///
  /// The directory for storing temporary cache files on external storage.
  /// Returns [Directory] with proper path.
  /// Path Example: `/storage/emulated/0/Android/data/devdf.plugins.docman_example/cache`
  Future<Directory?> cacheExt() => AppDir.cacheExt.asDir();

  /// Get Application Files External Directory.
  ///
  /// The directory for storing files on external storage.
  /// Returns [Directory] with proper path.
  /// Path Example: `/storage/emulated/0/Android/data/devdf.plugins.docman_example/files`
  Future<Directory?> filesExt() => AppDir.filesExt.asDir();

  /// Clear Temporary Cache Directories.
  ///
  /// Clears only the temp directories created by the plugin like `docManMedia` and `docMan`
  /// in external & internal cache directories if exists.
  ///
  /// Returns `true` if the directories were cleared successfully, otherwise `false`.
  Future<bool> clearCache() => AppDir.cache.clear();

  /// Get all application directories (paths) at once.
  ///
  /// Returns a map of all the app directories.
  /// Only the values of `cacheExt` & `filesExt` can be empty Strings.
  ///
  /// Result Example:
  /// ```dart
  /// {
  ///  "cache": "/data/user/0/devdf.plugins.docman_example/cache",
  ///  "files": "/data/user/0/devdf.plugins.docman_example/files",
  ///  "data": "/data/user/0/devdf.plugins.docman_example/app_flutter",
  ///  "cacheExt": "/storage/emulated/0/Android/data/devdf.plugins.docman_example/cache",
  ///  "filesExt": "/storage/emulated/0/Android/data/devdf.plugins.docman_example/files"
  /// }
  /// ```
  Future<Map<String, String>?> all() => AppDir.all();
}
