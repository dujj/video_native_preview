import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'video_native_preview_android/video_native_preview_surface_android.dart';
import 'video_native_preview_cupertino/video_native_preview_cupertino.dart';
import 'video_native_preview_platform_interface/video_native_preview_platform_interface.dart';

typedef VideoNativePreviewCreatedCallback = void Function(
    VideoNativePreviewController controller);

typedef VideoNativePreviewStringCallback = void Function(String);

class VideoNativePreview extends StatefulWidget {
  const VideoNativePreview({
    Key? key,
    this.onVideoNativePreviewCreated,
    required this.initialUrl,
    this.gestureRecognizers,
    this.onRotate,
    this.onChangeAppBar,
    this.failedText = 'failed',
    this.retryText = 'retry',
  }) : super(key: key);

  static VideoNativePreviewPlatform? _platform;

  static set platform(VideoNativePreviewPlatform? platform) {
    _platform = platform;
  }

  static VideoNativePreviewPlatform get platform {
    if (_platform == null) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          _platform = SurfaceAndroidVideoNativePreview();
          break;
        case TargetPlatform.iOS:
          _platform = CupertinoVideoNativePreview();
          break;
        default:
          throw UnsupportedError(
              "Trying to use the default webview implementation for $defaultTargetPlatform but there isn't a default one");
      }
    }
    return _platform!;
  }

  /// If not null invoked once the view is created.
  final VideoNativePreviewCreatedCallback? onVideoNativePreviewCreated;

  /// Which gestures should be consumed by the web view.
  ///
  /// It is possible for other gesture recognizers to be competing with the web view on pointer
  /// events, e.g if the web view is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The web view will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// When this set is empty or null, the web view will only handle pointer events for gestures that
  /// were not claimed by any other gesture recognizer.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// The initial URL to load.
  final String initialUrl;

  final VideoNativePreviewStringCallback? onRotate;
  final VideoNativePreviewStringCallback? onChangeAppBar;

  final String failedText;
  final String retryText;

  @override
  State<StatefulWidget> createState() => _VideoNativePreviewState();
}

class _VideoNativePreviewState extends State<VideoNativePreview> {
  final Completer<VideoNativePreviewController> _controller =
      Completer<VideoNativePreviewController>();

  late _PlatformCallbacksHandler _platformCallbacksHandler;

  @override
  Widget build(BuildContext context) {
    return VideoNativePreview.platform.build(
      context: context,
      onVideoNativePreviewPlatformCreated: _onVideoNativePreviewPlatformCreated,
      videoNativePreviewPlatformCallbacksHandler: _platformCallbacksHandler,
      gestureRecognizers: widget.gestureRecognizers,
      creationParams: _creationParamsfromWidget(widget),
    );
  }

  @override
  void initState() {
    super.initState();
    _platformCallbacksHandler = _PlatformCallbacksHandler(widget);
  }

  @override
  void didUpdateWidget(VideoNativePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.future.then((VideoNativePreviewController controller) {
      _platformCallbacksHandler._widget = widget;
      controller._updateWidget(widget);
    });
  }

  void _onVideoNativePreviewPlatformCreated(
      VideoNativePreviewPlatformController? webViewPlatform) {
    final VideoNativePreviewController controller =
        VideoNativePreviewController._(
      widget,
      webViewPlatform!,
    );
    _controller.complete(controller);
    if (widget.onVideoNativePreviewCreated != null) {
      widget.onVideoNativePreviewCreated!(controller);
    }
  }
}

CreationParams _creationParamsfromWidget(VideoNativePreview widget) {
  return CreationParams(
    initialUrl: widget.initialUrl,
    failedText: widget.failedText,
    retryText: widget.retryText,
  );
}

class _PlatformCallbacksHandler
    implements VideoNativePreviewPlatformCallbacksHandler {
  _PlatformCallbacksHandler(this._widget);

  VideoNativePreview _widget;

  /// orientation : 'portrait' or 'landscape'
  @override
  void onRotate(String orientation) {
    if (_widget.onRotate != null) {
      _widget.onRotate!(orientation);
    }
  }

  /// status : 'false' or 'true'
  @override
  void onChangeAppBar(String status) {
    if (_widget.onChangeAppBar != null) {
      _widget.onChangeAppBar!(status);
    }
  }
}

class VideoNativePreviewController {
  VideoNativePreviewController._(
    this._widget,
    this._videoNativePreviewPlatformController,
  );

  final VideoNativePreviewPlatformController
      _videoNativePreviewPlatformController;

  VideoNativePreview _widget;

  Future<void> _updateWidget(VideoNativePreview widget) async {
    _widget = widget;
  }

  void viewWillAppear() {
    _videoNativePreviewPlatformController.viewWillAppear();
  }

  void viewDidDisappear() {
    _videoNativePreviewPlatformController.viewDidDisappear();
  }
}
