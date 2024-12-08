import 'package:flutter/material.dart';

class SingleChildScrollViewWithScrollBar extends StatelessWidget {
  const SingleChildScrollViewWithScrollBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final listScrollController = ScrollController();
    return Scrollbar(
      interactive: true,
      thumbVisibility: true,
      trackVisibility: true,
      controller: listScrollController,
      radius: const Radius.circular(15),
      thickness: 2,
      child: SingleChildScrollView(
        controller: listScrollController,
        primary: false,
        child: child,
      ),
    );
  }
}
