import 'dart:async' show Future;

import 'package:docman/docman.dart';
import 'package:docman_example/src/ui/widgets/method_api_widget.dart';
import 'package:flutter/material.dart';

class ThumbResultWidget extends StatefulWidget {
  const ThumbResultWidget({
    required this.maxWidth,
    required this.maxHeight,
    required this.getThumb,
    super.key,
  });

  final num maxWidth;
  final num maxHeight;
  final Future<DocumentThumbnail?> getThumb;

  @override
  State<ThumbResultWidget> createState() => _ThumbResultWidgetState();
}

class _ThumbResultWidgetState extends State<ThumbResultWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ///Converts any [double, int] size like width or height
  ///to logical pixels - by Device Pixel Ratio from [MediaQuery]
  ///Used to get proper size for images for example
  int _asDPR(int size) => (size * MediaQuery.devicePixelRatioOf(context)).toInt();

  ///Used like this to prevent blurry images
  double get _containerWidth => (widget.maxWidth / 2);

  ///Used like this to prevent blurry images
  double get _containerHeight => (widget.maxHeight / 2);

  ///Image container
  Widget _imageContainer({DocumentThumbnail? imageData}) {
    final image = imageData != null ? MemoryImage(imageData.bytes) : null;
    return Container(
      margin: EdgeInsets.only(left: 15),
      clipBehavior: Clip.hardEdge,
      height: _containerWidth,
      width: _containerHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      foregroundDecoration: image != null
          ? BoxDecoration(
              image: DecorationImage(
                image: ResizeImage.resizeIfNeeded(_asDPR(widget.maxWidth.toInt()), null, image),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: imageData == null ? const Center(child: CircularProgressIndicator()) : null,
    );
  }

  Widget get _errorContainer => MethodApiWidget(
        MethodApiEntry(
          result: 'Error: Could not retrieve thumbnail',
          isResultOk: false,
        ),
        endDivider: false,
      );

  List<Widget> _metaData(DocumentThumbnail? imageData) => imageData == null
      ? []
      : [
          const SizedBox(height: 5),
          MethodApiWidget(
            MethodApiEntry(
              result: 'DocumentThumbnail(width: ${imageData.width}, height: ${imageData.height})',
            ),
            endDivider: false,
          ),
          MethodApiWidget(
            MethodApiEntry(
              result:
                  'Container size (width: $_containerWidth, height: $_containerHeight), equals to half of thumbnail size',
            ),
            endDivider: false,
          ),
        ];

  Widget _snapshotByState(AsyncSnapshot snapshot) => switch (snapshot.connectionState) {
        ConnectionState.done => snapshot.hasData ? _imageContainer(imageData: snapshot.data) : _errorContainer,
        _ => _imageContainer(imageData: snapshot.data)
      };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: Future.delayed(const Duration(seconds: 2), () => widget.getThumb),
        builder: (context, snapshot) => Container(
              padding: EdgeInsets.zero,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _snapshotByState(snapshot),
                ..._metaData(snapshot.data),
              ]),
            ));
  }
}
