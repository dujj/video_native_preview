package com.seewo.flutter.video_native_preview

import android.content.Context
import android.graphics.drawable.Drawable
import android.util.AttributeSet
import androidx.appcompat.widget.AppCompatImageView

class ClickEffectImageView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : AppCompatImageView(context, attrs, defStyleAttr) {

    override fun setBackgroundDrawable(background: Drawable?) {
        if (background != null) {
            super.setBackgroundDrawable(ClickEffectBackgroundDrawable(background))
        } else {
            super.setBackgroundDrawable(background)
        }
    }

    override fun setImageDrawable(drawable: Drawable?) {
        if (drawable != null) {
            super.setImageDrawable(ClickEffectBackgroundDrawable(drawable))
        } else {
            super.setImageDrawable(drawable)
        }
    }
}