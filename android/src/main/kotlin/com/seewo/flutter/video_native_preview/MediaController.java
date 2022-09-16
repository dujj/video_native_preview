package com.seewo.flutter.video_native_preview;

import static android.content.res.Configuration.ORIENTATION_PORTRAIT;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;

import java.util.Formatter;
import java.util.Locale;

public class MediaController {
    private static final String TAG = "MediaController";
    private static final int HIDE_TOP_BAR = 1;
    private static final int HIDE_FOOT_BAR = 2;
    private static final int BAR_DELAY_HIDE = 5 * 1000;
    private Context mContext;
    private LinearLayout mFootBar;
    private View mErrorView;
    private SeekBar mPlayProgressSeekBar;
    private ImageView mPlayImageView;
    private TextView mCurrentTime;
    private TextView mTotalTime;
    private int mShowTimeOutMs;
    private boolean mIsTrackingTouch;
    private IMediaPlayerOption mIMediaPlayerOption;
    private ImageView mRotationImageView;
    private boolean mIsPlaying = true;
    private StringBuilder mFormatBuilder;
    private Formatter mFormatter;
    private boolean mIsLandscape;
    private boolean mIsHideBar = true;
    private View.OnClickListener mClickListener;

    private String mRetryText;
    private String mFailedText;

