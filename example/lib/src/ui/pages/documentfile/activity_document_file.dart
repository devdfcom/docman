import 'package:docman/docman.dart';
import 'package:docman_example/src/ui/widgets/expansion_tile_widget.dart';
import 'package:docman_example/src/ui/widgets/method_action_button.dart';
import 'package:docman_example/src/ui/widgets/method_api_widget.dart';
import 'package:docman_example/src/ui/widgets/param_bool.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

class ActivityDocumentFile extends StatefulWidget {
  const ActivityDocumentFile({
    required this.document,
    required this.onDocument,
    required this.onResult,
    super.key,
  });

  final DocumentFile? document;
  final Function(DocumentFile?) onDocument;
  final Function(List<MethodApiEntry>) onResult;

  @override
  State<ActivityDocumentFile> createState() => _ActivityDocumentFileState();
}

class _ActivityDocumentFileState extends State<ActivityDocumentFile> {
  ///Save to action parameters
  bool _saveToLocalOnly = false;
  bool _saveToDeleteSource = false;

  void _setSaveToLocalOnly(bool value) => setState(() => _saveToLocalOnly = value);

  void _setSaveToDeleteSource(bool value) => setState(() => _saveToDeleteSource = value);

  MethodApiEntry _exceptionEntry(Object e) => MethodApiEntry(
        title: '${e.runtimeType}: ${e is DocManException ? e.code : e is PlatformException ? e.code : ''}',
        subTitle: 'Exception caught while picking files',
        result: e is AssertionError ? e.message.toString() : e.toString(),
        isResultOk: false,
      );

  Future<void> _open() async {
    bool isOpened = false;
    MethodApiEntry? exception;

    try {
      isOpened = await widget.document!.open('Open Document with');
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    setState(() {
      //1. Set the result
      widget.onResult([
        MethodApiEntry(
          name: 'DocumentFile.open(title: "Open Document with")',
          title: exception?.title ?? 'Open Document',
          subTitle: exception?.subTitle ?? 'Returns true if the document was opened',
          result: exception?.result ?? isOpened.toString(),
          isResultOk: exception == null,
        )
      ]);
    });
  }

  Future<void> _share() async {
    bool isShared = false;
    MethodApiEntry? exception;

    try {
      isShared = await widget.document!.share('Share Document with');
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    setState(() {
      //1. Set the result
      widget.onResult([
        MethodApiEntry(
          name: 'DocumentFile.share(title: "Share Document with")',
          title: exception?.title ?? 'Share Document',
          subTitle: exception?.subTitle ?? 'Returns true if the document was shared',
          result: exception?.result ?? isShared.toString(),
          isResultOk: exception == null,
        )
      ]);
    });
  }

  Future<void> _saveTo() async {
    DocumentFile? doc;
    MethodApiEntry? exception;

    try {
      doc = await widget.document!.saveTo(localOnly: _saveToLocalOnly, deleteSource: _saveToDeleteSource);
    } catch (e) {
      exception = _exceptionEntry(e);
    }

    setState(() {
      //1. Set the result
      widget.onDocument(doc);
      widget.onResult([
        MethodApiEntry(
          name: 'DocumentFile.saveTo(localOnly: $_saveToLocalOnly, deleteSource: $_saveToDeleteSource)',
          title: exception != null
              ? exception.title
              : doc != null
                  ? 'DocumentFile: ${doc.name}'
                  : 'Document was not saved',
          subTitle: exception?.subTitle ?? 'Returns the saved document as `DocumentFile`',
          result: exception?.result ?? doc?.toString(),
          isResultOk: exception == null && doc != null,
        )
      ]);
    });
  }

  Widget get _saveToWidget => ExpansionTileWidget(
        title: 'Save to',
        subTitle: Text('Returns the saved file as `DocumentFile`'),
        action: _saveTo,
        actionTooltip: 'Save Document',
        childrenPadding: EdgeInsets.zero,
        children: [
          ParamBool(
            title: 'localOnly',
            subTitle: 'Save to local storage only',
            value: _saveToLocalOnly,
            onUpdate: _setSaveToLocalOnly,
          ),
          ParamBool(
            title: 'deleteSource',
            subTitle: 'Delete the source document after saving',
            value: _saveToDeleteSource,
            onUpdate: _setSaveToDeleteSource,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //1. Button activity actions
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 5),
            child: Wrap(
              spacing: 5.0,
              runSpacing: 0.0,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                MethodActionButton(title: 'Open', onPressed: _open),
                MethodActionButton(title: 'Share', onPressed: _share),
              ],
            ),
          ),
          Divider(height: 5),
          //2. Save to action
          _saveToWidget,
        ]),
      );
}
