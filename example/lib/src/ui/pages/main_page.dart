import 'package:docman_example/src/ui/widgets/list_page.dart';
import 'package:docman_example/src/ui/widgets/list_tiles.dart';
import 'package:docman_example/src/ui/widgets/method_api_widget.dart';
import 'package:docman_example/src/ui/widgets/result_box.dart';
import 'package:docman_example/src/utils/app_dir.dart';
import 'package:docman_example/src/utils/router.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) => ListPage(
        title: 'Document Manager',
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Picker'),
                    subtitle: const Text(
                        'Used to pick directory, files, documents, media'),
                    onTap: () => AppRouter.picker.push(),
                  ),
                  ListTile(
                    title: Text('DocumentFile'),
                    subtitle:
                        Text('Representation of Android DocumentFile class'),
                    onTap: () => AppRouter.documentFile.push(),
                  ),
                  ListTile(
                    title: Text('Persisted Permissions'),
                    subtitle: Text('Manage permissions for documents'),
                    onTap: () => AppRouter.permissions.push(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          ResultBox.fromMethods([
            MethodApiEntry(
              name: 'DocMan.dir.cache()',
              title: 'Cache Directory',
              subTitle: 'Returns the internal cache directory of the app',
              result: AppDir.cache.path,
            ),
            MethodApiEntry(
              name: 'DocMan.dir.files()',
              title: 'Files Directory',
              subTitle: 'Returns the internal files directory of the app',
              result: AppDir.files.path,
            ),
            MethodApiEntry(
              name: 'DocMan.dir.data()',
              title: 'Data Directory',
              subTitle: 'Returns the internal data directory of the app',
              result: AppDir.data.path,
            ),
            MethodApiEntry(
              name: 'DocMan.dir.cacheExt()',
              title: 'External Cache Directory',
              subTitle: 'Returns the external cache directory of the app',
              result: AppDir.cacheExt?.path ?? 'Not Available',
            ),
            MethodApiEntry(
              name: 'DocMan.dir.filesExt()',
              title: 'External Files Directory',
              subTitle: 'Returns the external files directory of the app',
              result: AppDir.filesExt?.path ?? 'Not Available',
            ),
          ],
              header: ListTileHeaderDense(
                  title: 'Application Directories:',
                  icon: Icons.folder,
                  paddingX: 15)),
        ],
      );
}
