package com.seewo.flutter.video_native_preview

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Created by ctj on 2022/9/14.
 */
class MediaPlayerFactory(private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args?.let { args as Map<String, Any> }
        var url = params?.get("initialUrl") as String? ?: ""
        var type = params?.get("type") as String? ?: "video"
        var failedText = params?.get("failedText") as String? ?: ""
        var retryText = params?.get("retryText") as String? ?: ""
        var methodChannel =
            MethodChannel(messenger, "plugins.flutter.io/video_native_preview_$viewId")
        return MediaPlayerView(
            context = context,
            methodChannel = methodChannel,
            url = url,
            duration = 0,
            isAudio = type == "audio",
            failedText = failedText,
            retryText = retryText
        )
    }
}