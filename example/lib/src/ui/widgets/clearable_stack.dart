import 'package:flutter/material.dart';

class ClearableWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClear;
  final bool enabled;
  final String? tooltip;

  const ClearableWidget(
      {required this.child,
      this.onClear,
      this.enabled = true,
      this.tooltip,
      super.key});

  @override
  Widget build(BuildContext context) => Stack(children: [
        child,
        Visibility(
          visible: onClear != null,
          child: Positioned(
            right: -5,
            top: -10,
            child: IconButton(
              icon: Icon(Icons.clear_all),
              color: enabled ? Colors.red[700] : null,
              onPressed: enabled ? onClear : null,
              tooltip: tooltip,
            ),
          ),
        ),
      ]);
}
