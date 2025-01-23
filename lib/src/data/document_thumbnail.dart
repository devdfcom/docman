import 'dart:typed_data';

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

  //TODO get thumbnail directly from filePath or Uri

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
