import 'package:docman/src/exceptions/docman_base_exception.dart';

/// Exception thrown when platform tries to get path for a directory.
///
/// {@category Exceptions}
class AppDirPathException implements DocManException {
  /// The name of the directory for which the path is being requested.
  final String dirName;

  /// Representing corresponding `PlatformException` error code.
  static const tag = 'app_dirs_path';

  /// Creates a new instance of [AppDirPathException].
  ///
  /// The [name] parameter is the name of the directory for which the path is being requested.
  /// If [name] is not provided, the default value is `undefined`.
  const AppDirPathException([String? name]) : dirName = name ?? 'undefined';

  @override
  String toString() => 'Cannot get path for $dirName directory';

  @override
  String get code => tag;
}

/// Exception thrown when platform tries to perform unimplemented action.
///
/// {@category Exceptions}
class AppDirActionException implements DocManException {
  /// The name of the action that is not implemented.
  final String? action;

  /// Representing corresponding `PlatformException` error code.
  static const tag = 'app_dirs_action';

  /// Creates a new instance of [AppDirActionException].
  ///
  /// The [actionName] parameter is the name of the action that is not implemented.
  const AppDirActionException([String? actionName]) : action = actionName;

  @override
  String toString() => 'Method $action is not implemented for directories';

  @override
  String get code => tag;
}