    private final Handler mHandler = new Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(android.os.Message msg) {
            switch (msg.what) {
                case HIDE_TOP_BAR:
                    setTopBarInvisible();
                    break;
                case HIDE_FOOT_BAR:
                    mFootBar.setVisibility(View.INVISIBLE);
                    break;
                default:
                    break;
            }
        }
    };

    public MediaController(Context context, boolean isAudio, String retryText, String failedText) {
        mContext = context;
        mShowTimeOutMs = BAR_DELAY_HIDE;
        mFormatBuilder = new StringBuilder();
        mFormatter = new Formatter(mFormatBuilder, Locale.getDefault());
        mRetryText = retryText;
        mFailedText = failedText;
        initView(context, isAudio);
        setListeners();
    }

    private void initView(Context context, boolean isAudio) {
        initNoDoubleClickListener();
        mFootBar = isAudio ? (LinearLayout) LayoutInflater.from(context).inflate(R.layout.audio_foot_bar, null) :
                (LinearLayout) LayoutInflater.from(context).inflate(R.layout.video_foot_bar, null);

        mPlayProgressSeekBar = mFootBar.findViewById(R.id.media_controller);
        mPlayImageView = mFootBar.findViewById(R.id.iv_play);
        mCurrentTime = mFootBar.findViewById(R.id.current_time_textView);
        mTotalTime = mFootBar.findViewById(R.id.end_time_textView);
        mRotationImageView = mFootBar.findViewById(R.id.rotate_imageView);
        if (mRotationImageView != null) {
            mRotationImageView.setOnClickListener(mClickListener);
            mRotationImageView.addOnLayoutChangeListener((v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom) -> {
                int orientation = context.getResources().getConfiguration().orientation;
                Log.d(TAG, "onLayoutChange orientation" + orientation);
                if (orientation == ORIENTATION_PORTRAIT) {
                    updateRotationState(false);
                } else {
                    updateRotationState(true);
                }
            });
        }
    }

    public void setHideBar(boolean isHideBar) {
        mIsHideBar = isHideBar;
    }

    public void hideRotateBtn() {
        if (mRotationImageView != null) {
            mRotationImageView.setVisibility(View.GONE);
        }
    }

    private void setListeners() {
        mFootBar.setOnTouchListener(new ResetDelayHideBarTouchListener());
        mPlayProgressSeekBar.setOnSeekBarChangeListener(new ProgressChangeListener());
        mPlayImageView.setOnClickListener(mClickListener);
    }

    private void initNoDoubleClickListener() {
        mClickListener = v -> {
            int id = v.getId();
            if (id == R.id.iv_play) {
                doPauseResume();
            } else if (id == R.id.rotate_imageView) {
                onHandleScreenOrientation();
            }
        };
    }

    private void onHandleScreenOrientation() {
        if (mIMediaPlayerOption != null) {
            mIMediaPlayerOption.onScreenOrientation(!mIsLandscape);
        }
    }

    private void doPauseResume() {
        if (mIMediaPlayerOption != null) {
            mIMediaPlayerOption.doPauseResume();
        }
    }

    private void updateProgress(boolean fromUser, int msec) {
        if (mIMediaPlayerOption != null) {
            mIMediaPlayerOption.updateProgress(fromUser, msec);
        }
    }

    private class ProgressChangeListener implements SeekBar.OnSeekBarChangeListener {

        private int progressFromUser;

        @Override
        public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
            if (!fromUser) {
                return;
            }
            resetDelayHideTopBar();
            resetDelayHideFootBar();
            progressFromUser = progress;
            mCurrentTime.setText(stringForTime(progress));
            updateProgress(fromUser, progress);
        }

        @Override
        public void onStartTrackingTouch(SeekBar seekBar) {
            mIsTrackingTouch = true;
        }

        @Override
        public void onStopTrackingTouch(SeekBar seekBar) {
            mIsTrackingTouch = false;
            Log.d(TAG, " seekTo: " + progressFromUser);
            if (mIMediaPlayerOption != null) {
                mIMediaPlayerOption.seekTo(true, progressFromUser);
            }
            resetDelayHideFootBar();
        }
    }

    private class ResetDelayHideBarTouchListener implements View.OnTouchListener {
        @Override
        public boolean onTouch(View v, MotionEvent event) {
            resetDelayHideTopBar();
            resetDelayHideFootBar();
            return true;
        }
    }

    private void resetDelayHideTopBar() {
        mHandler.removeMessages(HIDE_TOP_BAR);
        if (!mIsPlaying || !mIsHideBar) {
            return;
        }
        mHandler.sendEmptyMessageDelayed(HIDE_TOP_BAR, mShowTimeOutMs);
    }

    private void resetDelayHideFootBar() {
        mHandler.removeMessages(HIDE_FOOT_BAR);
        if (!mIsPlaying || !mIsHideBar) {
            return;
        }
        mHandler.sendEmptyMessageDelayed(HIDE_FOOT_BAR, mShowTimeOutMs);
    }

    public void setMediaPlayerControl(IMediaPlayerOption mediaPlayerOption) {
        mIMediaPlayerOption = mediaPlayerOption;
    }

    public View getFootBar() {
        return mFootBar;
    }

    public int getShowTimeoutMs() {
        return mShowTimeOutMs;
    }


    public void setShowTimeoutMs(int showTimeoutMs) {
        mShowTimeOutMs = showTimeoutMs;
    }

    public void revertTopBarVisibility() {
        if (!mIsHideBar) {
            return;
        }
        if (mFootBar.getVisibility() == View.INVISIBLE) {
            showTopBarVisibility();
        } else {
            setTopBarInvisible();
        }
    }

    private void setTopBarInvisible() {
        if (mIMediaPlayerOption != null) {
            mIMediaPlayerOption.onTopBarVisibility(false);
        }
    }

    private void setTopBarVisible() {
        if (mIMediaPlayerOption != null) {
            mIMediaPlayerOption.onTopBarVisibility(true);
        }
    }

    public void showTopBarVisibility() {
        setTopBarVisible();
        resetDelayHideTopBar();
    }

    public void revertFootBarVisibility() {
        if (!mIsHideBar) {
            return;
        }
        if (mFootBar.getVisibility() == View.INVISIBLE) {
            showFootBarVisibility();
        } else {
            mFootBar.setVisibility(View.INVISIBLE);
        }
    }

    public void showFootBarVisibility() {
        mFootBar.setVisibility(View.VISIBLE);
        resetDelayHideFootBar();
    }

    public void updatePlayState(boolean isPlaying) {
        mIsPlaying = isPlaying;
        if (isPlaying) {
            mPlayImageView.setImageResource(R.drawable.ic_media_pause);
        } else {
            mPlayImageView.setImageResource(R.drawable.ic_media_play);
        }
        setTopBarVisible();
        resetDelayHideTopBar();
        mFootBar.setVisibility(View.VISIBLE);
        resetDelayHideFootBar();
    }

    private void updateRotationState(boolean isLandscape) {
        if (mRotationImageView == null) {
            return;
        }
        mIsLandscape = isLandscape;
        if (isLandscape) {
            mRotationImageView.setImageResource(R.drawable.ic_exit_full_screen);
        } else {
            mRotationImageView.setImageResource(R.drawable.ic_full_screen);
        }
    }

    public void updateProgress(int progress) {
        if (mIsTrackingTouch) {
            Log.d(TAG, "updateProgress return");
            return;
        }
        mPlayProgressSeekBar.setProgress(progress);
    }

    public int getTotalDuration() {
        return mPlayProgressSeekBar.getMax();
    }

    public int getCurrentDuration() {
        return mPlayProgressSeekBar.getProgress();
    }

    public void updateSecondaryProgress(int secondaryProgress) {
        mPlayProgressSeekBar.setSecondaryProgress(secondaryProgress);
    }

    public void updateCurrentTime(String currentTime) {
        if (mIsTrackingTouch) {
            Log.d(TAG, "updateCurrentTime return");
            return;
        }
        mCurrentTime.setText(currentTime);
    }

    public void updateDuration(String duration) {
        mTotalTime.setText(duration);
    }

    public void setProgressMax(int max) {
        mPlayProgressSeekBar.setMax(max);
    }

    public void release() {
        mHandler.removeCallbacksAndMessages(null);
    }

    public void setEnable(boolean enable) {
        mPlayProgressSeekBar.setEnabled(enable);
        mPlayImageView.setEnabled(enable);
        if (mRotationImageView != null) {
            mRotationImageView.setEnabled(enable);
        }
    }

    public View getErrorView() {
        if (mErrorView == null) {
            mErrorView = new LiveErrorView(mContext, mRetryText, mFailedText);
            mErrorView.setBackgroundColor(Color.BLACK);
        }
        return mErrorView;
    }

    private String stringForTime(int timeMs) {
        int totalSeconds = timeMs / 1000;
        int seconds = totalSeconds % 60;
        int minutes = (totalSeconds / 60) % 60;
        int hours = (totalSeconds / 3600) % 60;
        mFormatBuilder.setLength(0);
        return mFormatter.format("%02d:%02d", minutes + hours * 60, seconds).toString();
    }

}
