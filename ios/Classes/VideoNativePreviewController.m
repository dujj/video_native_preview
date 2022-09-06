//
//  VideoNativePreviewController.m
//  video_native_preview
//
//  Created by dujianjie on 2022/9/6.
//
#import "VideoNativePreview.h"
#import "VideoNativePreviewController.h"

@implementation VideoNativePreviewController{
    VideoNativePreview *_view;
    int64_t _viewId;
    FlutterMethodChannel *_channel;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  if (self = [super init]) {
      _viewId = viewId;

      NSString* channelName = [NSString stringWithFormat:@"plugins.flutter.io/video_native_preview_%lld", viewId];
      _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
      
      
      _view = [[VideoNativePreview alloc] initWithFrame:frame];

      NSLog(@"----------------%@", args);
      __weak __typeof__(self) weakSelf = self;
      [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        [weakSelf onMethodCall:call result:result];
      }];

  }
  return self;
}

- (UIView*)view {
  return _view;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([[call method] isEqualToString:@"test"]) {
      
      result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}
@end
