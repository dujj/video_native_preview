//
//  AudioNativePreview.swift
//  video_native_preview
//
//  Created by dujianjie on 2022/9/14.
//
import QMUIKit
import Foundation

class AudioNativePreview : NativePreview {
    
    
    
    var initialUrl: String
    var failedText: String = "failed"
    var retryText: String = "retry"
    
    public init(frame: CGRect, url: String, failedText: String, retryText: String) {
        self.initialUrl = url
        self.failedText = failedText
        self.retryText = retryText
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var headerImageView = UIImageView(image: UIImage(named: "im_header_cover_mask"))
    
    fileprivate lazy var failedView: UIView = UIView()
    
    fileprivate lazy var failedImageView: UIImageView = {
        UIImageView(image: UIImage(named: "Im_file_load_failed"))
    }()
    
    private lazy var failedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor(white: 1, alpha: 0.2)
        label.textAlignment = .center
        label.text = self.failedText
        return label
    }()
    
    fileprivate var retryCount = 0
    
    fileprivate lazy var manager: PKVideoPreviewManager = {
        let mananger = PKVideoPreviewManager()
        mananger.autoPlayViaWlan = true
        return mananger
    }()
    
    fileprivate lazy var audioMaskView: UIView = UIView()
    fileprivate lazy var backgroundImageView: UIImageView = {
        UIImageView(image: UIImage(named: "ic_audio_show_cover"))
    }()
    
    private lazy var loadingView = PKLogoLoadingView()
    
    fileprivate lazy var videoView: UIView = UIView()
    
    fileprivate lazy var controlView: PKMediaControlView = PKMediaControlView()
    
    fileprivate lazy var centerPlayBackgroundView: UIView = UIView()
    fileprivate lazy var headerTimeLabel: UILabel = UILabel()
    fileprivate lazy var centerPlayButton: QMUIButton = QMUIButton(type: .custom)
    
    fileprivate var isBeforePlaying = false
    
    deinit {
        self.manager.stopPlayer()
    }
    
