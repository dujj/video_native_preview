package com.seewo.flutter.video_native_preview

import android.content.Context
import android.util.Log
import android.view.View
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

/**
 * Created by ctj on 2022/9/15.
 */
class MediaPlayerView : PlatformView, MethodChannel.MethodCallHandler, IViewOption {

    private var mMethodChannel: MethodChannel? = null
    private var mPlayerView: PlayerView? = null

    constructor(
        context: Context,
        methodChannel: MethodChannel,
        url: String,
        duration: Long,
        isAudio: Boolean,
        retryText: String,
        failedText: String
    ) {
        this.mMethodChannel = methodChannel
        mPlayerView = PlayerView(
            context,
            url = url,
            duration = duration,
            isAudio = isAudio,
            retryText = retryText,
            failedText = failedText
        )
        mPlayerView?.mViewOption = this
    }

    override fun getView(): View? {
        return mPlayerView
    }

    override fun dispose() {
        mMethodChannel?.setMethodCallHandler(null)
        mPlayerView?.onDestroy()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "viewWillAppear" -> {
                mPlayerView?.onResume()
            }
            "viewDidDisappear" -> {
                mPlayerView?.onPause()
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onScreenOrientation(landscape: Boolean) {
        var orientation = if (landscape) "landscape" else "portrait"
        Log.d("MediaPlayerView", "onRotate :$orientation")
        mMethodChannel?.invokeMethod("onRotate", orientation)
    }

    override fun onTopBarVisibility(visible: Boolean) {
        var status = if (visible) "true" else "false"
        Log.d("MediaPlayerView", "onChangeAppBar :$status")
        mMethodChannel?.invokeMethod("onChangeAppBar", status)
    }
}