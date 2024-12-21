import 'dart:io';
import 'dart:math';

import 'package:docman_example/src/utils/app_dir.dart';
import 'package:flutter/services.dart';

/// This class creates the folder structure for the provider demo
class ProviderFolderInitializer {
  final List<String> _mediaAssets = [
    'assets/images/jpeg_example.jpg',
    'assets/images/webp_example.webp',
    'assets/images/gif_example.gif',
    'assets/images/png_example.png',
    'assets/video/video_sample.mp4'
  ];

  final List<String> _docAssets = ['assets/pdf/example.pdf'];

  final String _providerMediaFolder = 'media';
  final String _providerDocFolder = 'documents';

  String get _mediaFolderPath => [AppDir.provider.path, _providerMediaFolder].join(Platform.pathSeparator);

  String get _documentsFolderPath => [AppDir.provider.path, _providerDocFolder].join(Platform.pathSeparator);

  Future<void> init() async {
    //1. Create the folder if not exists
    //2. If the folder exists, return
    await AppDir.provider.create();
    //3. Copy the files from the assets folder to the folder
    if (AppDir.provider.listSync().isEmpty) await _initSubFolders();
  }

  Future<void> _initSubFolders() async {
    //3.2 Copy the media files
    await _initSubFolder(_mediaFolderPath, _mediaAssets);
    //3.3 Copy the doc files
    await _initSubFolder(_documentsFolderPath, _docAssets);
  }

  Future<void> _initSubFolder(String folderPath, List<String> assets) async {
    //1. Create the folder if not exists
    if (!await Directory(folderPath).exists()) await Directory(folderPath).create();
    //2. Copy the media files
    for (final asset in assets) {
      final extension = asset.split('.').last;
      final randomName = String.fromCharCodes(List.generate(10, (index) => Random().nextInt(26) + 97));
      await _getFilePath(asset, [folderPath, '$randomName.$extension'].join(Platform.pathSeparator));
    }
  }

  Future<String> _getFilePath(String asset, String dest) async {
    final file = File(dest);
    if (!(await file.exists())) {
      final bytes = (await rootBundle.load(asset)).buffer.asUint8List();
      await file.writeAsBytes(bytes);
    }

    return file.path;
  }
}
