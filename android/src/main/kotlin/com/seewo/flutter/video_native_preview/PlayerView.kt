package com.seewo.flutter.video_native_preview

import android.content.Context
import android.os.Handler
import android.os.Message
import android.util.AttributeSet
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import com.pinco.player.media.IjkVideoView
import tv.danmaku.ijk.media.player.IMediaPlayer
import java.lang.ref.WeakReference
import java.util.*

/**
 * Created by ctj on 2022/9/15.
 */
class PlayerView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    url: String,
    duration: Long,
    isAudio: Boolean,
    retryText: String,
    failedText: String
) : FrameLayout(context, attrs, defStyleAttr), IMediaPlayerOption,
    LiveErrorView.LiveErrorViewListener {

    companion object {
        private const val TAG = "PlayerView"
        private const val MESSAGE_UPDATE_PROGRESS = 100
        private const val DURATION = 500
        private const val MEDIA_ERROR = -10000
        private const val RETRY_COUNT = 3
    }

    private var mVideoView: IjkVideoView? = null
    private var mContainer: FrameLayout? = null
    private var mMediaController: MediaController? = null
    private var mFormatBuilder: StringBuilder? = null
    private var mFormatter: Formatter? = null
    private var mHandler: Handler? = null
    private var mFootBar: View? = null
    private var mErrorView: View? = null
    private var mPlayImageView: ImageView? = null
    private var mCurrentPositionTextView: TextView? = null
    private var mCurrentPosition = 0
    private var mRetryCount = 0
    private var mFileUrl: String? = null
    private var mSeekToDuration: Long = 0
    private var mIsPlayBeforeBackground = false
    private var mIsAudio = false
    private var mAnimationLoadingView: AnimationLoadingView? = null
    private var mUpdateProgressDelay: Long = 0
    private var mRetryText: String? = null
    private var mFailedText: String? = null
    var mViewOption: IViewOption? = null

    init {
        mFileUrl = url
        mSeekToDuration = duration
        mIsAudio = isAudio
        mRetryText = retryText
        mFailedText = failedText
        initView()
    }

    private fun getContentView(): Int {
        return if (mIsAudio) R.layout.layout_audio_preview else R.layout.layout_video_preview
    }

    private fun initView() {
        inflate(context, getContentView(), this)
        mHandler = MyHandler(this)
        mFormatBuilder = java.lang.StringBuilder()
        mFormatter = Formatter(mFormatBuilder, Locale.getDefault())
        mContainer = findViewById(R.id.container)
        mContainer?.setOnClickListener {
            mMediaController?.revertTopBarVisibility()
            mMediaController?.revertFootBarVisibility()
        }
        mPlayImageView = findViewById(R.id.play_imageView)
        mPlayImageView?.setOnClickListener {
            showPlayState()
        }
        mCurrentPositionTextView = findViewById(R.id.tv_current_position)
        initVideoView()
        initMediaController()
    }

    fun onPause() {
        if (mVideoView != null) {
            mIsPlayBeforeBackground = mVideoView?.isPlaying ?: false
            if (mIsPlayBeforeBackground) {
                onPauseVideo()
            }
        }
    }

    fun onResume() {
        if (mIsPlayBeforeBackground) {
            showPlayState()
        }
    }

    private fun initMediaController() {
        mMediaController = MediaController(context, mIsAudio, mRetryText, mFailedText)
        mMediaController?.setMediaPlayerControl(this)
        mErrorView = mMediaController?.errorView
        val errorViewLayoutParams = LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        mErrorView?.layoutParams = errorViewLayoutParams
        mErrorView?.visibility = GONE
        mContainer?.addView(mErrorView)
        val liveErrorView = mErrorView as LiveErrorView?
        liveErrorView?.listener = this
        mFootBar = mMediaController?.footBar
        val footBarParams = LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            if (mIsAudio) ViewGroup.LayoutParams.WRAP_CONTENT else resources.getDimensionPixelSize(R.dimen.video_foot_bar_height)
        )
        val margin =
            resources.getDimensionPixelSize(if (mIsAudio) R.dimen.audio_foot_bar_margin else R.dimen.video_foot_bar_margin)
        val leftRightMargin =
            if (mIsAudio) resources.getDimensionPixelSize(R.dimen.size_24) else resources.getDimensionPixelSize(
                R.dimen.size_16
            )
        footBarParams.leftMargin = leftRightMargin
        footBarParams.rightMargin = leftRightMargin
        footBarParams.bottomMargin = margin
        footBarParams.gravity = Gravity.BOTTOM
        mContainer?.addView(mFootBar, footBarParams)
        mMediaController?.setEnable(false)

        if (mIsAudio) {
            mMediaController?.setHideBar(false)
            mMediaController?.hideFullScreenBtn()
        }
    }

    private fun initVideoView() {
        mVideoView = findViewById(R.id.player_view)
        showLoadingView()
        Log.d(TAG, "initVideoView: $mFileUrl")
        mVideoView?.setVideoPath(mFileUrl)
        mVideoView?.requestFocus()
        mVideoView?.setOnPreparedListener {
            mVideoView?.start()
            val duration = mVideoView?.duration ?: -1
            Log.d(TAG, "onPrepared: $duration currentDuration: $mSeekToDuration")
            mMediaController?.setProgressMax(duration)
            mMediaController?.updateDuration(stringForTime(duration))
            mMediaController?.setEnable(true)
            mMediaController?.showTopBarVisibility()
            mMediaController?.showFootBarVisibility()
            dismissLoadingView()
            mHandler?.sendEmptyMessageDelayed(MESSAGE_UPDATE_PROGRESS, DURATION.toLong())
            if (mSeekToDuration in 1 until duration) {
                mVideoView?.seekTo(mSeekToDuration.toInt())
                mSeekToDuration = 0L
            }
        }
        mVideoView?.setOnCompletionListener {
            val duration = mVideoView?.duration ?: -1
            mHandler?.removeCallbacksAndMessages(null)
            mMediaController?.updateCurrentTime(stringForTime(duration))
            mMediaController?.updateProgress(duration)
            showPauseState()
        }
        mVideoView?.setOnInfoListener { _: IMediaPlayer?, what: Int, extra: Int ->
            Log.d(TAG, "onInfo: $what ,extra: $extra")
            false
        }
        mVideoView?.setOnErrorListener { _: IMediaPlayer?, what: Int, extra: Int ->
            Log.e(TAG, "========onError=======: $what extra: $extra")
            if (what == MEDIA_ERROR) {
                if (mRetryCount < RETRY_COUNT) {
                    showLoadingView()
                    mVideoView?.resume()
                    mRetryCount++
                } else {
                    mRetryCount = 0
                    dismissLoadingView()
                    mErrorView?.visibility = VISIBLE
                }
                mMediaController?.setEnable(false)
                mHandler?.removeCallbacksAndMessages(null)
            } else {
                dismissLoadingView()
                mErrorView?.visibility = VISIBLE
            }
            true
        }
        mVideoView?.setOnBufferingUpdateListener { _: IMediaPlayer?, percent: Int ->
            val buffer = mVideoView?.duration ?: -1 * (percent / 100f)
            mMediaController?.updateSecondaryProgress(buffer.toInt())
        }
    }


    private fun showLoadingView() {
        mErrorView?.visibility = GONE
        if (mAnimationLoadingView == null) {
            mAnimationLoadingView = AnimationLoadingView(context, R.drawable.anim_live_loading)
        }
        if (mContainer != null) {
            mAnimationLoadingView?.show(mContainer!!)
        }
    }

    private fun dismissLoadingView() {
        mAnimationLoadingView?.dismiss()
    }

    private fun onRetry() {
        mRetryCount = 0
        mVideoView?.resume()
        mVideoView?.seekTo(mCurrentPosition)
        Log.d(TAG, "onRetry")
    }

    private fun updateProgress() {
        val currentPosition = mVideoView?.currentPosition ?: 0
        if (mCurrentPosition != currentPosition) {
            dismissLoadingView()
            mUpdateProgressDelay = 0
        } else {
            mUpdateProgressDelay += DURATION.toLong()
        }
        if (mUpdateProgressDelay > 2 * DURATION) {
            showLoadingView()
        }
        mCurrentPosition = currentPosition
        mMediaController?.updateProgress(currentPosition)
        mMediaController?.updateCurrentTime(stringForTime(currentPosition))
        mHandler?.sendEmptyMessageDelayed(MESSAGE_UPDATE_PROGRESS, DURATION.toLong())
    }

    private fun stringForTime(timeMs: Int): String? {
        val totalSeconds = timeMs / 1000
        val seconds = totalSeconds % 60
        val minutes = totalSeconds / 60 % 60
        val hours = totalSeconds / 3600 % 60
        mFormatBuilder?.setLength(0)
        return mFormatter?.format("%02d:%02d", minutes + hours * 60, seconds).toString()
    }

    private fun showPlayState() {
        mPlayImageView?.visibility = GONE
        if (mVideoView != null) {
            mVideoView?.start()
            mMediaController?.updatePlayState(true)
            mHandler?.sendEmptyMessageDelayed(MESSAGE_UPDATE_PROGRESS, DURATION.toLong())
        }
    }

    private fun showPauseState() {
        if (!mIsAudio) {
            mPlayImageView?.visibility = VISIBLE
        }
        onPauseVideo()
    }

    private fun onPauseVideo() {
        if (mVideoView != null) {
            mVideoView?.pause()
            dismissLoadingView()
            mMediaController?.updatePlayState(false)
            mHandler?.removeCallbacksAndMessages(null)
        }
    }

    override fun doPauseResume() {
        if (mVideoView?.isPlaying == true) {
            showPauseState()
            Log.d(TAG, "doPauseResume pause")
        } else {
            showPlayState()
            Log.d(TAG, "doPauseResume play")
        }
    }

    override fun seekTo(fromUser: Boolean, msec: Int) {
        if (fromUser) {
            showLoadingView()
            mCurrentPositionTextView?.visibility = GONE
            mVideoView?.seekTo(msec)
            showPlayState()
        }
    }

    override fun updateProgress(fromUser: Boolean, msec: Int) {
        if (fromUser) {
            if (mCurrentPositionTextView?.visibility == GONE) {
                mCurrentPositionTextView?.visibility = VISIBLE
            }
            mCurrentPositionTextView?.text = stringForTime(msec)
        }
    }

    override fun onScreenOrientation(landscape: Boolean) {
        mViewOption?.onScreenOrientation(landscape)
    }

    override fun onTopBarVisibility(visible: Boolean) {
        mViewOption?.onTopBarVisibility(visible)
    }

    override fun onLiveRetry() {
        showLoadingView()
        onRetry()
    }

    fun onDestroy() {
        mHandler?.removeCallbacksAndMessages(null)
        mMediaController?.release()
        mVideoView?.release(true)
        mViewOption = null
    }

    private class MyHandler(view: PlayerView) :
        Handler() {
        private val mViewReference: WeakReference<PlayerView> = WeakReference<PlayerView>(view)
        override fun handleMessage(msg: Message) {
            super.handleMessage(msg)
            if (msg.what == MESSAGE_UPDATE_PROGRESS) {
                val view: PlayerView? =
                    mViewReference.get()
                view?.updateProgress()
            }
        }
    }

}