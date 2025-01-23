import 'dart:io' show Directory, Platform;

import 'package:docman/docman.dart';

/// A class representing various application directories.
class AppDir {
  /// Creates an instance of [AppDir].
  ///
  /// - [cache] The directory for cached files.
  /// - [files] The directory for storing files, rarely used.
  /// - [data] The directory for application documents.
  /// - [cacheExt] The external directory for cached files (optional).
  /// - [filesExt] The external directory for storing files (optional).
  factory AppDir() => _instance;

  AppDir._internal();

  static final AppDir _instance = AppDir._internal();

  /// The directory for cached files.
  static late Directory cache;

  /// The directory for files.
  static late Directory files;

  /// The directory for application documents.
  static late Directory data;

  /// The external directory for cached files (optional).
  static late Directory? cacheExt;

  /// The external directory for application documents (optional).
  static late Directory? filesExt;

  /// The directory used as root for `Documents Provider` on Android.
  static late Directory provider;

  /// Initializes the application directories.
  ///
  /// This method sets up the directories for application documents, temporary files,
  /// cached files, and external storage. It retrieves these directories using the
  /// `docman` package.
  ///
  /// Returns a Future that completes with the [AppDir] instance.
  Future<AppDir> init() async {
    //1. You can get each directory separately, like this:
    // cache = (await DocMan.dir.cache())!;
    // files = (await DocMan.dir.files())!;
    // data = (await DocMan.dir.data())!;
    // cacheExt = await DocMan.dir.cacheExt();
    // filesExt = await DocMan.dir.filesExt();

    //2. Or you can get all directories at once, like this:
    final dirs = await DocMan.dir.all();
    //2.1. Set the directories from the map
    for (var entry in dirs!.entries) {
      _setDirectoryFromEntry(entry);
    }

    // Initialize the provider directory for future use in the app
    // By this path, you can add files & dirs to the `Documents Provider`
    provider = Directory([
      (filesExt?.path ?? files.path),
      'nested/provider_folder'
    ].join(Platform.pathSeparator));

    //If its nested path create it
    await provider.create(recursive: true);

    return _instance;
  }

  void _setDirectoryFromEntry(MapEntry<String, String> entry) =>
      switch (entry.key) {
        'cache' => cache = Directory(entry.value),
        'files' => files = Directory(entry.value),
        'data' => data = Directory(entry.value),
        'cacheExt' => cacheExt =
            entry.value.isEmpty ? null : Directory(entry.value),
        'filesExt' => filesExt =
            entry.value.isEmpty ? null : Directory(entry.value),
        _ => throw AppDirPathException('Invalid directory entry: ${entry.key}'),
      };

  /// Returns a string representation of the [AppDir] instance.
  ///
  /// This method prints all the application directories.
  @override
  String toString() =>
      'AppDir(cache: ${cache.path}, files: ${files.path}, data: ${data.path}, cacheExt: ${cacheExt?.path}, filesExt: ${filesExt?.path})';
}
