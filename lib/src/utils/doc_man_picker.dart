import 'dart:io' show File;

import 'package:docman/src/data/document_file.dart';
import 'package:docman/src/methods/picker.dart';

/// Provides a simple way to pick files, documents and directories.
/// {@category DocMan}
class DocManPicker {
  /// Pick a directory.
  ///
  /// This will also grant the necessary permissions to access the directory by the app.
  ///
  /// - [initDir] The initial directory to start picking from.
  /// This is optional, must be a valid string representation of `tree Uri` - directory uri.
  ///
  /// Returns a [DocumentFile] representing the picked directory.
  Future<DocumentFile?> directory({String? initDir}) => Picker(type: PickType.directory, initDir: initDir).directory();

  /// Pick document(s).
  ///
  /// Allows to pick single or multiple documents.
  ///
  /// - [initDir] The initial directory to start picking from, must be a valid string representation of `tree Uri` - directory uri.
  /// If not provided, picker will try to guess the best directory to start from by `mimeTypes` and `extensions`.
  ///
  /// - [mimeTypes] The list of MIME types to filter the documents.
  /// Example: `['image/*', 'audio/*']` or specific MIME types like `['application/pdf']`.
  /// - [extensions] The list of extensions to filter the documents.
  /// Example: `['pdf', 'docx']`, extension can start with `.` or without it.
  ///
  /// On execution, both [mimeTypes] and [extensions] are combined together in list of supported MIME types.
  ///
  /// - [localOnly] Whether only local documents will be shown, no cloud documents.
  ///
  /// - [grantPermissions] Whether the picker will grant persisted permissions to the picked documents.
  /// This permissions are kept even after the app is closed, or device is rebooted.
  /// In case of using persisted permissions for documents,
  /// you should control the limit of total persisted permissions, due to limited number of permissions allowed.
  ///
  /// - [limit] The maximum number of documents to pick, if limit greater than 1, it will allow to pick multiple documents.
  ///Due to limit is not supported on Android, we simulate the limit by checking the number of picked files.
  ///There are different ways to handle the limit (when it's greater than 1), you can choose one of them:
  ///[limitResultEmpty], [limitResultCancel], [limitResultRestart],
  ///default is `limited` - this will allow to pick more than limit, but will return only limited number of files.
  /// - [limitResultEmpty] Whether the picker will return an empty list, if user pick items over the limit.
  /// - [limitResultCancel] Cancel with an error, error message will contain only count of picked items.
  /// - [limitResultRestart] Restart the picker with a toast message, if user pick items over the limit.
  /// - [limitRestartToastText] The toast message to show when picker is restarted,
  ///default is `Pick maximum $limit items`.
  ///
  /// Returns a list of [DocumentFile] representing the picked documents.
  /// After picking, you can get the list of picked documents, or another result depending on the limit.
  Future<List<DocumentFile>> documents({
    String? initDir,
    List<String> mimeTypes = const [],
    List<String> extensions = const [],
    bool localOnly = false,
    bool grantPermissions = false,
    int limit = 1,
    bool limitResultEmpty = false,
    bool limitResultCancel = false,
    bool limitResultRestart = false,
    String? limitRestartToastText,
  }) =>
      Picker(
        type: PickType.documents,
        initDir: initDir,
        filter: _filter(mimeTypes: mimeTypes, extensions: extensions),
        localOnly: localOnly,
        grantPermissions: grantPermissions,
        limit: _limit(
          limit,
          empty: limitResultEmpty,
          cancel: limitResultCancel,
          restart: limitResultRestart,
          toastText: limitRestartToastText,
        ),
      ).documents();

