import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../video_native_preview_platform_interface/video_native_preview_platform_interface.dart';

class AndroidVideoNativePreview implements VideoNativePreviewPlatform {
  @override
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
    required VideoNativePreviewPlatformCallbacksHandler
        videoNativePreviewPlatformCallbacksHandler,
    VideoNativePreviewPlatformCreatedCallback?
        onVideoNativePreviewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  }) {
    return GestureDetector(
      onLongPress: () {},
      excludeFromSemantics: true,
      child: AndroidView(
        viewType: 'plugins.flutter.io/video_native_preview',
        onPlatformViewCreated: (int id) {
          if (onVideoNativePreviewPlatformCreated != null) {
            onVideoNativePreviewPlatformCreated(
                MethodChannelVideoNativePreviewPlatform(
                    id, videoNativePreviewPlatformCallbacksHandler));
          }
        },
        gestureRecognizers: gestureRecognizers,
        layoutDirection: Directionality.maybeOf(context) ?? TextDirection.rtl,
        creationParams: creationParams.toJson(),
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
