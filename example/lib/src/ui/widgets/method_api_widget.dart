import 'package:flutter/material.dart';

class MethodApiEntry {
  final String? name;
  final String? title;
  final String? subTitle;
  final String? result;
  final bool isResultOk;

  MethodApiEntry(
      {this.name,
      this.title,
      this.subTitle,
      this.result,
      this.isResultOk = true});
}

class MethodApiWidget extends StatelessWidget {
  const MethodApiWidget(this.entry, {this.endDivider = true, super.key});

  final MethodApiEntry entry;
  final bool endDivider;

  bool get _resultSuccess => entry.isResultOk;

  Widget _nameWidget(BuildContext context) => entry.name != null
      ? Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(5)),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code,
                    color: Colors.black,
                    size: Theme.of(context).textTheme.bodyMedium?.fontSize),
                SizedBox(width: 5),
                Flexible(
                  child: SelectableText(entry.name!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red[700],
                            fontSize: 11,
                          )),
                ),
              ]),
        )
      : SizedBox.shrink();

  Widget _titleWidget(BuildContext context) => entry.title != null
      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(
            _resultSuccess ? Icons.info : Icons.warning_amber_outlined,
            size: 16,
            color: _resultSuccess
                ? Colors.blueAccent.withOpacity(0.8)
                : Colors.orange.withOpacity(0.8),
          ),
          SizedBox(width: 5),
          Expanded(
              child: Text(entry.title!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  softWrap: true)),
        ])
      : SizedBox.shrink();

  Widget _subTitleWidget(BuildContext context) => entry.subTitle != null
      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Text(entry.subTitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                  softWrap: true)),
        ])
      : SizedBox.shrink();

  Widget _resultWidget(BuildContext context) => entry.result != null
      ? Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(
              _resultSuccess ? Icons.check_circle : Icons.error_outline,
              size: Theme.of(context).textTheme.bodySmall?.fontSize,
              color: _resultSuccess ? Colors.green : Colors.red,
            ),
            SizedBox(width: 5),
            Expanded(
                child: Text(entry.result!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _resultSuccess ? Colors.white70 : Colors.red,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          fontWeight: _resultSuccess
                              ? FontWeight.normal
                              : FontWeight.bold,
                          height: 1.2,
                        ),
                    softWrap: true))
          ]),
        )
      : SizedBox.shrink();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //1. Method Name
          _nameWidget(context),
          //2. Title
          _titleWidget(context),
          //3. SubTitle - Description
          _subTitleWidget(context),
          //3. Result
          _resultWidget(context),
          if (endDivider) Divider(height: 4),
        ]),
      );
}
