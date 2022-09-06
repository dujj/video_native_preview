import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../types/types.dart';
import 'video_native_preview_platform_callbacks_handler.dart';
import 'video_native_preview_platform_controller.dart';

/// Signature for callbacks reporting that a [VideoNativePreviewPlatformController] was created.
///
/// See also the `onVideoNativePreviewPlatformCreated` argument for [VideoNativePreviewPlatform.build].
typedef VideoNativePreviewPlatformCreatedCallback = void Function(
    VideoNativePreviewPlatformController? videoNativePreviewPlatformController);

/// Interface for a platform implementation of a WebView.
///
/// [VideoNativePreview.platform] controls the builder that is used by [VideoNativePreview].
/// [AndroidVideoNativePreviewPlatform] and [CupertinoWVideoNativePreviewPlatform] are the default implementations
/// for Android and iOS respectively.
abstract class VideoNativePreviewPlatform {
  /// Builds a new VideoNativePreview.
  ///
  /// Returns a Widget tree that embeds the created VideoNativePreview.
  ///
  /// `creationParams` are the initial parameters used to setup the VideoNativePreview.
  ///
  /// `videoNativePreviewPlatformHandler` will be used for handling callbacks that are made by the created
  /// [VideoNativePreviewPlatformController].
  ///
  /// `onVideoNativePreviewPlatformCreated` will be invoked after the platform specific [VideoNativePreviewPlatformController]
  /// implementation is created with the [VideoNativePreviewPlatformController] instance as a parameter.
  ///
  /// `videoNativePreviewPlatformHandler` must not be null.
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
    required VideoNativePreviewPlatformCallbacksHandler
        videoNativePreviewPlatformCallbacksHandler,
    VideoNativePreviewPlatformCreatedCallback?
        onVideoNativePreviewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  });
}
