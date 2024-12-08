import 'package:docman_example/src/doc_man.dart';
import 'package:docman_example/src/utils/app_dir.dart';
import 'package:docman_example/src/utils/router.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //1. Init directories
  await AppDir().init();
  //2. Init router
  AppRouter().init();

  runApp(const DocManExample());
}
