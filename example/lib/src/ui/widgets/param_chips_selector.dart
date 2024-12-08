import 'package:flutter/material.dart';

class ParamChipsSelector extends StatefulWidget {
  const ParamChipsSelector({
    required this.title,
    required this.available,
    required this.selected,
    required this.onUpdate,
    this.subTitle,
    this.action,
    this.actionTooltip,
    this.collapseOnAction = true,
    this.isExpanded = false,
    this.clearTooltip,
    this.paramName,
    this.hideParam = false,
    super.key,
  });

  final String title;
  final Widget? subTitle;
  final String? clearTooltip;
  final String? paramName;
  final bool hideParam;
  final VoidCallback? action;
  final String? actionTooltip;
  final bool collapseOnAction;
  final bool isExpanded;
  final List<String> available;
  final List<String> selected;
  final Function(List<String>) onUpdate;

  @override
  State<ParamChipsSelector> createState() => _ParamChipsSelectorState();
}

class _ParamChipsSelectorState extends State<ParamChipsSelector> {
  late ExpansionTileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExpansionTileController();
  }

  List<ChoiceChip> get _chips => widget.available
      .map(
        (param) => ChoiceChip(
          label: Text(param, style: TextStyle(fontSize: 12, height: 1.2)),
          selected: widget.selected.contains(param),
          onSelected: (isAvailable) => _updateParams(param, isAvailable),
          visualDensity: VisualDensity.compact.copyWith(vertical: -4.0),
        ),
      )
      .toList();

  void _updateParams(String param, bool add) {
    List<String> updatedList = List.from(widget.selected);
    add ? updatedList.add(param) : updatedList.remove(param);
    widget.onUpdate(updatedList);
  }

  void _onActionPressed() {
    if (widget.collapseOnAction) {
      _controller.collapse();
    }

    if (widget.action != null) {
      widget.action!();
    }
  }

  String get _paramNameText => widget.paramName ?? widget.title;

  Widget get _paramNameWidget => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        margin: const EdgeInsets.only(left: 5),
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

  Widget get _paramResult => widget.selected.isNotEmpty && !widget.hideParam
      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              child: SelectableText('${widget.selected}',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12, height: 1.2)),
            ),
          ),
        ])
      : SizedBox.shrink();

  Widget get _clearAction => IconButton(
        icon: Icon(Icons.clear_all),
        color: widget.selected.isNotEmpty ? Colors.red[700] : null,
        onPressed:
            widget.selected.isNotEmpty ? () => widget.onUpdate([]) : null,
        tooltip: widget.clearTooltip ?? 'Clear All',
      );

  Widget? get _actionWidget => IconButton(
        icon: Icon(Icons.play_circle_outline),
        color: Colors.green,
        onPressed: widget.action != null ? _onActionPressed : null,
        tooltip: widget.actionTooltip ?? 'Run',
      );

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ExpansionTile(
          controller: _controller,
          title:
              Text(widget.title, style: TextStyle(fontSize: 14, height: 1.2)),
          subtitle: widget.subTitle,
          trailing: widget.action != null ? _actionWidget : _clearAction,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          visualDensity: VisualDensity.compact,
          childrenPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          expandedAlignment: Alignment.centerLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          tilePadding: EdgeInsets.zero,
          initiallyExpanded: widget.isExpanded,
          children: [
            Wrap(spacing: 5, runSpacing: 0, children: _chips),
            SizedBox(height: 5)
          ],
        ),
        _paramResult,
      ]);
}
