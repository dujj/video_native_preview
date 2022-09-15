package com.seewo.flutter.video_native_preview

import android.graphics.Color
import android.graphics.LightingColorFilter
import android.graphics.drawable.Drawable
import android.graphics.drawable.LayerDrawable

open class ClickEffectBackgroundDrawable(d: Drawable) : LayerDrawable(arrayOf(d)) {

    protected var mPressedFilter = LightingColorFilter(Color.LTGRAY, 1)

    protected var mPressedAlpha = 126
    protected var mDisabledAlpha = 85
    protected var mFullAlpha = 255
    override fun onStateChange(states: IntArray): Boolean {
        var enabled = false
        var pressed = false
        for (state in states) {
            if (state == android.R.attr.state_enabled) {
                enabled = true
            } else if (state == android.R.attr.state_pressed) {
                pressed = true
            }
        }
        mutate()
        if (enabled && pressed) {
            colorFilter = mPressedFilter
            alpha = mPressedAlpha
        } else if (!enabled) {
            colorFilter = null
            alpha = mDisabledAlpha
        } else {
            colorFilter = null
            alpha = mFullAlpha
        }
        return super.onStateChange(state)
    }

    override fun isStateful(): Boolean {
        return true
    }
}