    func commonInit() {
        self.retryCount = 0
        NotificationCenter.default.addObserver(self, selector: #selector(self.statusBarOrientationDidChanged(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        
        self.initSubviews()
    }
    
    func initSubviews() {
        
        self.backgroundColor = .black
        
        
        self.manager.playWhenResumed = true
        self.manager.delegate = self
        
        self.initBackgroundImageView()
        
        self.loadingView.isHidden = true
        self.addSubview(self.loadingView)
        
        self.initializeControlView()
        
        self.initFailedView()
        self.initHeaderView()
        
        self.setupVideoPlayer()
        
        self.manager.resumePlayer()
        
    }
    
    public override func viewWillAppear() {
        // 如果之前是播放状态，继续播放,否则不处理
        if self.isBeforePlaying {
            self.isBeforePlaying = false
            self.manager.play()
        }
    }
    
    public override func viewDidDisappear() {
        self.isBeforePlaying = self.manager.isPlaying
        self.pauseVideo()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = self.bounds.width
        let height = self.bounds.height
        let bottomMargin = QMUIHelper.safeAreaInsetsForDeviceWithNotch.bottom
        self.videoView.frame = self.bounds
        
        self.audioMaskView.frame = self.bounds
        self.backgroundImageView.frame = CGRect(x: width*0.5-60, y: (height-60)*0.33, width: 120, height: 120)
        
        self.loadingView.frame = self.bounds
        
        self.controlView.frame = CGRect(x: 0, y: height-150-bottomMargin, width: width, height: 150)
        
        self.headerImageView.frame = CGRect(x: 0, y: 0, width: width, height: width > height ? 60 : 160)
        self.headerTimeLabel.frame = CGRect(x: 0, y: 160-18-42, width: width, height: 48)
        
        self.failedView.frame = self.bounds
        self.failedImageView.frame = CGRect(x: self.failedView.bounds.width*0.5-44, y: self.failedView.bounds.height*0.5-62-40, width: 88, height: 88)
        self.failedLabel.frame = CGRect(x: 0, y: self.failedImageView.frame.maxY+12, width: self.failedView.bounds.width, height: 24)
        
        self.centerPlayBackgroundView.frame = self.bounds
        self.centerPlayButton.frame = CGRect(x: width*0.5-36, y: height*0.5-36, width: 72, height: 72)
    }
    
    fileprivate func initFailedView() {
        self.failedView.backgroundColor = UIColor.black
        self.failedView.isHidden = true
        self.addSubview(self.failedView)
        
        self.failedView.addSubview(self.failedImageView)
        self.failedView.addSubview(self.failedLabel)
        
    }
    
    fileprivate func initHeaderView() {
        self.headerTimeLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        self.headerTimeLabel.backgroundColor = .clear
        self.headerTimeLabel.textColor = .white
        self.headerTimeLabel.textAlignment = .center
        self.headerTimeLabel.isHidden = true
        self.headerImageView.addSubview(self.headerTimeLabel)
        
        self.addSubview(self.headerImageView)
    }
    
    fileprivate func initBackgroundImageView() {
        
        self.audioMaskView.backgroundColor = UIColor.black
        
        self.audioMaskView.addSubview(self.backgroundImageView)
        
        self.addSubview(self.audioMaskView)
    }
    
    fileprivate func initializeControlView() {
        self.controlView.showOriginButton = false
        self.controlView.isUserInteractionEnabled = false
        
        self.controlView.playHandler = { [weak weakSelf = self] in
            weakSelf?.manager.checkBeforePlay()
        }
        
        self.controlView.pauseHandler = { [weak weakSelf = self] in
            weakSelf?.pauseVideo()
        }
        
        self.controlView.slideChangedHandler = { [weak weakSelf = self] (value, event) in
            guard let strongSelf = weakSelf else { return }
            switch event {
            case .touchDown:
                strongSelf.manager.beginSeekTime()
                strongSelf.headerTimeLabel.isHidden = false
            case .touchCancel, .touchUpOutside, .touchUpInside:
                if !strongSelf.centerPlayBackgroundView.isHidden {
                    strongSelf.centerPlayBackgroundView.isHidden = true
                    strongSelf.manager.checkBeforePlay()
                }
                strongSelf.manager.seek(to: Double(value), shouldUpdatePlayer: true)
                strongSelf.manager.endSeekTime()
                strongSelf.headerTimeLabel.isHidden = true
            case .valueChanged:
                let postion = value + 0.5
                let currentTimeString = String(format: "%02d:%02d", Int(postion) / 60, Int(postion) % 60)
                strongSelf.manager.seek(to: Double(value), shouldUpdatePlayer: false)
                strongSelf.headerTimeLabel.text = currentTimeString
                strongSelf.controlView.updateTime(currentTimeString)
            default:
                break
            }
        }
        
        self.controlView.landscapeHandler = { [weak weakSelf = self] in
            weakSelf?.delegate?.rotate("landscape")
        }
        
        self.controlView.portraitHandler = { [weak weakSelf = self] in
            weakSelf?.delegate?.rotate("portrait")
        }
        
        self.addSubview(self.controlView)
        self.headerTimeLabel.text = "00:00"
        self.controlView.updateTime(current: "00:00", total: "00:00")
    }
    
    fileprivate func initializeCenterPlayButton() {
        self.centerPlayBackgroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.addSubview(self.centerPlayBackgroundView)
        
        self.centerPlayButton.adjustsImageWhenHighlighted = false
        self.centerPlayButton.setImage(UIImage(named: "ic_video_paly_cover_normal"), for: .normal)
        self.centerPlayButton.addTarget(self, action: #selector(self.playButtonDidTapped(_:)), for: .touchUpInside)
        self.centerPlayBackgroundView.addSubview(self.centerPlayButton)
        self.centerPlayBackgroundView.isHidden = true
        
    }
    
    fileprivate func setupVideoPlayer() {
        if let url = URL(string: self.initialUrl) {
            self.manager.videoUrl = url
            self.manager.setupPlayerForLiveConcatVideo()
        } else {
            self.failedView.isHidden = false
        }
    }
    
    fileprivate func showLoadingView() {
        if self.centerPlayBackgroundView.isHidden {
            self.loadingView.startAnimating()
        }
    }
    
    fileprivate func hideLoadingView() {
        self.loadingView.stopAnimating()
    }
    
    fileprivate func showRetryView() {
        self.centerPlayBackgroundView.isHidden = true
        self.hideLoadingView()
        self.failedView.isHidden = false
    }
    
    fileprivate func hideRetryView() {
        self.failedView.isHidden = true
        self.showLoadingView()
    }
    
    fileprivate func playVideoByUser(byUser: Bool) {
        self.centerPlayBackgroundView.isHidden = true
        self.controlView.showPauseButton()
        if byUser {
            self.manager.play()
        }
    }
    
    fileprivate func pauseVideo() {
        self.centerPlayBackgroundView.isHidden = false
        self.hideLoadingView()
        self.controlView.showPlayButton()
        self.manager.pause()
    }
    
    @objc private func playButtonDidTapped(_ sender: UIButton) {
        self.manager.checkBeforePlay()
    }
    
    @objc private func statusBarOrientationDidChanged(_ notification: Notification) {
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape {
            self.controlView.showPortraitButton()
        } else if orientation.isPortrait {
            self.controlView.showLandscapeButton()
        }
    }
}

extension AudioNativePreview: PKVideoPreviewManagerDelegate {
    func configVideoView(videoView: UIView?) {
        if let mVideoView = videoView {
            if self.videoView.superview != nil {
                self.videoView.removeFromSuperview()
            }
            self.videoView = mVideoView
            self.videoView.frame = self.bounds
            self.insertSubview(self.videoView, at: 0)
        }
    }
    
    func didPreparePlay() {
        if !self.manager.playWhenResumed {
            return
        }
        self.hideLoadingView()
        self.controlView.isUserInteractionEnabled = true
    }
    
    func didPlaying() {
        
        self.controlView.isUserInteractionEnabled = true
        
        self.hideRetryView()
        self.hideLoadingView()
        self.playVideoByUser(byUser: false)
    }
    
    func didBuffering() {
        self.controlView.isUserInteractionEnabled = false
        self.showLoadingView()
    }
    
    func didFinishPlay() {
        self.centerPlayBackgroundView.isHidden = false
        self.controlView.showPlayButton()
        self.controlView.progressSlider.value = self.controlView.progressSlider.maximumValue
    }
    
    func didPlayInterrupt(event: PKVideoPreviewManager.InterruptType) {
      
        
        if event == .noNetwork {
            self.pauseVideo()
            self.showRetryView()
        } else if event == .loseWifi {
            if !self.manager.autoPlayViaWlan {
                self.pauseVideo()
            }
        } else if event == .hasWifi {
            self.playVideoByUser(byUser: true)
        }
    }
    
    func didPlayError(_ error: Any?) {
        if !self.failedView.isHidden {
            return
        }
        if self.retryCount < 3 {
            debugPrint("didPlayError retry count less than 3.")
            self.manager.stopPlayer()
            self.manager.setupPlayerForLiveConcatVideo()
            self.manager.resumePlayer()
            self.retryCount += 1
        } else {
            debugPrint("didPlayError retry count exceed 3.")
            self.retryCount = 0
            self.showRetryView()
        }
    }
    
    func shouldContinuousUpdateTime() -> Bool {
        true
    }
    
    func didUpdateTime(currentTime: TimeInterval, playableTime: TimeInterval, totalTime: TimeInterval) {
        if currentTime <= 0 {
            return
        }
        let postion = currentTime + 0.5
        let totalPosition = totalTime + 0.5
        let currentTimeString = String(format: "%02d:%02d", Int(postion) / 60, Int(postion) % 60)
        let totalTimeString = totalPosition > 0 ? String(format: "%02d:%02d", Int(totalPosition) / 60, Int(totalPosition) % 60) : "00:00"
        if currentTime == 0 {
            self.controlView.progressSlider.setValue(0, animated: false)
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
                self.controlView.progressSlider.maximumValue = totalPosition > 0 ? Float(totalTime) : 1
                self.controlView.progressSlider.setValue((postion > 0 ? Float(currentTime) : 0), animated: true)
            }, completion: nil)
            self.controlView.progressSlider.cacheValue = playableTime > 0 ? Float(playableTime + 0.5) : 0
        }
        self.headerTimeLabel.text = currentTimeString
        self.controlView.updateTime(current: currentTimeString, total: totalTimeString)
    }
    
    func didUpdateDegree(degree: PKVideoPreviewManager.Degree) {
        if self.manager.playWhenResumed {
            return
        }
        if degree == .piDivideTwo {
            self.videoView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
        } else if degree == .onePi {
            self.videoView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        } else if degree == .onePointFivePi {
            self.videoView.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi/2))
        }
        self.manager.playWhenResumed = true
    }
}
