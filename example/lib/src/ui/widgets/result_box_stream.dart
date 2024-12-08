import 'dart:async' show StreamController;

import 'package:docman_example/src/ui/widgets/clearable_stack.dart';
import 'package:docman_example/src/ui/widgets/thumb_result_widget.dart';
import 'package:flutter/material.dart';

class ResultBoxStream extends StatefulWidget {
  const ResultBoxStream({
    required this.streamController,
    this.autoClear = false,
    this.autoClearLimit = 30,
    this.onClear,
    this.resetAll = false,
    super.key,
  });

  final StreamController<Widget> streamController;
  final VoidCallback? onClear;
  final bool autoClear;
  final int autoClearLimit;
  final bool resetAll;

  @override
  State<ResultBoxStream> createState() => _ResultBoxStreamState();
}

class _ResultBoxStreamState extends State<ResultBoxStream> {
  final List<Widget> _streamResult = [];
  final _listScrollController = ScrollController();
  final _resultStreamController = StreamController<List<Widget>>.broadcast();

  @override
  void initState() {
    super.initState();
    widget.streamController.stream.listen((streamWidget) {
      if (widget.autoClear && _streamResult.length >= widget.autoClearLimit) {
        _clearStream();
      }
      setState(() {
        _streamResult.add(streamWidget);
        _resultStreamController.add(_streamResult);
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _resultStreamController.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ResultBoxStream oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetAll != widget.resetAll) {
      _clearStream();
    }
  }

  void _clearStream() {
    setState(() {
      _streamResult.clear();
      _resultStreamController.add(_streamResult);
    });
    widget.onClear?.call();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_listScrollController.hasClients) {
          _listScrollController.animateTo(
            _listScrollController.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Widget _resizableWidget(Widget child) => child is ThumbResultWidget
      ? NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (notification) {
            _scrollToBottom();
            return true;
          },
          child: SizeChangedLayoutNotifier(child: child),
        )
      : child;

  Widget get _defaultListItem => const ListTile(
        title: Text('Resulting Box'),
        subtitle: Text('This box is used to print results of actions'),
      );

  @override
  Widget build(BuildContext context) => ClearableWidget(
        onClear: _clearStream,
        enabled: _streamResult.isNotEmpty,
        tooltip: 'Clear Results',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
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
          child: StreamBuilder<List<Widget>>(
            stream: _resultStreamController.stream,
            builder: (context, snapshot) => Scrollbar(
              interactive: true,
              thumbVisibility: true,
              trackVisibility: true,
              controller: _listScrollController,
              radius: const Radius.circular(15),
              thickness: 2,
              child: ListView.builder(
                controller: _listScrollController,
                primary: false,
                itemCount: _streamResult.isEmpty ? 1 : _streamResult.length,
                itemBuilder: (context, index) =>
                    _streamResult.isEmpty ? _defaultListItem : _resizableWidget(_streamResult[index]),
              ),
            ),
          ),
        ),
      );
}
