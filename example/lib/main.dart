import 'package:docman_example/src/doc_man.dart';
import 'package:docman_example/src/utils/app_dir.dart';
import 'package:docman_example/src/utils/provider_folder_initializer.dart';
import 'package:docman_example/src/utils/router.dart';
import 'package:flutter/material.dart';

/// Main entry point for the DocMan example app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //1. Init directories
  await AppDir().init();
  //2. Init router
  AppRouter().init();
  //3. Init DocumentsProvider sample folder with media and documents
  await ProviderFolderInitializer().init();
  //4. Run the app
  runApp(const DocManExample());
}
