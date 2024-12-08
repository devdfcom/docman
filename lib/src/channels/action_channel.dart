import 'package:docman/src/extensions/platform_exception_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// An implementation of [PlatformInterface] that uses method channel.
/// Action channel is used for actions that don't require any UI.
/// And can run in the background.
class ActionChannel extends PlatformInterface {
  /// Constructs a [ActionChannel] platform interface.
  ActionChannel() : super(token: _token);

  static final Object _token = Object();

  static ActionChannel _instance = ActionChannel();

  /// The default instance of [ActionChannel] to use.
  ///
  /// Defaults to [ActionChannel].
  static ActionChannel get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ActionChannel] when
  /// they register themselves.
  static set instance(ActionChannel instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('devdf.plugins/docman/action');

  /// Entry point for calls on the native platform.
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
