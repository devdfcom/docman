import 'package:flutter/material.dart';

class ExpansionTileWidget extends StatefulWidget {
  const ExpansionTileWidget({
    required this.title,
    required this.children,
    this.subTitle,
    this.isExpanded = false,
    this.controlsOnLeft = true,
    this.childrenPadding,
    this.action,
    this.actionTooltip,
    this.collapseOnAction = true,
    this.hideTrailing = false,
    super.key,
  });

  final String title;
  final Widget? subTitle;
  final List<Widget> children;
  final bool isExpanded;
  final bool controlsOnLeft;
  final bool hideTrailing;
  final bool collapseOnAction;

  final EdgeInsetsGeometry? childrenPadding;
  final VoidCallback? action;
  final String? actionTooltip;

  @override
  State<ExpansionTileWidget> createState() => _ExpansionTileWidgetState();
}

class _ExpansionTileWidgetState extends State<ExpansionTileWidget> {
  late ExpansionTileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExpansionTileController();
  }

  void _onActionPressed() {
    if (widget.action != null) {
      widget.action!();
    }
    if (widget.collapseOnAction) {
      _controller.collapse();
    }
  }

  Widget? get actionWidget => IconButton(
        icon: Icon(Icons.play_circle_outline),
        color: Colors.green,
        onPressed: widget.action != null ? _onActionPressed : null,
        tooltip: widget.actionTooltip,
      );

  @override
  Widget build(BuildContext context) => ExpansionTile(
        controller: _controller,
        title: Text(widget.title, style: TextStyle(fontSize: 14, height: 1.2)),
        subtitle: widget.subTitle,
        dense: true,
        showTrailingIcon: !widget.hideTrailing,
        controlAffinity: widget.controlsOnLeft
            ? ListTileControlAffinity.leading
            : ListTileControlAffinity.trailing,
        leading: widget.controlsOnLeft ? null : actionWidget,
        trailing: widget.controlsOnLeft ? actionWidget : null,
        visualDensity: VisualDensity.compact,
        childrenPadding:
            widget.childrenPadding ?? EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: widget.isExpanded,
        children: widget.children,
      );
}
