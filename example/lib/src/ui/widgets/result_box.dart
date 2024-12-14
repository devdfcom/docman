import 'package:docman_example/src/ui/widgets/clearable_stack.dart';
import 'package:docman_example/src/ui/widgets/method_api_widget.dart';
import 'package:docman_example/src/ui/widgets/single_scroll_bar.dart';
import 'package:flutter/material.dart';

class ResultBox extends StatelessWidget {
  const ResultBox({this.children = const [], this.onClear, super.key});

  final List<Widget> children;
  final VoidCallback? onClear;

  factory ResultBox.fromMethods(List<MethodApiEntry> methods, {Widget? header, VoidCallback? onClear}) => ResultBox(
        onClear: onClear,
        children: [header, ...methods.map((m) => MethodApiWidget(m))].nonNulls.toList(),
      );

  List<Widget> _defaultList() => <Widget>[
        const ListTile(
          title: Text('Resulting Box'),
          subtitle: Text('This box is used to print results of actions'),
        )
      ];

  @override
  Widget build(BuildContext context) {
    return ClearableWidget(
      onClear: onClear,
      enabled: children.isNotEmpty,
      tooltip: 'Clear Results',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255.0 * 0.5).round()),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 10).copyWith(right: 3),
        clipBehavior: Clip.antiAlias,
        height: MediaQuery.of(context).size.height / 2.5,
        child: SingleChildScrollViewWithScrollBar(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.isEmpty ? _defaultList() : children,
          ),
        ),
      ),
    );
  }
}