  /// Pick file(s).
  ///
  /// Allows to pick single or multiple files.
  ///
  /// - [initDir] The initial directory to start picking from,
  /// must be a valid string representation of `tree Uri` - directory uri.
  /// If not provided, picker will try to guess the best directory to start from by `mimeTypes` and `extensions`.
  ///
  ///
  /// - [mimeTypes] The list of MIME types to filter the files.
  /// Example: `['image/*', 'audio/*']` or specific MIME type like `['application/pdf']`.
  /// - [extensions] The list of extensions to filter the documents.
  /// Example: `['pdf', '.docx']`, extension can start with `.` or without it.
  ///
  ///   - On execution, both [mimeTypes] and [extensions] are combined together in list of supported MIME types.
  ///
  /// - [localOnly] Whether only local files will be shown, no cloud files.
  /// - [limit] The maximum number of files to pick, if limit greater than 1, it will allow to pick multiple files.
  ///Due to limit is not supported on Android (only Photo picker - PickVisualMedia has limit),
  ///We simulate the limit by checking the number of picked files.
  ///There are different ways to handle the limit (when it's greater than 1), you can choose one of them:
  ///[limitResultEmpty], [limitResultCancel], [limitResultRestart],
  ///default is `limited` - this will allow to pick more than limit, but will return only limited number of files.
  /// - [limitResultEmpty] Whether the picker will return an empty list, if user pick items over the limit.
  /// - [limitResultCancel] Cancel with an error, error message will contain only count of picked items.
  /// - [limitResultRestart] Restart the picker with a toast message, if user pick items over the limit.
  /// - [limitRestartToastText] The toast message to show when picker is restarted,
  ///default is `Pick maximum $limit items`
  ///
  /// Returns a list of [File] representing the picked files.
  /// After picking, the files will be copied to the cache directory,
  /// first it will try to copy to external cache directory, if not available, then to internal cache directory.
  /// It's your responsibility to move the files to the desired directory,
  /// Otherwise, the files will be deleted when the app is closed/destroyed.
  Future<List<File>> files({
    String? initDir,
    List<String> mimeTypes = const [],
    List<String> extensions = const [],
    bool localOnly = false,
    int limit = 1,
    bool limitResultEmpty = false,
    bool limitResultCancel = false,
    bool limitResultRestart = false,
    String? limitRestartToastText,
  }) =>
      Picker(
        type: PickType.files,
        initDir: initDir,
        filter: _filter(mimeTypes: mimeTypes, extensions: extensions),
        localOnly: localOnly,
        limit: _limit(
          limit,
          empty: limitResultEmpty,
          cancel: limitResultCancel,
          restart: limitResultRestart,
          toastText: limitRestartToastText,
        ),
      ).files();

