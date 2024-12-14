import 'package:flutter/material.dart';

class MethodActionButton extends StatelessWidget {
  MethodActionButton({
    required this.title,
    required this.onPressed,
    this.active = true,
    this.description,
    this.iconButton,
    this.iconColor,
    super.key,
  });

  final String title;
  final Future<void> Function() onPressed;
  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);
  final bool active;
  final Widget? description;
  final IconData? iconButton;
  final Color? iconColor;

  Widget _descriptionWidget(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: description!),
            ]),
      );

  Widget _iconButton(BuildContext context, {VoidCallback? onPress}) =>
      IconButton(
        onPressed: onPress,
        icon: Icon(iconButton),
        visualDensity: VisualDensity.compact,
        color: iconColor,
      );

  Widget _elevateButton(BuildContext context, {VoidCallback? onPress}) =>
      ElevatedButton(
        onPressed: onPress,
        style: ElevatedButton.styleFrom(
          foregroundColor: description != null
              ? Theme.of(context).colorScheme.onSecondaryContainer
              : Theme.of(context).primaryColor,
          backgroundColor: description != null
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context)
                  .primaryColorDark
                  .withAlpha((255.0 * 0.1).round()),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Text(title),
      );

  Future<void> _onPressed() async {
    isProcessing.value = true;
    try {
      await onPressed();
    } finally {
      isProcessing.value = false;
    }
  }

  Widget _buttonWidget(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: isProcessing,
        builder: (context, processing, child) => iconButton != null
            ? _iconButton(context,
                onPress: processing || !active ? null : _onPressed)
            : _elevateButton(context,
                onPress: processing || !active ? null : _onPressed),
      );

  @override
  Widget build(BuildContext context) => description != null
      ? Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: _buttonWidget(context))]),
                Divider(height: 5),
                _descriptionWidget(context),
              ],
            ),
          ),
        )
      : _buttonWidget(context);
}
