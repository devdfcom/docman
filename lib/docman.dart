
import 'docman_platform_interface.dart';

class Docman {
  Future<String?> getPlatformVersion() {
    return DocmanPlatform.instance.getPlatformVersion();
  }
}
