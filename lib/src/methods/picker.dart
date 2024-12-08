import 'dart:io';

import 'package:docman/docman.dart';
import 'package:docman/src/channels/activity_channel.dart';

/// Used for setting proper result when limit is used
enum PickLimitResult {
  /// Returns only items till the limit is reached
  limited,

  /// Result will be successful with empty list
  empty,

  /// Return error, throws an exception when limit is reached
  cancel,

  /// Restart the picker with a toast message about the limit
  restart
}

///Defines the type of pick
enum PickType { directory, documents, files, media }

///Set of parameters to control pick type
class PickTypeFilter {
  ///List of mime types to filter
  final List<String> mimeTypes;

  ///List of extensions to filter
  final List<String> extensions;

  ///Creates a new instance of [PickTypeFilter]
  const PickTypeFilter({this.mimeTypes = const [], this.extensions = const []});

  Map<String, dynamic> get args => <String, dynamic>{
        'mimeTypes': mimeTypes,
        'extensions': extensions.any((e) => e.contains('.'))
            ? extensions.map((it) => it.replaceAll('.', '')).toList()
            : extensions,
      };
}

///Set of parameters to control pick limit
class PickLimit {
  ///The maximum number of items to pick
  final int limit;

  ///The type of result when limit is reached
  final PickLimitResult type;

  ///The toast message to show when limit result is restart
  final String? toastText;

  ///Creates a new instance of [PickLimit]
  const PickLimit(this.limit, {PickLimitResult? type, this.toastText})
      : type = type ?? PickLimitResult.limited;

  ///Returns the arguments for the limit
  Map<String, dynamic> get args => <String, dynamic>{
        'limit': limit,
        'limitType': type.name,
        'limitToast': switch (type) {
          PickLimitResult.restart => toastText ?? 'Pick maximum $limit items',
          _ => null,
        },
      };
}

///Set of parameters to control visual media picker
class PickMedia {
  ///The quality of the image, used for compression (0-100), for jpeg & webp
  final int quality;

  ///Use Android Photo Picker instead of Document Picker if available
  final bool useVisualMediaPicker;

  ///Creates a new instance of [PickMedia]
  const PickMedia({
    this.quality = 100,
    this.useVisualMediaPicker = true,
  }) : assert(quality >= 0 && quality <= 100,
            'Invalid image quality, must be between 0 and 100');

  ///Returns the arguments for the media
  Map<String, dynamic> get args => <String, dynamic>{
        'imageQuality': quality,
        'usePhotoPicker': useVisualMediaPicker
      };
}

///Entry point for picking files, directories and media
class Picker {
  ///The type of pick
  final PickType type;

  ///The filter for the pick
  final PickTypeFilter filter;

  ///The limit for the pick
  final PickLimit limit;

  ///The media settings for the pick
  final PickMedia media;

  ///Only show local files
  final bool localOnly;

  ///Initial directory to start from
  final String? initDir;

  ///Whether to grant persisted permissions
  final bool grantPermissions;

  ///Creates a new instance of [Picker]
  const Picker({
    required this.type,
    this.filter = const PickTypeFilter(),
    this.limit = const PickLimit(1),
    this.media = const PickMedia(),
    this.localOnly = false,
    this.grantPermissions = false,
    this.initDir,
  });

  ///Returns the name of the method
  String get _name => 'pickactivity';

  /// Final arguments for the picker
  Map<String, dynamic> get arguments => <String, dynamic>{
        'type': type.name,
        ...filter.args,
        'localOnly': localOnly,
        'grantPermissions': grantPermissions,
        ...limit.args,
        ...media.args,
        'initDir': initDir,
      };

  ///Pick directory as DocumentFile
  Future<DocumentFile?> directory() async {
    final result = await _onMethodResult<Map<dynamic, dynamic>>();
    return result != null ? DocumentFile.fromMap(Map.from(result)) : null;
  }

  ///Pick list of DocumentFiles
  Future<List<DocumentFile>> documents() async {
    final result = await _onMethodResult<List<dynamic>>();
    return result != null
        ? result
            .cast<Map<dynamic, dynamic>>()
            .map((it) => DocumentFile.fromMap(Map.from(it)))
            .toList()
        : [];
  }

  ///Pick files
  Future<List<File>> files() async {
    final result = await _onMethodResult<List<dynamic>>();
    return result != null ? result.cast<String>().map(File.new).toList() : [];
  }

  Future<T?> _onMethodResult<T>() =>
      ActivityChannel.instance.call<T>(_name, arguments);
}
