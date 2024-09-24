import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'docman_method_channel.dart';

abstract class DocmanPlatform extends PlatformInterface {
  /// Constructs a DocmanPlatform.
  DocmanPlatform() : super(token: _token);

  static final Object _token = Object();

  static DocmanPlatform _instance = MethodChannelDocman();

  /// The default instance of [DocmanPlatform] to use.
  ///
  /// Defaults to [MethodChannelDocman].
  static DocmanPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DocmanPlatform] when
  /// they register themselves.
  static set instance(DocmanPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
