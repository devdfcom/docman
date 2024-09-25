import 'package:docman/channels/document_file_api.dart';

class Docman {
  Future<String?> getPlatformVersion() => DocumentFileApi.instance.getPlatformVersion();
}
