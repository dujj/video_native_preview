#import "VideoNativePreviewFactory.h"
#import "VideoNativePreviewPlugin.h"

@implementation VideoNativePreviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    VideoNativePreviewFactory *factory = [[VideoNativePreviewFactory alloc] initWithMessenger:registrar.messenger];
        [registrar registerViewFactory:factory withId:@"plugins.flutter.io/video_native_preview"];
}



@end