  /// Pick visual media files like images, video files.
  ///
  /// ### Android PhotoPicker (VisualMediaPicker)
  /// On Android, it will try to use the visual media picker (photo picker) if it's available.
  /// It allows to pick images and videos only, There are some requirements to use the visual media picker:
  ///
  /// - The device should support [android photo picker](https://developer.android.com/training/data-storage/shared/photopicker).
  /// - Set proper mimeTypes. Supported values: `[image/*]`, `[video/*]`,
  /// empty list - `[]`, or specific mimeType like `['image/jpeg']`, `['video/mp4']`.
  /// - If you will use both `extensions` and `mimeTypes`, it will be combined together, however if resulting mimeTypes list
  /// is not equals to supported values, it will not use the visual media picker.
  ///
  /// ### Filter parameters
  /// - [initDir] The initial directory to start picking from,
  /// must be a valid string representation of `tree Uri` - directory uri.
  /// If not provided, picker will try to guess the best directory to start from by `mimeTypes` and `extensions`.
  /// - [localOnly] Whether only local files will be shown, no cloud files.
  ///
  /// - [mimeTypes] The list of MIME types to filter the media files.
  /// Example: `['image/*']` or specific MIME type like `['video/mp4']`.
  /// - [extensions] The list of extensions to filter the media files.
  /// Example: `['jpg', '.png', 'webp']`, extension can start with `.` or without it.
  ///
  ///   - On execution, both [mimeTypes] and [extensions] are combined together in list of supported MIME types.
  ///   - If both `mimeTypes` and `extensions` are empty, it will allow to pick any images and videos.
  /// ### Media parameters
  /// - [imageQuality] The quality of the image, a value between 0 and 100,
  /// where 100 means the highest quality, and 0 means the lowest quality, used only for images.
  /// Currently only JPEG & WEBP images support compression, PNG images will be copied as is.
  /// - [useVisualMediaPicker] By default it will try to use the Android PhotoPicker, if it's available.
  /// Even if it's true, it's not guaranteed that it will be used, because it depends on proper mimeTypes,
  /// and the device system support. Allows to disable it, if you want to use the default files picker.
  ///
  /// ### Limit parameters
  /// - [limit] The maximum number of files to pick, if limit greater than 1, it will allow to pick multiple.
  /// Android PhotoPicker supports `limit` and it's not allow to pick more than limit,
  /// however, if it uses system file picker (max limit is set to 100).
  /// We simulate the limit by checking the number of picked files for system file picker.
  /// There are different ways to handle the limit (when it's greater than 1), you can choose one of them:
  /// [limitResultEmpty], [limitResultCancel], [limitResultRestart],
  /// default is `limited` - this will allow to pick more than limit, but will return only limited number of files.
  /// - [limitResultEmpty] Whether the picker will return an empty list, if user pick items over the limit.
  /// - [limitResultCancel] Cancel with an error, error message will contain only count of picked items.
  /// - [limitResultRestart] Restart the picker with a toast message, if user pick items over the limit.
  /// - [limitRestartToastText] The toast message to show when picker is restarted,
  /// default is `Pick maximum $limit items`
  ///
  /// Returns a list of [File] representing the picked visual media files.
  /// After picking, the files will be copied to the temporary cache directory,
  /// It's your responsibility to move the files to the desired directory,
  /// Otherwise, the files will be deleted when the app is closed/destroyed.
  Future<List<File>> visualMedia({
    String? initDir,
    List<String> mimeTypes = const [],
    List<String> extensions = const [],
    int imageQuality = 100,
    bool useVisualMediaPicker = true,
    bool localOnly = false,
    int limit = 1,
    bool limitResultEmpty = false,
    bool limitResultCancel = false,
    bool limitResultRestart = false,
    String? limitRestartToastText,
  }) {
    assert(mimeTypes.isEmpty || mimeTypes.every((m) => m.startsWith(RegExp('image|video'))),
        'mimeTypes can starts only with "image/" or "video/"');
    return Picker(
      type: PickType.media,
      initDir: initDir,
      filter: _filter(mimeTypes: mimeTypes, extensions: extensions),
      localOnly: localOnly,
      limit: _limit(
        limit,
        empty: limitResultEmpty,
        cancel: limitResultCancel,
        restart: limitResultRestart,
        toastText: limitRestartToastText,
      ),
      media: _media(quality: imageQuality, useVisualMediaPicker: useVisualMediaPicker),
    ).files();
  }

  ///Constructs a [PickLimit] object with the given limit and result.
  ///
  ///Used to control the limit of picked files/documents/media for system file picker.
  ///
  ///Due to limit is not supported on Android (only PhotoPicker has limit),
  ///We simulate the limit by checking the number of picked files.
  ///There are different ways to handle the limit, you can choose one of them:
  ///[empty], [cancel], [restart],
  ///default is `limited` - this will allow to pick more than limit, but will return only limit number of files.
  ///
  /// - [limit] The maximum number of items to pick, must be greater than 0.
  /// - [empty] If true, the picker will return an empty list, if user picker more than limit.
  /// - [cancel] Cancel with an error, error message will contain only count of picked items.
  /// - [restart] Restart the picker with a toast message, if user picked more than limit.
  /// - [toastText] The toast message to show when picker is restarted,
  /// default is `Pick maximum $limit items`
  PickLimit _limit(
    int limit, {
    bool empty = false,
    bool cancel = false,
    bool restart = false,
    String? toastText,
  }) {
    assert(limit > 0, 'Limit must be greater than 0');
    assert(
      [empty, cancel, restart].where((e) => e).length <= 1,
      'Only one limitResult type can be true, or none of them',
    );

    var limitResult = PickLimitResult.limited;

    if (empty) {
      limitResult = PickLimitResult.empty;
    } else if (cancel) {
      limitResult = PickLimitResult.cancel;
    } else if (restart) {
      limitResult = PickLimitResult.restart;
    }

    return PickLimit(limit, type: limitResult, toastText: toastText);
  }

  PickTypeFilter _filter({List<String> mimeTypes = const [], List<String> extensions = const []}) =>
      PickTypeFilter(mimeTypes: mimeTypes, extensions: extensions);

  PickMedia _media({int quality = 100, bool useVisualMediaPicker = true}) =>
      PickMedia(quality: quality, useVisualMediaPicker: useVisualMediaPicker);
}
