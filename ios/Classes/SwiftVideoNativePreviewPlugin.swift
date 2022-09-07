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

public protocol VideoNativePreviewDelegate: NSObjectProtocol {
    func rotate(_ orientation: String)
    func changeAppBar(_ show: String)
}

public class VideoNativePreviewController: NSObject, FlutterPlatformView, VideoNativePreviewDelegate {
    
    var viewId: Int64
    
    var channel: FlutterMethodChannel
    
    var preview: VideoNativePreview
    
    public init(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, messenger: FlutterBinaryMessenger) {
        
        self.viewId = viewId
        let channelName = "plugins.flutter.io/video_native_preview_\(viewId)"
        self.channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        
        var url: String = ""
        if let dic = args as? [String: Any] {
            url = dic["initialUrl"] as? String ?? ""
        }
        self.preview = VideoNativePreview(frame: frame, url: url)
        
        super.init()
        
        self.preview.delegate = self
        
        self.channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }
    
    public func view() -> UIView {
        return self.preview
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "viewWillAppear":
            self.preview.viewWillAppear()
            result(nil)
        case "viewDidDisappear":
            self.preview.viewDidDisappear()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func rotate(_ orientation: String) {
        self.channel.invokeMethod("rotateDeviceOrientation", arguments: ["orientation": orientation])
    }
    
    public func changeAppBar(_ show: String) {
        self.channel.invokeMethod("changeAppBar", arguments: ["status": show])
    }
}
