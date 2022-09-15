package com.seewo.flutter.video_native_preview

import android.content.Context
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat

class LiveErrorView(context: Context, var retryText: String, var failedText: String) :
    LinearLayout(context) {
    companion object {
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

    interface LiveErrorViewListener {
        fun onLiveRetry()
    }

    var listener: LiveErrorViewListener? = null

    init {
        layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        orientation = VERTICAL
        gravity = Gravity.CENTER
        addTipsView(context)
        addRetryView(context)
    }

    private fun addRetryView(context: Context) {
        var textView = TextView(context)
        textView.text = retryText
        textView.layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
        textView.setTextSize(
            TypedValue.COMPLEX_UNIT_PX,
            context.resources.getDimensionPixelSize(R.dimen.size_12).toFloat()
        )
        textView.setTextColor(ContextCompat.getColor(context, R.color.color_FFA200))
        textView.background = ContextCompat.getDrawable(context, R.drawable.bg_retry_shape)
        textView.setPadding(
            dipToPixel(context, 24),
            dipToPixel(context, 4),
            dipToPixel(context, 24),
            dipToPixel(context, 4)
        )
        textView.setOnClickListener { listener?.onLiveRetry() }
        addView(textView)
    }

    private fun addTipsView(context: Context) {
        var textView = TextView(context)
        textView.text = failedText
        textView.layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
        textView.setPadding(
            dipToPixel(context, 0),
            dipToPixel(context, 0),
            dipToPixel(context, 0),
            dipToPixel(context, 12)
        )
        textView.setTextSize(
            TypedValue.COMPLEX_UNIT_PX,
            context.resources.getDimensionPixelSize(R.dimen.size_14).toFloat()
        )
        textView.setTextColor(ContextCompat.getColor(context, R.color.white_alpha_60))
        addView(textView)
    }

}