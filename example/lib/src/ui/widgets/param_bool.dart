import 'package:flutter/material.dart';

class ParamBool extends StatelessWidget {
  const ParamBool({
    required this.title,
    required this.value,
    required this.onUpdate,
    this.subTitle,
    this.disabled = false,
    super.key,
  });

  final String title;
  final String? subTitle;
  final bool value;
  final bool disabled;
  final Function(bool) onUpdate;

  Widget _subTitleWidget(BuildContext context) => Text(
        subTitle!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
      );

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: disabled ? null : () => onUpdate(!value),
        title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: subTitle != null ? _subTitleWidget(context) : null,
        trailing: Transform.scale(
          alignment: Alignment.centerRight,
          scale: 0.75,
          child: Switch(
            value: value,
            onChanged: disabled ? null : onUpdate,
            activeColor: Theme.of(context).primaryColor,
          ),
        ),
        dense: true,
        visualDensity: VisualDensity.compact.copyWith(vertical: -4.0),
        contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
      );
}
