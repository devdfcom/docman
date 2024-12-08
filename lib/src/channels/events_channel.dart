import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

///Events channel
class EventsChannel extends PlatformInterface {
  /// Constructs a [EventsChannel] platform interface.
  EventsChannel() : super(token: _token);

  static final Object _token = Object();

  static EventsChannel _instance = EventsChannel();

  /// The default instance of [EventsChannel] to use.
  ///
  /// Defaults to [EventsChannel].
  static EventsChannel get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EventsChannel] when
  /// they register themselves.
  static set instance(EventsChannel instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final eventsChannel = const EventChannel('devdf.plugins/docman/events');

  /// Listen to events from the platform.
  Stream<dynamic> listen([dynamic args]) =>
      eventsChannel.receiveBroadcastStream(args);
}
