/// Base class for all custom exceptions in the `docman` package
/// {@category Exceptions}
abstract interface class DocManException implements Exception {
  /// Representing corresponding `PlatformException` error code.
  final String code;

  /// Creates a new instance of [DocManException].
  ///
  /// The [code] parameter is the error message.
  const DocManException(this.code);

  @override
  String toString();
}
