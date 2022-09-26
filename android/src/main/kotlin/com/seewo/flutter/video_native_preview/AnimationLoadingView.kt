package com.seewo.flutter.video_native_preview

import android.content.Context
import android.graphics.Canvas
import android.graphics.drawable.AnimationDrawable
import android.util.AttributeSet
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.appcompat.widget.AppCompatImageView
import com.tencent.mars.xlog.Log

class AnimationLoadingView : AppCompatImageView {
    private var isShowing = false

    constructor(context: Context, attrs: AttributeSet? = null) : super(context, attrs)
    constructor(context: Context, resId: Int) : super(context) {
        setBackgroundResource(resId)
    }

    override fun onDraw(canvas: Canvas?) {
        try {
            super.onDraw(canvas)
        } catch (e: Exception) {
            Log.e("AnimationLoadingView", "onDraw error: ${e.message}")
        }
    }

    fun show(parent: FrameLayout, width: Int) {
        var lps = FrameLayout.LayoutParams(width, width)
        lps.gravity = Gravity.CENTER
        layoutParams = lps
        removeFromParent()
        parent.addView(this)
        var animationDrawable = background as AnimationDrawable?
        animationDrawable?.start()
        isShowing = true
    }

    fun show(parent: FrameLayout) {
        val size = dipToPixel(context, 48)
        show(parent, size)
    }

    fun dismiss() {
        var animationDrawable = background as AnimationDrawable?
        animationDrawable?.stop()
        removeFromParent()
        isShowing = false
    }

    fun isShowing(): Boolean {
        return isShowing
    }

    private fun removeFromParent() {
        var parent: ViewGroup? = parent as ViewGroup?
        parent?.removeView(this)
    }

    //把px转换成dp
    private fun dipToPixel(context: Context, dip: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dip.toFloat(),
            context.resources.displayMetrics
        )
            .toInt()
    }

}