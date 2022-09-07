import Flutter
import UIKit

public class SwiftVideoNativePreviewPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = VideoNativePreviewFactory(registrar.messenger())
    registrar.register(factory, withId: "plugins.flutter.io/video_native_preview")
  }
}

public class VideoNativePreviewFactory: NSObject, FlutterPlatformViewFactory {
    var messenger: FlutterBinaryMessenger
    
    public init(_ messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return VideoNativePreviewController(withFrame: frame, viewIdentifier: viewId, arguments: args, messenger: self.messenger)
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    
}

public class VideoNativePreviewController: NSObject, FlutterPlatformView {
    
    var viewId: Int64
    
    var channel: FlutterMethodChannel
    
    var preview: VideoNativePreview
    
    public init(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, messenger: FlutterBinaryMessenger) {
        
        self.viewId = viewId
        let channelName = "plugins.flutter.io/video_native_preview_\(viewId)"
        self.channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        self.preview = VideoNativePreview(frame: frame)
        
        super.init()
        
        self.channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }
    
    public func view() -> UIView {
        return self.preview
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "test":
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

}
