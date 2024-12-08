import 'package:flutter/material.dart';

class ListPage extends StatelessWidget {
  const ListPage(
      {required this.title, this.actions, this.children = const [], super.key});

  final String title;
  final List<Widget>? actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), centerTitle: true, actions: actions),
        body: SafeArea(
            minimum: EdgeInsets.all(15), child: Column(children: children)),
        resizeToAvoidBottomInset: false,
      );
}
