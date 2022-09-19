package com.seewo.flutter.video_native_preview

interface IMediaPlayerOption {
    fun doPauseResume()
    fun seekTo(fromUser: Boolean, msec: Int)
    fun updateProgress(fromUser: Boolean, msec: Int)
    fun onScreenOrientation(landscape: Boolean)
    fun onTopBarVisibility(visible: Boolean)
}