import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'docman_platform_interface.dart';

/// An implementation of [DocmanPlatform] that uses method channels.
class MethodChannelDocman extends DocmanPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('docman');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
