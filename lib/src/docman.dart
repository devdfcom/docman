import 'package:docman/src/utils/doc_man_app_dirs.dart';
import 'package:docman/src/utils/doc_man_permissions.dart';
import 'package:docman/src/utils/doc_man_picker.dart';

/// Helper for the document manager plugin.
///
/// Contains the [DocManPicker], [DocManAppDirs], and [DocManPermissionManager] instances.
/// Allows to access them via the [pick], [dir], and [perms] properties.
///
/// ```dart
/// DocMan.pick.directory();
/// DocMan.dir.cache();
/// DocMan.perms.list();
/// ```
///
///{@category DocMan}
class DocMan {
  /// [DocManPicker] for the picker methods, like `directory`, `documents`, and `files`.
  static final pick = DocManPicker();

  /// [DocManAppDirs] for the application directories, like `cache`, `files`, `data`, `cacheExt`, and `filesExt`,
  /// or get all directories at once with `all` method.
  static final dir = DocManAppDirs();

  /// [DocManPermissionManager] for the persisted permission manager.
  static final perms = DocManPermissionManager();
}
