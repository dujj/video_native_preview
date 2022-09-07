#import "VideoNativePreviewPlugin.h"
#if __has_include(<video_native_preview/video_native_preview-Swift.h>)
#import <video_native_preview/video_native_preview-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "video_native_preview-Swift.h"
#endif

@implementation VideoNativePreviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftVideoNativePreviewPlugin registerWithRegistrar:registrar];
}
@end
