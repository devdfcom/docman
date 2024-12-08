import 'package:docman/docman.dart';

/// Exceptions thrown by executing document file operations.
///
/// {@category DocumentFile}
/// {@category Exceptions}
class DocumentFileException implements DocManException {
  /// The error message.
  final String? message;

  /// Representing corresponding `PlatformException` error code.
  static const tag = 'document_file';

  /// Creates a new instance of [DocumentFileException].
  const DocumentFileException(this.message);

  @override
  String toString() => message ?? 'Document file operation failed';

  @override
  String get code => tag;
}
