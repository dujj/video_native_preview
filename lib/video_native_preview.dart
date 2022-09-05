
import 'video_native_preview_platform_interface.dart';

class VideoNativePreview {
  Future<String?> getPlatformVersion() {
    return VideoNativePreviewPlatform.instance.getPlatformVersion();
  }
}
