import 'package:docman/channels/document_file_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class DocumentFileApi extends PlatformInterface {
  /// Constructs a DocumentFileApi platform interface.
  DocumentFileApi() : super(token: _token);

  static final Object _token = Object();

  static DocumentFileChannel _instance = DocumentFileChannel();

  /// The default instance of [DocumentFileChannel] to use.
  ///
  /// Defaults to [DocumentFileChannel].
  static DocumentFileChannel get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DocumentFileChannel] when
  /// they register themselves.
  static set instance(DocumentFileChannel instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
