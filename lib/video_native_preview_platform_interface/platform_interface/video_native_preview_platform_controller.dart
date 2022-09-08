import 'video_native_preview_platform_callbacks_handler.dart';

abstract class VideoNativePreviewPlatformController {
  /// Creates a new WebViewPlatform.
  ///
  /// Callbacks made by the WebView will be delegated to `handler`.
  ///
  /// The `handler` parameter must not be null.
  VideoNativePreviewPlatformController(
      VideoNativePreviewPlatformCallbacksHandler handler);

  void viewWillAppear();

  void viewDidDisappear();
}
