abstract class VideoNativePreviewPlatformCallbacksHandler {
  /// orientation : 'portrait' or 'landscape'
  void onRotate(String orientation);

  /// status : 'false' or 'true'
  void onChangeAppBar(String status);
}
