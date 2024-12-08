import 'package:docman_example/src/doc_man.dart';
import 'package:docman_example/src/ui/pages/document_file_page.dart';
import 'package:docman_example/src/ui/pages/permissions_page.dart';
import 'package:docman_example/src/ui/pages/picker_page.dart';
import 'package:flutter/material.dart';

class AppRouter {
  factory AppRouter() => _instance;

  AppRouter._internal();

  static final AppRouter _instance = AppRouter._internal();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext get context => navigatorKey.currentContext!;

  static List<AppRoute> routes = [];

  static AppRoute get main => getByName('main');

  static AppRoute get picker => getByName('picker');

  static AppRoute get documentFile => getByName('documentFile');

  static AppRoute get permissions => getByName('permissions');

  //Collecting routes
  AppRouter init() {
    routes.addAll([
      AppRoute(name: 'main', page: (__) => const DocManExample()),
      AppRoute(name: 'picker', page: (__) => const PickerPage()),
      AppRoute(name: 'documentFile', page: (__) => const DocumentFilePage()),
      AppRoute(name: 'permissions', page: (__) => const PermissionsPage()),
    ]);
    return _instance;
  }

  ///Getting route by name
  static AppRoute getByName(String name) =>
      routes.firstWhere((r) => r.name == name);

  ///Pushing route by string name, finding it in list, and if data is not null, pushing with data
  static pushNamed(String name, {Map<String, dynamic>? data}) =>
      getByName(name).push(data: data);

  ///Push to custom page
  static Future<T?> pushCustom<T>({
    required Widget child,
    bool fullscreenDialog = false,
    bool maintainState = true,
    bool barrierDismissible = false,
  }) =>
      push(
        () => child,
        maintainState: maintainState,
        barrierDismissible: barrierDismissible,
        fullscreenDialog: fullscreenDialog,
      );

  ///Push to custom page as fullScreenDialog
  static Future<T?> pushFullScreenDialog<T>({required Widget child}) =>
      pushCustom(child: child, fullscreenDialog: true);

  ///Going back in navigation history, currently using [Navigator.pop]
  static void goBack<T>([T? result]) => Navigator.pop(context, result);

  ///Using [PopScope] widget to listen back button press, and if it's pressed, we will invoke [onTap] function
  static goBackWithValidation(
          {required Widget child, required Function onTap}) =>
      PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            onTap();
          },
          child: child);

  ///Force to go back to main page, removing all routes from stack
  static Future<void> goBackToMain({Map<String, dynamic>? data}) =>
      pushRoot(() => main.page(data));

  /// Pushes a new route.
  static Future<T?> push<T, W extends Widget>(
    RouteWidgetBuilder<W> builder, {
    bool fullscreenDialog = false,
    bool maintainState = true,
    bool barrierDismissible = false,
  }) =>
      Navigator.push<T>(
        AppRouter.context,
        _RouteTransition().zoom<T, W>(builder,
            fullscreenDialog: fullscreenDialog, maintainState: maintainState),
      );

  /// Pushes a new route while removing all others.
  static Future<T?> pushRoot<T, W extends Widget>(
          RouteWidgetBuilder<W> builder) =>
      Navigator.pushAndRemoveUntil(
        context,
        _RouteTransition().zoom<T, W>(builder),
        (route) => false,
      );

  /// Pushes a new route while removing all others (no animation).
  static Future<T?> pushNoAnimation<T, W extends Widget>(
      RouteWidgetBuilder<W> builder) {
    return Navigator.pushAndRemoveUntil(
      context,
      _RouteTransition().noAnimation<T, W>(builder),
      (route) => false,
    );
  }
}

///Each route stored in that class
@immutable
class AppRoute<T> {
  const AppRoute({required this.name, required this.page});

  ///Name which is used in app to route properly
  final String name;

  ///Widget which is representing page
  final Widget Function(Map<String, T>?) page;

  push({Map<String, T>? data}) => AppRouter.push(() => page(data));

  pushAsFullScreenDialog({Map<String, T>? data}) =>
      AppRouter.push(() => page(data), fullscreenDialog: true);
}

/// The widget should use the implicit context declared in a separate widget.
typedef RouteWidgetBuilder<W extends Widget> = W Function();

/// It will push the first route immediately.
/// This is needed to avoid having an unnamed first route.
class RouterHome<W extends Widget> extends StatefulWidget {
  final RouteWidgetBuilder<W> builder;

  const RouterHome({required this.builder, super.key});

  @override
  State<RouterHome> createState() => _RouterHomeState<W>();
}

class _RouterHomeState<W extends Widget> extends State<RouterHome> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.pushNoAnimation<void, W>(
          widget.builder as RouteWidgetBuilder<W>);
    });
  }

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
}

/// Default flutter transition
class _RouteTransition {
  const _RouteTransition();

  PageRoute<T> noAnimation<T, W extends Widget>(
          RouteWidgetBuilder<W> builder) =>
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => builder(),
        settings: RouteSettings(name: W.toString()),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );

  PageRoute<T> zoom<T, W extends Widget>(
    RouteWidgetBuilder<W> builder, {
    bool maintainState = true,
    bool fullscreenDialog = false,
    bool allowSnapshotting = true,
    bool barrierDismissible = false,
  }) =>
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => builder(),
        transitionsBuilder: (context, a1, a2, child) => ScaleTransition(
          scale: CurvedAnimation(
            parent: a1,
            curve: Curves.easeInOut,
          ),
          child: child,
        ),
        settings: RouteSettings(name: W.toString()),
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
}
