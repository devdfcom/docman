import 'package:docman/docman.dart';
import 'package:flutter/material.dart';

/// Representation of `UriPermission` on dart side.
/// {@category Permissions}
@immutable
class PersistedPermission {
  /// The URI of the permission, usually a document content URI.
  final String uri;

  /// Whether the permission allows read access.
  final bool read;

  /// Whether the permission allows write access.
  final bool write;

  /// The time when the permission was granted.
  final int time;

  /// Constructs a [PersistedPermission] instance.
  const PersistedPermission({required this.uri, this.read = false, this.write = false, this.time = 0});

  /// Creates a [PersistedPermission] instance from a map.
  factory PersistedPermission.fromMap(Map<String, dynamic> map) => PersistedPermission(
        uri: map['uri'] as String,
        read: map['read'] as bool,
        write: map['write'] as bool,
        time: map['time'] as int,
      );

  /// The date when the permission was granted.
  DateTime? get date => time > 0 ? DateTime.fromMillisecondsSinceEpoch(time) : null;

  /// Releases the permission.
  Future<bool> release() => DocMan.perms.release(uri);

  /// Converts the instance to a map.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'uri': uri,
        'read': read,
        'write': write,
        'time': time,
      };

  @override
  String toString() => 'PersistedPermission(uri: $uri, read: $read, write: $write, time: $time, date: $date)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersistedPermission &&
          uri == other.uri &&
          read == other.read &&
          write == other.write &&
          time == other.time;

  @override
  int get hashCode => Object.hash(uri, read, write, time);
}
