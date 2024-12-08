import 'package:docman_example/src/ui/widgets/param_bool.dart';
import 'package:flutter/material.dart';

import 'method_param_input.dart';

class PickerParamLimitWidget extends StatelessWidget {
  const PickerParamLimitWidget({
    this.limit = 1,
    this.resultEmpty = false,
    this.resultCancel = false,
    this.resultRestart = false,
    required this.setLimit,
    required this.setLimitResultEmpty,
    required this.setLimitResultCancel,
    required this.setLimitResultRestart,
    required this.resetLimit,
    super.key,
  });

  final int limit;
  final Function(String?) setLimit;
  final bool resultEmpty;
  final Function(bool) setLimitResultEmpty;
  final bool resultCancel;
  final Function(bool) setLimitResultCancel;
  final bool resultRestart;
  final Function(bool) setLimitResultRestart;
  final VoidCallback resetLimit;

  String get _properTitle =>
      limit > 1 ? 'Maximum items to pick: $limit' : 'Single Selection';

  String get _properSubtitle {
    //1. Check if limit > 1
    if (limit > 1) {
      //2. Check if limitResultEmpty is true
      if (resultEmpty) return 'Returns empty list, if items > limit';
      //3. Check if limitResultCancel is true
      if (resultCancel) return 'Returns error, if items > limit';
      //4. Check if limitResultRestart is true
      if (resultRestart) return 'Restarts the picker, if items > limit';
      //5. Default action when limit is reached
      return 'Returns only limited items, if items > limit';
    }
    //6. Limit is 1
    return 'Allows to pick only one item';
  }

  bool get _isDisabled => limit == 1;

  String get _paramNameText => 'limit';

  Widget get _paramNameWidget => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        // margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SelectableText(_paramNameText,
                style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.2)),
            Text(':',
                style:
                    TextStyle(color: Colors.black, fontSize: 11, height: 1.2)),
          ],
        ),
      );

  Widget get _paramResult =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _paramNameWidget,
        SizedBox(width: 5),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white70.withOpacity(0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            margin: const EdgeInsets.only(bottom: 5, right: 5),
            child: SelectableText(_paramResultText,
                style:
                    TextStyle(color: Colors.white, fontSize: 12, height: 1.2)),
          ),
        ),
      ]);

  String get _paramResultText {
    var params = ['limit: $limit'];
    if (limit > 1) {
      if (resultEmpty) params.add('limitResultEmpty: true');
      if (resultCancel) params.add('limitResultCancel: true');
      if (resultRestart) params.add('limitResultRestart: true');
    }

    return 'PickLimit(${params.join(', ')})';
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ExpansionTile(
          title:
              Text(_properTitle, style: TextStyle(fontSize: 14, height: 1.2)),
          subtitle: Text(_properSubtitle,
              style: TextStyle(fontSize: 11, height: 1.2)),
          trailing: IconButton(
            icon: Icon(Icons.clear_all),
            color: !_isDisabled ? Colors.red[700] : null,
            onPressed: !_isDisabled ? resetLimit : null,
            tooltip: 'Clear All',
          ),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          visualDensity: VisualDensity.compact,
          childrenPadding: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          expandedAlignment: Alignment.centerLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          tilePadding: EdgeInsets.zero,
          children: [
            MethodParamInput(
              fieldName: 'Limit - max number of items',
              initialValue: limit.toString(),
              onSaved: setLimit,
              numbersOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Limit is required';
                final limit = int.tryParse(value);
                if (limit == null || limit < 1)
                  return 'Limit must be a positive number';
                return null;
              },
            ),
            ParamBool(
              title: 'limitResultEmpty',
              subTitle: 'Finish with empty list, if items > limit',
              value: resultEmpty,
              onUpdate: setLimitResultEmpty,
              disabled: _isDisabled,
            ),
            ParamBool(
              title: 'limitResultCancel',
              subTitle: 'Returns error, where message is count of picked items',
              value: resultCancel,
              onUpdate: setLimitResultCancel,
              disabled: _isDisabled,
            ),
            ParamBool(
              title: 'limitResultRestart',
              subTitle: 'Restart picker with toast message, if items > limit',
              value: resultRestart,
              onUpdate: setLimitResultRestart,
              disabled: _isDisabled,
            ),
          ],
        ),
        _paramResult,
        Divider(height: 3),
      ]);
}
