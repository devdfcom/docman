import 'package:docman/src/exceptions/docman_base_exception.dart';

/// Exception thrown when a same method is already running,
/// and the user tries to run it again, without waiting for the first one to finish.
///
/// {@category Exceptions}
class AlreadyRunningException implements DocManException {
  /// The name of the method that is already in progress.
  final String methodName;

  /// Representing corresponding `PlatformException` error code.
  static const tag = 'already_running';

  /// Creates a new instance of [AlreadyRunningException].
  ///
  /// The [name] parameter is the name of the method that is already in progress.
  /// If [name] is not provided, the default value is `undefined`.
  const AlreadyRunningException([String? name])
      : methodName = name ?? 'undefined';

  @override
  String toString() => 'AlreadyRunning Method: $methodName';

  @override
  String get code => tag;
}

/// Exception thrown when no activity is found to handle the request.
///
/// {@category Exceptions}
class NoActivityException implements DocManException {
  /// The name of the method that is already in progress.
  final String methodName;

  /// Representing corresponding `PlatformException` error code.
  static const tag = 'no_activity';

  /// Creates a new instance of [NoActivityException].
  ///
  /// The [name] parameter is the name of the method that is already in progress.
  /// If [name] is not provided, the default value is `undefined`.
  const NoActivityException([String? name]) : methodName = name ?? 'undefined';

  @override
  String toString() => 'No apps found to handle the $methodName request';

  @override
  String get code => tag;
}
