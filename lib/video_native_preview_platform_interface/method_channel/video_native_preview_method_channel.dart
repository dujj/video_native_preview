import 'package:flutter/services.dart';

import '../platform_interface/platform_interface.dart';

/// A [VideoNativePreviewPlatformController] that uses a method channel to control the webview.
class MethodChannelVideoNativePreviewPlatform
    implements VideoNativePreviewPlatformController {
  /// Constructs an instance that will listen for views broadcasting to the
  /// given [id], using the given [VideoNativePreviewPlatformCallbacksHandler].
  MethodChannelVideoNativePreviewPlatform(
    int id,
    this._platformCallbacksHandler,
  ) : _channel = MethodChannel('plugins.flutter.io/video_native_preview_$id') {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  final VideoNativePreviewPlatformCallbacksHandler _platformCallbacksHandler;

  final MethodChannel _channel;

  Future<bool?> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTest':
        _platformCallbacksHandler.onTest();
        return null;
    }

    throw MissingPluginException(
      '${call.method} was invoked but has no handler',
    );
  }

  @override
  void test() {
    _channel.invokeMethod('test');
  }
}
