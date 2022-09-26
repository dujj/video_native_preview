package com.seewo.flutter.video_native_preview

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.os.Message
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.View.OnTouchListener
import android.widget.ImageView
import android.widget.SeekBar
import android.widget.SeekBar.OnSeekBarChangeListener
import android.widget.TextView
import com.tencent.mars.xlog.Log
import java.util.*

class MediaPlayerController(
    private val mContext: Context,
    isAudio: Boolean,
    retryText: String,
    failedText: String
) {
    var footBar: View? = null
        private set
    private var mErrorView: View? = null
    private var mSeekBar: SeekBar? = null
    private var mPlayImageView: ImageView? = null
    private var mCurrentTime: TextView? = null
    private var mTotalTime: TextView? = null
    private var showTimeoutMs: Int = BAR_DELAY_HIDE
    private var mIsTrackingTouch = false
    private var mIMediaPlayerOption: IMediaPlayerOption? = null
    private var mRotationImageView: ImageView? = null
    private var mIsPlaying = true
    private val mFormatBuilder: StringBuilder = StringBuilder()
    private val mFormatter: Formatter = Formatter(mFormatBuilder, Locale.getDefault())
    private var mIsLandscape = false
    private var mIsHideBar = true
    private var mClickListener: View.OnClickListener? = null
    private val mRetryText: String = retryText
    private val mFailedText: String = failedText
    private val mHandler: Handler = object : Handler(Looper.getMainLooper()) {
        override fun handleMessage(msg: Message) {
            when (msg.what) {
                HIDE_TOP_BAR -> setTopBarInvisible()
                HIDE_FOOT_BAR -> footBar?.visibility =
                    View.INVISIBLE
                else -> {}
            }
        }
    }

    private fun initView(context: Context, isAudio: Boolean) {
        initNoDoubleClickListener()
        footBar = if (isAudio) LayoutInflater.from(context)
            .inflate(R.layout.layout_audio_foot_bar, null) else LayoutInflater.from(context)
            .inflate(R.layout.layout_video_foot_bar, null)
        mSeekBar = footBar?.findViewById(R.id.seekbar_media)
        mSeekBar?.rotation = 180f //pinco 项目接入后莫名被旋转了180度，通过此恢复
        mPlayImageView = footBar?.findViewById(R.id.iv_play)
        mCurrentTime = footBar?.findViewById(R.id.tv_current_time)
        mTotalTime = footBar?.findViewById(R.id.tv_end_time)
        mRotationImageView = footBar?.findViewById(R.id.rotate_view)
        if (mRotationImageView != null) {
            setRotation(context)
            mRotationImageView?.setOnClickListener(mClickListener)
            mRotationImageView?.addOnLayoutChangeListener { v: View?, left: Int, top: Int, right: Int, bottom: Int, oldLeft: Int, oldTop: Int, oldRight: Int, oldBottom: Int ->
                setRotation(
                    context
                )
            }
        }
    }

    private fun setRotation(context: Context) {
        val orientation = context.resources.configuration.orientation
        Log.d(TAG, "setRotation orientation$orientation")
        if (orientation == Configuration.ORIENTATION_PORTRAIT) {
            updateRotationState(false)
        } else {
            updateRotationState(true)
        }
    }

    fun setHideBar(isHideBar: Boolean) {
        mIsHideBar = isHideBar
    }

    fun hideRotateBtn() {
        mRotationImageView?.visibility = View.GONE
    }

    private fun setListeners() {
        footBar?.setOnTouchListener(ResetDelayHideBarTouchListener())
        mSeekBar?.setOnSeekBarChangeListener(ProgressChangeListener())
        mPlayImageView?.setOnClickListener(mClickListener)
    }

    private fun initNoDoubleClickListener() {
        mClickListener = View.OnClickListener { v: View ->
            if (v === mPlayImageView) {
                doPauseResume()
            } else if (v === mRotationImageView) {
                onHandleScreenOrientation()
            }
        }
    }

    private fun onHandleScreenOrientation() {
        mIMediaPlayerOption?.onScreenOrientation(!mIsLandscape)
    }

    private fun doPauseResume() {
        mIMediaPlayerOption?.doPauseResume()
    }

    private fun updateProgress(fromUser: Boolean, msec: Int) {
        mIMediaPlayerOption?.updateProgress(fromUser, msec)
    }

    private inner class ProgressChangeListener : OnSeekBarChangeListener {
        private var progressFromUser = 0
        override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
            if (!fromUser) {
                return
            }
            resetDelayHideTopBar()
            resetDelayHideFootBar()
            progressFromUser = progress
            mCurrentTime?.text = stringForTime(progress)
            updateProgress(fromUser, progress)
        }

        override fun onStartTrackingTouch(seekBar: SeekBar) {
            mIsTrackingTouch = true
        }

        override fun onStopTrackingTouch(seekBar: SeekBar) {
            mIsTrackingTouch = false
            Log.d(TAG, "seekTo: $progressFromUser")
            mIMediaPlayerOption?.seekTo(true, progressFromUser)
            resetDelayHideFootBar()
        }
    }

    private inner class ResetDelayHideBarTouchListener : OnTouchListener {
        override fun onTouch(v: View, event: MotionEvent): Boolean {
            resetDelayHideTopBar()
            resetDelayHideFootBar()
            return true
        }
    }

    private fun resetDelayHideTopBar() {
        mHandler.removeMessages(HIDE_TOP_BAR)
        if (!mIsPlaying || !mIsHideBar) {
            return
        }
        mHandler.sendEmptyMessageDelayed(HIDE_TOP_BAR, showTimeoutMs.toLong())
    }

    private fun resetDelayHideFootBar() {
        mHandler.removeMessages(HIDE_FOOT_BAR)
        if (!mIsPlaying || !mIsHideBar) {
            return
        }
        mHandler.sendEmptyMessageDelayed(HIDE_FOOT_BAR, showTimeoutMs.toLong())
    }

    fun setMediaPlayerControl(mediaPlayerOption: IMediaPlayerOption?) {
        mIMediaPlayerOption = mediaPlayerOption
    }

    fun revertTopBarVisibility() {
        if (!mIsHideBar) {
            return
        }
        if (footBar?.visibility == View.INVISIBLE) {
            showTopBarVisibility()
        } else {
            setTopBarInvisible()
        }
    }

    private fun setTopBarInvisible() {
        mIMediaPlayerOption?.onTopBarVisibility(false)
    }

    private fun setTopBarVisible() {
        mIMediaPlayerOption?.onTopBarVisibility(true)
    }

    fun showTopBarVisibility() {
        setTopBarVisible()
        resetDelayHideTopBar()
    }

    fun revertFootBarVisibility() {
        if (!mIsHideBar) {
            return
        }
        if (footBar?.visibility == View.INVISIBLE) {
            showFootBarVisibility()
        } else {
            footBar?.visibility = View.INVISIBLE
        }
    }

    fun showFootBarVisibility() {
        footBar?.visibility = View.VISIBLE
        resetDelayHideFootBar()
    }

    fun updatePlayState(isPlaying: Boolean) {
        mIsPlaying = isPlaying
        if (isPlaying) {
            mPlayImageView?.setImageResource(R.drawable.ic_media_pause)
        } else {
            mPlayImageView?.setImageResource(R.drawable.ic_media_play)
        }
        setTopBarVisible()
        resetDelayHideTopBar()
        footBar?.visibility = View.VISIBLE
        resetDelayHideFootBar()
    }

    private fun updateRotationState(isLandscape: Boolean) {
        if (mRotationImageView == null) {
            return
        }
        mIsLandscape = isLandscape
        if (isLandscape) {
            mRotationImageView?.setImageResource(R.drawable.ic_exit_full_screen)
        } else {
            mRotationImageView?.setImageResource(R.drawable.ic_full_screen)
        }
    }

    fun updateProgress(progress: Int) {
        if (mIsTrackingTouch) {
            Log.d(TAG, "updateProgress return")
            return
        }
        mSeekBar?.progress = progress
    }

    val totalDuration: Int
        get() = mSeekBar?.max ?: 100
    val currentDuration: Int
        get() = mSeekBar?.progress ?: 0

    fun updateSecondaryProgress(secondaryProgress: Int) {
        mSeekBar?.secondaryProgress = secondaryProgress
    }

    fun updateCurrentTime(currentTime: String?) {
        if (mIsTrackingTouch) {
            Log.d(TAG, "updateCurrentTime return")
            return
        }
        mCurrentTime?.text = currentTime
    }

    fun updateDuration(duration: String?) {
        mTotalTime?.text = duration
    }

    fun setProgressMax(max: Int) {
        mSeekBar?.max = max
    }

    fun release() {
        mHandler.removeCallbacksAndMessages(null)
    }

    fun setEnable(enable: Boolean) {
        mSeekBar?.isEnabled = enable
        mPlayImageView?.isEnabled = enable
        mRotationImageView?.isEnabled = enable
    }

    val errorView: View
        get() {
            if (mErrorView == null) {
                mErrorView = LiveErrorView(mContext, mRetryText, mFailedText)
                mErrorView?.setBackgroundColor(Color.BLACK)
            }
            return mErrorView!!
        }

    private fun stringForTime(timeMs: Int): String {
        val totalSeconds = timeMs / 1000
        val seconds = totalSeconds % 60
        val minutes = totalSeconds / 60 % 60
        val hours = totalSeconds / 3600 % 60
        mFormatBuilder.setLength(0)
        return mFormatter.format("%02d:%02d", minutes + hours * 60, seconds).toString()
    }

    companion object {
        private const val TAG = "MediaPlayerController"
        private const val HIDE_TOP_BAR = 1
        private const val HIDE_FOOT_BAR = 2
        private const val BAR_DELAY_HIDE = 5 * 1000
    }

    init {
        initView(mContext, isAudio)
        setListeners()
    }
}