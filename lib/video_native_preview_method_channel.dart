import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'video_native_preview_platform_interface.dart';

/// An implementation of [VideoNativePreviewPlatform] that uses method channels.
class MethodChannelVideoNativePreview extends VideoNativePreviewPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_native_preview');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
