import 'package:docman/src/exceptions/docman_base_exception.dart';

/// Exception thrown for invalid mimeType.
///
/// When the mimeType is not valid for `DocMan.pick.visualMedia(mimyType:)` method.
///
/// {@category Exceptions}
class PickerMimeTypeException implements DocManException {
  /// The name of mimeType that is invalid.
  final String? mimyType;

  /// Representing corresponding `PlatformException` error code.
  static const tag = 'picker_mimetype';

  /// Creates a new instance of [PickerMimeTypeException].
  const PickerMimeTypeException(this.mimyType);

  @override
  String toString() => 'Invalid mimeType: $mimyType';

  @override
  String get code => tag;
}

/// Exception thrown for invalid limit.
///
/// When `limit` is greater than max allowed by the platform.
/// For method `DocMan.pick.visualMedia(limit:)`.
///
/// {@category Exceptions}
class PickerMaxLimitException implements DocManException {
  /// Max allowed limit
  final String? limit;

  /// Representing corresponding `PlatformException` error code.
  static const tag = 'picker_max_limit';

  /// Creates a new instance of [PickerMaxLimitException].
  const PickerMaxLimitException(this.limit);

  @override
  String toString() => 'Limit param must be less or equal to $limit';

  @override
  String get code => tag;
}

/// Exception thrown when picked items count is greater than allowed limit.
///
/// For `DocMan.pick` methods that have `limit` parameter.
/// Thrown when you set picker parameter `limitResultCancel` to `true`.
/// For example when you pick 5 files, but `limit` is set to 3 and `limitResultCancel` is `true`.
///
/// {@category Exceptions}
class PickerCountException implements DocManException {
  /// Picked items count
  final String? count;

  /// The limit that is invalid.
  final String? limit;

  /// Representing corresponding `PlatformException` error code.
  static const tag = 'picker_count';

  /// Creates a new instance of [PickerCountException].
  ///
  /// The [limit] parameter is the limit that is invalid.
  const PickerCountException(this.limit, this.count);

  @override
  String toString() => 'Picked: $count, but limit is: $limit';

  @override
  String get code => tag;
}
