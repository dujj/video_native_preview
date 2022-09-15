package com.seewo.flutter.video_native_preview;

public interface IMediaPlayerOption {
    void doPauseResume();
    void seekTo(boolean fromUser, int msec);
    void updateProgress(boolean fromUser, int msec);
    void onScreenOrientation(boolean landscape);
    void onTopBarVisibility(boolean visible);
}
