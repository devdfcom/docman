import 'package:docman/docman.dart';
import 'package:flutter/material.dart';

/// A class representing a `DocumentFile` on dart side.
///
/// {@category DocumentFile}
@immutable
class DocumentFile {
  /// The name of the document. `DISPLAY_NAME` - The display name of the document.
  final String name;

  /// Represents the MIME type of the document.
  /// If the MIME type is not available, this will be `unknown`.
  /// If this is a directory, this will be `directory`.
  final String type;

  /// The String representation of the document `Uri`.
  final String uri;

  /// Represents the size of the document in bytes.
  /// If it's File & size is 0, means it's an empty file or size is unknown.
  /// If the document is a directory, this will store count of documents in the directory.
  final int size;

  /// Represents the last modified date and time of the document in milliseconds since epoch.
  /// If the last modified date is not available, this will be 0.
  final int lastModified;

  /// Whether the document exists or not.
  final bool exists;

  /// Whether the document can be read.
  final bool canRead;

  /// Whether it's possible to write to the document.
  final bool canWrite;

  /// Whether the document can be deleted.
  final bool canDelete;

  /// Whether the document can create a new document.
  /// If it's a directory, it can create a new directory or file.
  final bool canCreate;

  /// Whether the document can generate a thumbnail.
  final bool canThumbnail;

  // final bool canRename;

  /// Constructs a [DocumentFile] instance.
  const DocumentFile({
    required this.uri,
    this.name = 'unknown',
    this.type = 'unknown',
    this.size = 0,
    this.lastModified = 0,
    this.exists = false,
    this.canRead = true,
    this.canWrite = false,
    this.canDelete = false,
    this.canCreate = false,
    this.canThumbnail = false,
    // required this.canRename,
  });

  /// Creates a [DocumentFile] instance from a map.
  ///
  /// The [map] parameter must contain the following keys:
  /// - `name`: [String] representing the document's display name.
  /// - `type`: [String] representing the MIME type of the document.
  /// - `uri`: [String] representation of the document URI.
  /// - `size`: [int] representing the size of the document in bytes or count of documents in the directory.
  /// - `lastModified`: [int] representing the last modified date and time in milliseconds since epoch.
  /// Can be 0 if not available.
  /// - `exists`: [bool] whether the document exists or not.
  /// - `canRead`: [bool] whether the document can be read.
  /// - `canWrite`: [bool] whether it's possible to write to the document.
  /// - `canDelete`: [bool] whether the document can be deleted.
  /// - `canCreate`: [bool] whether the document can create a new document.
  /// - `canThumbnail`: [bool] whether the document can generate a thumbnail.
  /// Returns a [DocumentFile] instance.
  factory DocumentFile.fromMap(Map<String, dynamic> map) => DocumentFile(
        name: map['name'] as String,
        type: map['type'] as String? ?? 'unknown',
        uri: map['uri'] as String,
        size: map['size'] as int,
        lastModified: map['lastModified'] as int,
        exists: map['exists'] as bool,
        canRead: map['canRead'] as bool,
        canWrite: map['canWrite'] as bool,
        canDelete: map['canDelete'] as bool,
        // canRename: map['canRename'] as bool,
        canCreate: map['canCreate'] as bool,
        canThumbnail: map['canThumbnail'] as bool,
      );

  /// Instantiates a [DocumentFile] from a Content URI or a File path.
  ///
  /// Same as `DocumentFile(uri: uri).get()`, just syntactic sugar.
  ///
  /// **Note**: Or you can use old method `DocumentFile(uri: uri).get()` to get the `DocumentFile` instance.
  ///
  /// Returns a [DocumentFile] instance or `null` if the document is not available.
  static Future<DocumentFile?> fromUri(String uri) =>
      DocumentFile(uri: uri).get();

  /// Checks if the document is a directory.
  bool get isDirectory => type == 'directory';

  /// Checks if the document is a file.
  bool get isFile => !isDirectory;

  /// Returns the last modified date and time of the document.
  /// If the last modified date is not available, this will be `null`.
  DateTime? get lastModifiedDate => lastModified == 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(lastModified);

  /// Converts the [DocumentFile] instance to a map.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'type': type,
        'uri': uri,
        'size': size,
        'lastModified': lastModified,
        'exists': exists,
        'canRead': canRead,
        'canWrite': canWrite,
        'canDelete': canDelete,
        'canCreate': canCreate,
        'canThumbnail': canThumbnail,
        // 'canRename': canRename,
      };

  @override
  String toString() =>
      'DocumentFile(name: $name, type: $type, uri: $uri, size: $size, lastModified: $lastModified,'
      ' lastModifiedDate: $lastModifiedDate, exists: $exists, isDirectory: $isDirectory, isFile: $isFile, '
      'canRead: $canRead, canWrite: $canWrite, canDelete: $canDelete, canCreate: $canCreate, '
      'canThumbnail: $canThumbnail)';

//canRename: $canRename,

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentFile &&
          name == other.name &&
          type == other.type &&
          uri == other.uri &&
          size == other.size &&
          lastModified == other.lastModified &&
          exists == other.exists;

  @override
  int get hashCode => Object.hash(name, type, uri, size, lastModified, exists);
}
