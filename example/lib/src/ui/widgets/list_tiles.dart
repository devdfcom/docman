import 'package:flutter/material.dart';

class ListTileHeaderDense extends StatelessWidget {
  const ListTileHeaderDense({required this.title, this.icon, this.paddingX = 5.0, super.key});

  final String title;
  final IconData? icon;
  final double paddingX;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                )),
        // tileColor: Colors.black,
        dense: true,
        leading: icon != null ? Icon(icon, size: 16, color: Colors.white70) : null,
        visualDensity: VisualDensity.compact.copyWith(vertical: -4.0),
        contentPadding: EdgeInsets.symmetric(horizontal: paddingX),
        horizontalTitleGap: 4.0,
        minVerticalPadding: 0.0,
      );
}

class ListTileDense extends StatelessWidget {
  const ListTileDense({this.title, this.subTitle, this.fitLine = false, this.trailing, super.key});

  final String? title;
  final String? subTitle;
  final bool fitLine;
  final Widget? trailing;

  Widget get _titleWidget => Text(title!);

  Widget get _subTitleSimple => Text(subTitle!, style: TextStyle(fontSize: 11));

  Widget get _subTitleFitted =>
      FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(subTitle!));

  Widget get _subTitleWidget => fitLine ? _subTitleFitted : _subTitleSimple;

  @override
  Widget build(BuildContext context) => ListTile(
        title: title != null ? _titleWidget : null,
        subtitle: subTitle != null ? _subTitleWidget : null,
        trailing: trailing,
        dense: true,
        visualDensity: VisualDensity.compact.copyWith(vertical: -4.0),
      );
}

class ListHeader extends StatelessWidget {
  ///Header for lists items, default padding is bottom: `8.0`.
  ///Color is [secondary], text always to upperCase.
  ///If [padding] is null, [verticalPadding] is used.
  ///If [verticalPadding] is true, [EdgeInsets.symmetric(vertical:)] is used.
  ///If [verticalPadding] is false, [onlyBottomPadding] is used.
  ///If [onlyBottomPadding] is true, [EdgeInsets.only(bottom:)] is used.
  ///If [onlyBottomPadding] is false, [verticalPadding] must be true.
  ///If [color] is null, [secondary] is used.
  ///If [padValue] is null, `8.0` is used.
  const ListHeader({
    required this.text,
    this.padding,
    this.onlyBottomPadding = true,
    this.verticalPadding = false,
    this.color,
    this.padValue,
    this.toUpperCase = false,
    super.key,
  }) : assert(onlyBottomPadding || verticalPadding, 'onlyBottomPadding or verticalPadding must be true');

  const ListHeader.vertical({
    required this.text,
    this.toUpperCase = false,
    this.color,
    this.padValue,
    super.key,
  })  : onlyBottomPadding = false,
        verticalPadding = true,
        padding = null;

  const ListHeader.bottom({
    required this.text,
    this.toUpperCase = false,
    this.color,
    this.padValue,
    super.key,
  })  : onlyBottomPadding = true,
        verticalPadding = false,
        padding = null;

  ///Header text
  final String text;

  ///Header text to upperCase, default is false
  final bool toUpperCase;

  ///Setting padding, if null [onlyBottomPadding] is used
  final EdgeInsets? padding;

  ///Setting color, if null [secondary] is used
  final Color? color;

  ///Only bottom padding, default is true
  final bool onlyBottomPadding;

  ///Vertical padding, default is false
  final bool verticalPadding;

  ///Setting padding value, if null `8.0` is used
  final double? padValue;

  double get _padValue => padValue ?? 8.0;

  EdgeInsets get _padding =>
      verticalPadding ? EdgeInsets.symmetric(vertical: _padValue) : EdgeInsets.only(bottom: _padValue);

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? _padding,
        child: Text(
          toUpperCase ? text.toUpperCase() : text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color ?? Theme.of(context).colorScheme.secondary,
                letterSpacing: 0.5,
              ),
        ),
      );
}
