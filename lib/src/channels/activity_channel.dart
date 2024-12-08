import 'package:docman/src/extensions/platform_exception_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// An implementation of [PlatformInterface] that uses method channel.
class ActivityChannel extends PlatformInterface {
  /// Constructs a [ActivityChannel] platform interface.
  ActivityChannel() : super(token: _token);

  static final Object _token = Object();

  static ActivityChannel _instance = ActivityChannel();

  /// The default instance of [ActivityChannel] to use.
  ///
  /// Defaults to [ActivityChannel].
  static ActivityChannel get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ActivityChannel] when
  /// they register themselves.
  static set instance(ActivityChannel instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('devdf.plugins/docman/activity');

  Future<T?> call<T>(String name, [dynamic args]) async {
    try {
      return await methodChannel.invokeMethod<T>(name, args);
    } catch (e) {
      if (e is PlatformException) {
        e.throwByCode();
      } else {
        rethrow;
      }
    }
  }
}
