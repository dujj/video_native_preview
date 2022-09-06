import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/gestures/recognizer.dart';
import 'package:flutter/src/foundation/basic_types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:video_native_preview/video_native_preview_platform_interface/video_native_preview_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVideoNativePreviewPlatform
    with MockPlatformInterfaceMixin
    implements VideoNativePreviewPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Widget build(
      {required BuildContext context,
      required CreationParams creationParams,
      required VideoNativePreviewPlatformCallbacksHandler
          videoNativePreviewPlatformCallbacksHandler,
      VideoNativePreviewPlatformCreatedCallback?
          onVideoNativePreviewPlatformCreated,
      Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers}) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

void main() {}
