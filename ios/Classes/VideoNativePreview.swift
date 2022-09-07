//
//  VideoNativePreview.swift
//  video_native_preview
//
//  Created by dujianjie on 2022/9/7.
//

import Foundation

public class VideoNativePreview: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.red
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
