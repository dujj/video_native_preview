package com.seewo.flutter.video_native_preview

import android.content.Context
import android.util.TypedValue
import android.view.Gravity
import android.widget.ImageView
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
        addErrorImageView(context)
        addTipsView(context)
        addRetryView(context)
    }

    private fun addErrorImageView(context: Context){
        val imageView = ImageView(context)
        imageView.layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT,LayoutParams.WRAP_CONTENT)
        imageView.setImageResource(R.drawable.ic_error_black)
        addView(imageView)
    }

    private fun addRetryView(context: Context) {
        var textView = TextView(context)
        textView.text = retryText
        val layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
        layoutParams.topMargin = dipToPixel(context, 16)
        textView.layoutParams = layoutParams
        textView.gravity = Gravity.CENTER
        textView.minWidth = dipToPixel(context, 160)
        textView.minHeight = dipToPixel(context, 52)
        textView.setTextSize(
            TypedValue.COMPLEX_UNIT_PX,
            context.resources.getDimensionPixelSize(R.dimen.size_16).toFloat()
        )
        textView.setTextColor(ContextCompat.getColor(context, R.color.white))
        textView.background = ContextCompat.getDrawable(context, R.drawable.bg_retry_shape)
        textView.setOnClickListener { listener?.onLiveRetry() }
        addView(textView)
    }

    private fun addTipsView(context: Context) {
        var textView = TextView(context)
        textView.text = failedText
        val layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
        layoutParams.topMargin = dipToPixel(context, 24)
        textView.layoutParams = layoutParams
        textView.setTextSize(
            TypedValue.COMPLEX_UNIT_PX,
            context.resources.getDimensionPixelSize(R.dimen.size_16).toFloat()
        )
        textView.setTextColor(ContextCompat.getColor(context, R.color.white_alpha_80))
        addView(textView)
    }

}