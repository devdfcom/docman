import 'dart:typed_data';

import 'package:docman/docman.dart';
import 'package:flutter/material.dart';

/// A class that represents a document thumbnail.
/// {@category DocumentFile}
@immutable
class DocumentThumbnail {
  /// The bytes of the thumbnail.
  final Uint8List bytes;

  /// The width of the thumbnail.
  final int width;

  /// The height of the thumbnail.
  final int height;

  /// Constructs a [DocumentThumbnail] instance.
  const DocumentThumbnail({
    required this.bytes,
    required this.width,
    required this.height,
  });

  /// Creates a [DocumentThumbnail] instance from a map.
  factory DocumentThumbnail.fromMap(Map<String, dynamic> map) =>
      DocumentThumbnail(
        bytes: map['bytes'] as Uint8List,
        width: map['width'] as int,
        height: map['height'] as int,
      );

  /// Instantiates a [DocumentThumbnail] from a Content URI or a File path.
  ///
  /// [uri] - can be `Content Uri` saved from previous request with persisted permission,
  /// or it can be app local `File.path`
  ///
  /// - [width] Width of the thumbnail, default is 256.
  /// - [height] Height of the thumbnail, default is 256.
  ///
  /// [width] & [height] must be greater than 0.
  ///
  /// - [quality] Quality of the thumbnail, default is 100. Must be between 0 and 100.
  /// - [png] Whether it will compress the thumbnail as PNG, otherwise as JPEG.
  /// - [webp] Whether it will compress the thumbnail as WebP, otherwise as JPEG.
  ///
  /// [png] & [webp] can't be true at the same time.
  ///
  /// Returns thumbnail as [DocumentThumbnail] or null if thumbnail is not available.
  /// Sometimes due to different document providers, thumbnail can have bigger dimensions, than requested.
  /// Some document providers may not support thumbnail generation.
  /// Added custom thumbnail generation for video & pdf & image files.
  static Future<DocumentThumbnail?> fromUri(
    String uri, {
    int width = 256,
    int height = 256,
    int quality = 100,
    bool png = false,
    bool webp = false,
  }) =>
      DocumentFile(uri: uri, exists: true, canThumbnail: true).thumbnail();

  /// Converts the instance to a map.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'bytes': bytes,
        'width': width,
        'height': height,
      };

  @override
  String toString() =>
      'DocumentThumbnail(bytes: ${bytes.length}, width: $width, height: $height)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentThumbnail &&
        other.bytes == bytes &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height, bytes);
}
