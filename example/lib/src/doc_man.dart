import 'package:docman_example/src/ui/pages/main_page.dart';
import 'package:docman_example/src/utils/router.dart';
import 'package:docman_example/src/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class DocManExample extends StatelessWidget {
  const DocManExample({super.key});

  @override
  Widget build(BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
        child: MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          scaffoldMessengerKey: ToastHelper.messengerKey,
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.blue,
            appBarTheme: ThemeData.dark().appBarTheme.copyWith(scrolledUnderElevation: 0.0),
            chipTheme: ThemeData.dark().chipTheme.copyWith(
                  backgroundColor: Colors.transparent,
                  selectedColor: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  labelPadding: EdgeInsets.zero,
                  showCheckmark: false,
                ),
          ),
          home: RouterHome(builder: () => const MainPage()),
        ),
      );
}
