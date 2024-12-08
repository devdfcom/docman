import 'package:docman/src/exceptions/docman_base_exception.dart';

/// Exceptions thrown by executing permissions operations.
///
/// {@category Permissions}
/// {@category Exceptions}
class PermissionsException implements DocManException {
  /// The error message.
  final String? message;

  /// Representing corresponding `PlatformException` error code.
  static const tag = 'permissions';

  /// Creates a new instance of [PermissionsException].
  const PermissionsException(this.message);

  @override
  String toString() => message ?? 'Permissions operation failed';

  @override
  String get code => tag;
}
