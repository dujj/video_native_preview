import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../video_native_preview_platform_interface/video_native_preview_platform_interface.dart';

/// Builds an iOS VideoNativePreview.
///
/// This is used as the default implementation for [VideoNativePreview.platform] on iOS. It uses
/// a [UiKitView] to embed the webview in the widget hierarchy, and uses a method channel to
/// communicate with the platform code.
class CupertinoVideoNativePreview implements VideoNativePreviewPlatform {
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
    return UiKitView(
      viewType: 'plugins.flutter.io/video_native_preview',
      onPlatformViewCreated: (int id) {
        if (onVideoNativePreviewPlatformCreated != null) {
          onVideoNativePreviewPlatformCreated(
              MethodChannelVideoNativePreviewPlatform(
                  id, videoNativePreviewPlatformCallbacksHandler));
        }
      },
      gestureRecognizers: gestureRecognizers,
      creationParams: creationParams.toJson(),
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
