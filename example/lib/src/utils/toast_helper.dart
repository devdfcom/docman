import 'package:docman_example/src/utils/router.dart';
import 'package:flutter/material.dart';

///This is toast type means simple toast, simple toast with close button,
enum ToastType { simple, close, action }

///Color types of toasts
enum ToastColor {
  simple,
  success,
  error,
  notify;

  Color? bgColor(BuildContext context) => switch (this) {
        ToastColor.success => Theme.of(context).colorScheme.primary,
        ToastColor.error => Theme.of(context).colorScheme.error,
        ToastColor.notify => Theme.of(context).colorScheme.secondary,
        _ => null,
      };

  Color textColor(BuildContext context) => switch (this) {
        ToastColor.success => Theme.of(context).colorScheme.onPrimary,
        ToastColor.error => Theme.of(context).colorScheme.onError,
        ToastColor.notify => Theme.of(context).colorScheme.onSecondary,
        _ => Theme.of(context).colorScheme.surface,
      };
}

class ToastHelper {
  static GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const defaultSeconds = 5;

  ///Showing custom toast, after initialization you need to call [show()] method
  ToastHelper({
    this.seconds = defaultSeconds,
    this.color = ToastColor.simple,
    this.text = '',
    this.showCloseIcon = false,
  });

  ///Showing success toast, no need to call [show()] method, it will be called automatically
  ToastHelper.success({
    required this.text,
    int? seconds,
    bool? showCloseIcon,
  })  : seconds = seconds ?? defaultSeconds,
        showCloseIcon = showCloseIcon ?? false,
        color = ToastColor.success {
    show();
  }

  ///Showing error toast, no need to call [show()] method, it will be called automatically
  ToastHelper.error({
    required this.text,
    int? seconds,
    bool? showCloseIcon,
  })  : seconds = seconds ?? defaultSeconds,
        showCloseIcon = showCloseIcon ?? false,
        color = ToastColor.error {
    show();
  }

  ///Showing notify toast, no need to call [show()] method, it will be called automatically
  ToastHelper.notify({
    required this.text,
    int? seconds,
    bool? showCloseIcon,
  })  : seconds = seconds ?? defaultSeconds,
        showCloseIcon = showCloseIcon ?? false,
        color = ToastColor.notify {
    show();
  }

  ///Currently used context
  BuildContext get _context => AppRouter.context;

  ///Toast text to be displayed
  String text;

  ///Determines what type of toast it is by background color
  ///Can be simple, success, error, warning, notify
  ///By default [ToastColor.simple] is used
  ToastColor color;

  ///How much seconds to show toast
  final int seconds;

  ///Show or not close icon on toast
  final bool showCloseIcon;

  SnackBar get _snackBar => SnackBar(
        elevation: 2.0,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: seconds),
        backgroundColor: color.bgColor(_context),
        showCloseIcon: showCloseIcon,
        content: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(color: color.textColor(_context)),
          ),
        ),
      );

  show() {
    //1. Remove currently used snackbar
    remove();
    //2. show new one
    ScaffoldMessenger.of(_context).showSnackBar(_snackBar);
  }

  hide() => ScaffoldMessenger.of(_context).hideCurrentSnackBar();

  remove() => ScaffoldMessenger.of(_context).removeCurrentSnackBar();
}
