import 'package:flutter_test/flutter_test.dart';
import 'package:docman/docman.dart';
import 'package:docman/docman_platform_interface.dart';
import 'package:docman/docman_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDocmanPlatform
    with MockPlatformInterfaceMixin
    implements DocmanPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DocmanPlatform initialPlatform = DocmanPlatform.instance;

  test('$MethodChannelDocman is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDocman>());
  });

  test('getPlatformVersion', () async {
    Docman docmanPlugin = Docman();
    MockDocmanPlatform fakePlatform = MockDocmanPlatform();
    DocmanPlatform.instance = fakePlatform;

    expect(await docmanPlugin.getPlatformVersion(), '42');
  });
}
