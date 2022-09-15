package com.seewo.flutter.video_native_preview

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin

/** VideoNativePreviewPlugin */
class VideoNativePreviewPlugin : FlutterPlugin {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        binding
            .platformViewRegistry
            .registerViewFactory(
                "plugins.flutter.io/video_native_preview",
                MediaPlayerFactory(binding.binaryMessenger)
            )
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    }
}
