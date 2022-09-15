package com.seewo.flutter.video_native_preview

/**
 * Created by ctj on 2022/9/15.
 */
interface IViewOption {
    fun onScreenOrientation(landscape: Boolean)
    fun onTopBarVisibility(visible: Boolean)
}