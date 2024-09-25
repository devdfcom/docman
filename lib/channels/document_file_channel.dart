import 'package:docman/channels/channel_names.dart';
import 'package:docman/channels/document_file_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An implementation of [DocumentFileApi] that uses method channels.
class DocumentFileChannel extends DocumentFileApi {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(ChannelName.documentFile);

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
