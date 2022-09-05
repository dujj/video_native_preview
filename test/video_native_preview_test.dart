import 'package:flutter_test/flutter_test.dart';
import 'package:video_native_preview/video_native_preview.dart';
import 'package:video_native_preview/video_native_preview_platform_interface.dart';
import 'package:video_native_preview/video_native_preview_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVideoNativePreviewPlatform
    with MockPlatformInterfaceMixin
    implements VideoNativePreviewPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VideoNativePreviewPlatform initialPlatform = VideoNativePreviewPlatform.instance;

  test('$MethodChannelVideoNativePreview is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVideoNativePreview>());
  });

  test('getPlatformVersion', () async {
    VideoNativePreview videoNativePreviewPlugin = VideoNativePreview();
    MockVideoNativePreviewPlatform fakePlatform = MockVideoNativePreviewPlatform();
    VideoNativePreviewPlatform.instance = fakePlatform;

    expect(await videoNativePreviewPlugin.getPlatformVersion(), '42');
  });
}
