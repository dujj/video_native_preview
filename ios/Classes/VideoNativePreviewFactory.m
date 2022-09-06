//
//  VideoNativePreviewFactory.m
//  video_native_preview
//
//  Created by dujianjie on 2022/9/6.
//
#import "VideoNativePreviewController.h"
#import "VideoNativePreviewFactory.h"

@implementation VideoNativePreviewFactory{
    NSObject<FlutterBinaryMessenger>* _messenger;
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    return [[VideoNativePreviewController alloc] initWithFrame:frame viewIdentifier:viewId arguments:args binaryMessenger:_messenger];
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  self = [super init];
  if (self) {
    _messenger = messenger;
  }
  return self;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}
@end
