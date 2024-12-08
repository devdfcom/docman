import 'package:docman/src/exceptions/app_dir_path.dart';
import 'package:docman/src/exceptions/common_exceptions.dart';
import 'package:docman/src/exceptions/document_file_exception.dart';
import 'package:docman/src/exceptions/permissions_exceptions.dart';
import 'package:docman/src/exceptions/picker_exceptions.dart';
import 'package:flutter/services.dart' show PlatformException;

/// Extensions for [PlatformException] class.
extension PlatformExceptionExt on PlatformException {
  /// Throws a custom exception based on the error [code].
  ///
  /// If the [code] is 'already_running', it throws an [AlreadyRunningException]
  /// with the provided [message]. For any other [code] not in list, it rethrows the original
  /// [PlatformException].
  Never throwByCode() => switch (code) {
        AlreadyRunningException.tag => throw AlreadyRunningException(message),
        NoActivityException.tag => throw NoActivityException(message),
        AppDirPathException.tag => throw AppDirPathException(message),
        AppDirActionException.tag => throw AppDirActionException(message),
        PickerMimeTypeException.tag => throw PickerMimeTypeException(message),
        PickerMaxLimitException.tag => throw PickerMaxLimitException(message),
        PickerCountException.tag =>
          throw PickerCountException(message, details as String),
        DocumentFileException.tag => throw DocumentFileException(message),
        PermissionsException.tag => throw PermissionsException(message),
        _ => throw this,
      };
}
