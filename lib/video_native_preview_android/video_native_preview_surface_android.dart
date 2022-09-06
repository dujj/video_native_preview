import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../video_native_preview_platform_interface/video_native_preview_platform_interface.dart';
import 'video_native_preview_android.dart';

class SurfaceAndroidVideoNativePreview extends AndroidVideoNativePreview {
  @override
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
    VideoNativePreviewPlatformCreatedCallback?
        onVideoNativePreviewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    required VideoNativePreviewPlatformCallbacksHandler
        videoNativePreviewPlatformCallbacksHandler,
  }) {
    return PlatformViewLink(
      viewType: 'plugins.flutter.io/video_native_preview',
      surfaceFactory: (
        BuildContext context,
        PlatformViewController controller,
      ) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: gestureRecognizers ??
              const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: 'plugins.flutter.io/video_native_preview',
          layoutDirection: TextDirection.rtl,
          creationParamsCodec: const StandardMessageCodec(),
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..addOnPlatformViewCreatedListener((int id) {
            if (onVideoNativePreviewPlatformCreated != null) {
              onVideoNativePreviewPlatformCreated(
                MethodChannelVideoNativePreviewPlatform(
                    id, videoNativePreviewPlatformCallbacksHandler),
              );
            }
          })
          ..create();
      },
    );
  }
}
