//
//  VideoNativePreview.swift
//  video_native_preview
//
//  Created by dujianjie on 2022/9/7.
//
import QMUIKit
import Foundation
import Alamofire
import IJKMediaFrameworkWithSSL

class PKBaseView: UIView {
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.setup()
    }
    
    func setup() {
        
    }
    
}

class PKLogoLoadingView : PKBaseView {

    private static let imageSize: CGFloat = 48
    
    private lazy var imageView = UIImageView()

    private(set) var isAnimating: Bool = false
    var hidesWhenStopped: Bool = true {
        didSet {
            if self.hidesWhenStopped == oldValue {
                return
            }
            if !self.isAnimating {
                self.isHidden = self.hidesWhenStopped
            }
        }
    }

    override func setup() {
        
        super.setup()
        self.backgroundColor = .clear
        self.isHidden = true
        let images = (21...53).map { index in UIImage(named: "liveshow_logo_loading_\(index)")! }
        self.imageView.animationImages = images
        self.addSubview(self.imageView)
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        self.imageView.frame = CGRect(x: (self.bounds.width - Self.imageSize) / 2.0, y: (self.bounds.height - Self.imageSize) / 2.0, width: Self.imageSize, height: Self.imageSize)
    }
    
    func startAnimating() {
        
        guard !self.isAnimating else { return }
        self.isAnimating = true
        if self.hidesWhenStopped {
            self.isHidden = false
        }
        self.imageView.startAnimating()
    }

    func stopAnimating() {
        
        guard self.isAnimating else { return }
        self.isAnimating = false
        if self.hidesWhenStopped {
            self.isHidden = true
        }
        self.imageView.stopAnimating()
    }
}

class PKSlider: UISlider {
    var cacheValue: Float = 0
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var result = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        result.origin.y = bounds.height*0.5 - self.qmui_thumbSize.height*0.5
        result.size.height = self.qmui_thumbSize.height
        return result
    }
}

class PKMediaControlView: UIView {
    
    fileprivate(set) lazy var progressSlider: PKSlider = PKSlider()
    
    var playHandler: (() -> Void)? = nil
    var pauseHandler: (() -> Void)? = nil
    
    var slideChangedHandler: ((Float, UIControl.Event) -> Void)? = nil
    
    var landscapeHandler: (() -> Void)? = nil
    var portraitHandler: (() -> Void)? = nil
    
    fileprivate lazy var playButton = QMUIButton()
    fileprivate lazy var pauseButton = QMUIButton()
    
    fileprivate lazy var currentTimeLabel: UILabel = UILabel()
    fileprivate lazy var totalTimeLabel: UILabel = UILabel()
    
    fileprivate lazy var landscapeButton = QMUIButton()
    fileprivate lazy var portraitButton = QMUIButton()
    
    fileprivate lazy var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        
        self.addSubview(self.playButton)
        self.playButton.setImage(UIImage(named: "ic_vido_play_normal"), for: .normal)
        self.playButton.addTarget(self, action: #selector(self.playButtonDidTapped(_:)), for: .touchUpInside)
        
        self.addSubview(self.pauseButton)
        self.pauseButton.setImage(UIImage(named: "ic_vido_suspend_normal"), for: .normal)
        self.pauseButton.addTarget(self, action: #selector(self.pauseButtonDidTapped(_:)), for: .touchUpInside)
        self.pauseButton.isHidden = true
        
        self.addSubview(self.landscapeButton)
        self.landscapeButton.setImage(UIImage(named: "ic_vido_spin_normal"), for: .normal)
        self.landscapeButton.addTarget(self, action: #selector(self.landscapeButtonDidTapped(_:)), for: .touchUpInside)
        
        self.addSubview(self.portraitButton)
        self.portraitButton.setImage(UIImage(named: "ic_vido_spin_normal"), for: .normal)
        self.portraitButton.addTarget(self, action: #selector(self.portraitButtonDidTapped(_:)), for: .touchUpInside)
        self.portraitButton.isHidden = true
        
        self.addSubview(self.currentTimeLabel)
        self.currentTimeLabel.backgroundColor = UIColor.clear
        self.currentTimeLabel.textAlignment = .left
        self.currentTimeLabel.textColor = UIColor(white: 1, alpha: 0.8)
        self.currentTimeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.currentTimeLabel.text = "00:00"
        
        self.addSubview(self.totalTimeLabel)
        self.totalTimeLabel.backgroundColor = UIColor.clear
        self.totalTimeLabel.textAlignment = .right
        self.totalTimeLabel.textColor = UIColor(white: 1, alpha: 0.8)
        self.totalTimeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.totalTimeLabel.text = "00:00"
        
        self.addSubview(self.progressSlider)
        self.progressSlider.minimumTrackTintColor = UIColor.white
        self.progressSlider.maximumTrackTintColor = UIColor(white: 1, alpha: 0.4)
        self.progressSlider.qmui_thumbColor = UIColor.white
        self.progressSlider.qmui_thumbSize = CGSize(width: 12, height: 12)
        self.progressSlider.qmui_trackHeight = 2
        self.progressSlider.addTarget(self, action: #selector(self.progressDidTouchDown(_:)), for: .touchDown)
        self.progressSlider.addTarget(self, action: #selector(self.progressDidTouchCancel(_:)), for: .touchCancel)
        self.progressSlider.addTarget(self, action: #selector(self.progressDidTouchUpInside(_:)), for: .touchUpInside)
        self.progressSlider.addTarget(self, action: #selector(self.progressDidTouchUpOutside(_:)), for: .touchUpOutside)
        self.progressSlider.addTarget(self, action: #selector(self.progressDidChanged(_:)), for: .valueChanged)
        
        self.tapGesture.addTarget(self, action: #selector(self.sliderTapGesture(_:)))
        self.progressSlider.addGestureRecognizer(self.tapGesture)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = self.bounds.width
        let height = self.bounds.height
        if self.showOriginButton {
            self.playButton.frame = CGRect(x: 6, y: 10, width: 44, height: 44)
            self.pauseButton.frame = CGRect(x: 6, y: 10, width: 44, height: 44)
            self.currentTimeLabel.frame = CGRect(x: 52, y: height*0.5-10, width: 40, height: 20)
            self.portraitButton.frame = CGRect(x: width-50, y: 10, width: 44, height: 44)
            self.landscapeButton.frame = CGRect(x: width-50, y: 10, width: 44, height: 44)
            self.totalTimeLabel.frame = CGRect(x: width-52-40, y: height*0.5-10, width: 40, height: 20)
            self.progressSlider.frame = CGRect(x: 96, y: height*0.5-10, width: width-96-96, height: 20)
        } else {
            self.playButton.frame = CGRect(x: width*0.5-30, y: height-100, width: 60, height: 60)
            self.pauseButton.frame = CGRect(x: width*0.5-30, y: height-100, width: 60, height: 60)
            self.currentTimeLabel.frame = CGRect(x: 24, y: 2, width: 40, height: 20)
            self.portraitButton.frame = CGRect(x: width, y: 0, width: 0, height: 0)
            self.landscapeButton.frame = CGRect(x: width, y: 0, width: 0, height: 0)
            self.totalTimeLabel.frame = CGRect(x: width-24-40, y: 2, width: 40, height: 20)
            self.progressSlider.frame = CGRect(x: 72, y: 2, width: width-72-72, height: 20)
        }
    }

    func showPlayButton() {
        self.playButton.isHidden = false
        self.pauseButton.isHidden = true
    }
    
    func showPauseButton() {
        self.playButton.isHidden = true
        self.pauseButton.isHidden = false
    }
    
    func showLandscapeButton() {
        self.landscapeButton.isHidden = false
        self.portraitButton.isHidden = true
    }
    
    func showPortraitButton() {
        self.landscapeButton.isHidden = true
        self.portraitButton.isHidden = false
    }
    
    func updateTime(current: String, total: String) {
        self.currentTimeLabel.text = current.isEmpty ? "00:00" : current
        self.totalTimeLabel.text = total.isEmpty ? "00:00" : total
    }
    
    func updateTime(_ current: String) {
        self.currentTimeLabel.text = current.isEmpty ? "00:00" : current
    }

    @objc private func playButtonDidTapped(_ sender: UIButton) {
        self.playHandler?()
    }
    
    @objc private func pauseButtonDidTapped(_ sender: UIButton) {
        self.pauseHandler?()
    }
    
    @objc private func landscapeButtonDidTapped(_ sender: UIButton) {
        self.showPortraitButton()
        self.landscapeHandler?()
    }
    
    @objc private func portraitButtonDidTapped(_ sender: UIButton) {
        self.showLandscapeButton()
        self.portraitHandler?()
    }

    @objc private func progressDidTouchDown(_ slider: PKSlider) {
        self.tapGesture.isEnabled = false
        self.slideChangedHandler?(slider.value, .touchDown)
    }
    
    @objc private func progressDidTouchCancel(_ slider: PKSlider) {
        self.tapGesture.isEnabled = true
        self.slideChangedHandler?(slider.value, .touchCancel)
    }
 
    @objc private func progressDidTouchUpInside(_ slider: PKSlider) {
        self.tapGesture.isEnabled = true
        self.slideChangedHandler?(slider.value, .touchUpInside)
    }
    
    @objc private func progressDidTouchUpOutside(_ slider: PKSlider) {
        self.tapGesture.isEnabled = true
        self.slideChangedHandler?(slider.value, .touchUpOutside)
    }
    
    @objc private func progressDidChanged(_ slider: PKSlider) {
        self.slideChangedHandler?(slider.value, .valueChanged)
    }
    
    @objc private func sliderTapGesture(_ gesture: UIGestureRecognizer) {
        let touchPoint = gesture.location(in: self.progressSlider)
        let scale = Float(touchPoint.x/self.progressSlider.frame.width)
        let value = (self.progressSlider.maximumValue-self.progressSlider.minimumValue)*scale
        self.progressSlider.setValue(value, animated: true)
        self.progressSlider.sendActions(for: .touchUpInside)
    }
    
    var showOriginButton = false {
        didSet {
            self.landscapeButton.alpha = self.showOriginButton ? 1 : 0
            self.portraitButton.alpha = self.showOriginButton ? 1 : 0
            if self.showOriginButton {
                self.playButton.clipsToBounds = false
                self.playButton.layer.cornerRadius = 0
                self.playButton.backgroundColor = UIColor.clear
                self.pauseButton.clipsToBounds = false
                self.pauseButton.layer.cornerRadius = 0
                self.pauseButton.backgroundColor = UIColor.clear
                self.playButton.setImage(UIImage(named: "ic_vido_play_normal"), for: .normal)
                self.pauseButton.setImage(UIImage(named: "ic_vido_suspend_normal"), for: .normal)
            } else {
                self.playButton.clipsToBounds = true
                self.playButton.layer.cornerRadius = 30
                self.playButton.backgroundColor = UIColor(white: 1, alpha: 0.08)
                self.pauseButton.clipsToBounds = true
                self.pauseButton.layer.cornerRadius = 30
                self.pauseButton.backgroundColor = UIColor(white: 1, alpha: 0.08)
                self.playButton.setImage(UIImage(named: "ic_vido_play_big_normal"), for: .normal)
                self.pauseButton.setImage(UIImage(named: "ic_vido_suspend_big_normal"), for: .normal)
            }
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
}

enum PlayerStatus: Equatable {
    case pasue(Bool)
    case playing(Bool)
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        if case .playing(let isLhsLoading) = lhs, case .playing(let isRhsLoading) = rhs, isLhsLoading == isRhsLoading {
            return true
        }
        if case .pasue(let isLhsError) = lhs, case .pasue(let isRhsError) = rhs, isLhsError == isRhsError {
            return true
        }
        return false
    }
}

class PKLiveVideoRetryView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private(set) lazy var imageView = UIImageView(image: UIImage(named: "empty_server_error_black"))
    private(set) lazy var retryLabel = UILabel()
    private(set) lazy var retryButton = QMUIButton(type: .custom)
    
    func commonInit() {
        
        self.backgroundColor = .clear
        self.addSubview(self.imageView)
        
        self.retryLabel.alpha = 0.6
        self.retryLabel.textAlignment = .center
        self.retryLabel.textColor = .white
        self.retryLabel.font = UIFont.systemFont(ofSize: 16)
        self.addSubview(self.retryLabel)
        
        
        self.retryButton.backgroundColor = UIColor(red: 0.0, green: 110.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        self.retryButton.setTitleColor(UIColor.white, for: .normal)
        self.retryButton.cornerRadius = 6
        self.retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        self.addSubview(self.retryButton)
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        let width = self.bounds.width
        let height = self.bounds.height
        var originY = 233 * CGFloat.maximum(UIScreen.main.bounds.width, UIScreen.main.bounds.height) / 667.0
        if width > height {
            originY = (height - (160.0 + 24.0 + 20.0 + 16.0 + 48.0)) * 0.5
        }
        
        self.imageView.frame = CGRect(x: (width - 160.0) * 0.5, y: originY, width: 160.0, height: 160.0)
        self.retryLabel.frame = CGRect(x: 16.0, y: self.imageView.frame.maxY + 24.0, width: width - 32.0, height: 20.0)
        self.retryButton.frame = CGRect(x: (width - 128.0) * 0.5, y: self.retryLabel.frame.maxY + 16.0, width: 128.0, height: 48.0)
    }
}

class PKLiveVideoPauseView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private(set) lazy var centerPlayButton: UIButton = UIButton(type: .custom)
    
    func commonInit() {
        
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        
        self.centerPlayButton.adjustsImageWhenHighlighted = false
        self.centerPlayButton.setImage(UIImage(named: "ic_video_paly_cover_normal"), for: .normal)
        self.addSubview(self.centerPlayButton)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = self.bounds.width
        let height = self.bounds.height
        
        self.centerPlayButton.frame = CGRect(x: width*0.5-36, y: height*0.5-36, width: 72, height: 72)
    }
}

class PKLiveVideoControlView: UIView {
    
    enum Event {
        case play
        case pause
        case landscape
        case portrait
        case seekBegain
        case seek(Double)
    }
    
    private var handlerEvent: ((Event) -> Void)
    init(_ handlerEvent: @escaping (Event) -> Void) {
        self.handlerEvent = handlerEvent
        super.init(frame: CGRect.zero)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var loadingView = PKLogoLoadingView()
    
    private lazy var pauseView = PKLiveVideoPauseView()
    
    private(set) lazy var retryView = PKLiveVideoRetryView()
    
    private lazy var headerImageView = UIImageView(image: UIImage(named: "im_header_cover_mask"))
    private lazy var headerTimeLabel: UILabel = UILabel()
    
    private lazy var controlView: PKMediaControlView = PKMediaControlView()
    
    func commonInit() {
        
        self.backgroundColor = .clear
        
        self.loadingView.isHidden = true
        self.addSubview(self.loadingView)
        
        self.pauseView.isHidden = true
        self.pauseView.centerPlayButton.qmui_tapBlock = { [weak weakSelf = self] (_) in
            weakSelf?.handlerEvent(.play)
        }
        self.addSubview(self.pauseView)
        
        self.retryView.isHidden = true
        self.retryView.retryButton.qmui_tapBlock = { [weak weakSelf = self] (_) in
            weakSelf?.handlerEvent(.play)
        }
        self.addSubview(self.retryView)
        
        
        self.headerTimeLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        self.headerTimeLabel.backgroundColor = .clear
        self.headerTimeLabel.textColor = .white
        self.headerTimeLabel.textAlignment = .center
        self.headerTimeLabel.isHidden = true
        self.headerImageView.addSubview(self.headerTimeLabel)
        
        self.addSubview(self.headerImageView)
        
        self.addSubview(self.controlView)
        
        self.controlView.playHandler = { [weak weakSelf = self] in
            weakSelf?.handlerEvent(.play)
        }

        self.controlView.pauseHandler = { [weak weakSelf = self] in
            weakSelf?.handlerEvent(.pause)
        }

        self.controlView.slideChangedHandler = { [weak weakSelf = self] (value, event) in
            guard let strongSelf = weakSelf else { return }
            let postion = value + 0.5
            let currentTimeString = String(format: "%02d:%02d", Int(postion) / 60, Int(postion) % 60)
            switch event {
            case .touchDown:
                strongSelf.headerTimeLabel.text = currentTimeString
                strongSelf.headerTimeLabel.isHidden = false
                strongSelf.handlerEvent(.seekBegain)
            case .touchCancel, .touchUpOutside, .touchUpInside:
                strongSelf.headerTimeLabel.isHidden = true
                strongSelf.handlerEvent(.seek(Double(Int(postion))))
            case .valueChanged:
                strongSelf.headerTimeLabel.text = currentTimeString
                strongSelf.controlView.updateTime(currentTimeString)
            default:
                break
            }
        }

        self.controlView.landscapeHandler = { [weak weakSelf = self] in
            weakSelf?.handlerEvent(.landscape)
        }

        self.controlView.portraitHandler = { [weak weakSelf = self] in
            weakSelf?.handlerEvent(.portrait)
        }
        
        self.controlView.showOriginButton = true
        self.controlView.isUserInteractionEnabled = false
        self.headerTimeLabel.text = "00:00"
        self.controlView.updateTime(current: "00:00", total: "00:00")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.statusBarOrientationDidChanged(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.loadingView.frame = self.bounds
        
        self.pauseView.frame = self.bounds
        
        self.retryView.frame = self.bounds
        
        let width = self.bounds.width
        let height = self.bounds.height
        
        self.headerImageView.frame = CGRect(x: 0, y: 0, width: width, height: width > height ? 60 : 160)
        self.headerTimeLabel.frame = CGRect(x: 0, y: 160-18-42, width: width, height: 48)
        
        let bottomMargin = QMUIHelper.safeAreaInsetsForDeviceWithNotch.bottom
        
        self.controlView.frame = CGRect(x: 0, y: height-64-bottomMargin, width: width, height: 64)
    }
    
    @objc private func statusBarOrientationDidChanged(_ notification: Notification) {
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape {
            self.controlView.showPortraitButton()
        } else if orientation.isPortrait {
            self.controlView.showLandscapeButton()
        }
    }
    
    var status: PlayerStatus = .pasue(false) {
        didSet {
            switch self.status {
            case .pasue(let isError):
                self.loadingView.stopAnimating()
                if isError {
                    self.retryView.isHidden = false
                    self.pauseView.isHidden = true
                } else {
                    self.retryView.isHidden = true
                    self.pauseView.isHidden = false
                }
                
                self.controlView.showPlayButton()
            case .playing(let isLoading):
                self.pauseView.isHidden = true
                self.retryView.isHidden = true
                self.controlView.showPauseButton()
                if isLoading {
                    self.loadingView.startAnimating()
                } else {
                    self.loadingView.stopAnimating()
                }
            
            }
        }
    }
    
    func prepareForControlView() {
        self.controlView.isUserInteractionEnabled = true
    }
    
    func refreshControl(_ player: IJKMediaPlayback?) {
        if self.controlView.isHidden {
            return
        }
        if self.isSlider {
            return
        }
        
        var duration: Double = player?.duration ?? 0
        var playableDuration: Double = player?.playableDuration ?? 0
        
        if playableDuration > 0, duration <= 0 {
            duration = playableDuration
        }
        
        let intDuration = Int(duration + 0.5)
        
        var totalText = "00:00"
        if intDuration > 0 {
            self.controlView.progressSlider.maximumValue = Float(duration)
            totalText = String(format: "%02d:%02d", intDuration / 60, intDuration % 60)
        } else {
            self.controlView.progressSlider.maximumValue = 1.0
        }
        
        
        if playableDuration > duration {
            playableDuration = duration
        }
        if intDuration > 0 {
            self.controlView.progressSlider.cacheValue = Float(playableDuration)
        } else {
            self.controlView.progressSlider.maximumValue = 0.0
        }
        
        var position: Double = 0
        if (self.isSlider) {
            position = Double(self.controlView.progressSlider.value)
        } else {
            position = player?.currentPlaybackTime ?? 0
        }
        if position > duration {
            position = duration
        }
        let intPosition = Int(position + 0.5)
        if intDuration > 0 {
            self.controlView.progressSlider.value = Float(position)
        } else {
            self.controlView.progressSlider.value = 0.0
        }
        let currentText = String(format: "%02d:%02d", intPosition / 60, intPosition % 60)
        self.controlView.updateTime(current: currentText, total: totalText)
    }
    
    func changeBottomStatus(_ isHidden: Bool) {
        self.controlView.isHidden = isHidden
    }
    
    var isBottomHidden: Bool {
        self.controlView.isHidden
    }
    
    var isSlider: Bool {
        return !self.headerTimeLabel.isHidden
    }
}


public class VideoNativePreview: NativePreview {
    var initialUrl: String
    var failedText: String = "failed"
    var retryText: String = "retry"
    
    private var player: IJKMediaPlayback?
    
    private lazy var controlView: PKLiveVideoControlView = {
        PKLiveVideoControlView { [weak weakSelf = self] (event) in
            weakSelf?.handlerEvent(event)
        }
    }()
    
    deinit {
        self.removeObervers()
        self.resume()
        self.timer.cancel()
        self.player?.view.removeFromSuperview()
        self.player?.shutdown()
        self.player = nil
    }
    
    
    public init(frame: CGRect, url: String, failedText: String, retryText: String) {
        self.initialUrl = url
        self.failedText = failedText
        self.retryText = retryText
        super.init(frame: frame)
        self.backgroundColor = UIColor(red: 25.0/255.0, green: 30.0/255.0, blue: 34.0/255.0, alpha: 1.0)
        
        #if DEBUG
        IJKFFMoviePlayerController.setLogReport(true)
        IJKFFMoviePlayerController.setLogLevel(IJKLogLevel(1))
        #else
        IJKFFMoviePlayerController.setLogReport(false)
        IJKFFMoviePlayerController.setLogLevel(IJKLogLevel(4))
        #endif

        self.setupPlayer()
        
        self.controlView.retryView.retryLabel.text = self.failedText // failed_to_load
        self.controlView.retryView.retryButton.setTitle(self.retryText, for: .normal) //"desktop_retry"
        self.addSubview(self.controlView)
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGestureRecognized(_:))))
        
        self.addObervers()

        self.status = .playing(true)
        self.player?.prepareToPlay()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer() {
        self.player?.shutdown()
        if let url = URL(string: self.initialUrl), let options = IJKFFOptions.byDefault() {
            options.setFormatOptionValue("rtmp,concat,ffconcat,file,subfile,http,https,tls,rtp,tcp,udp,crypto", forKey: "protocol_whitelist")
            options.setFormatOptionIntValue(0, forKey: "safe")
            options.setPlayerOptionIntValue(1, forKey: "enable-accurate-seek")
//            options.setPlayerOptionIntValue(1, forKey: "videotoolbox") // 硬解当前存在崩溃
            self.player = IJKFFMoviePlayerController(contentURL: url, with: options)
            self.player?.scalingMode = .aspectFit
            self.player?.shouldAutoplay = true
            self.player?.setPauseInBackground(false)
            if let playerView = self.player?.view {
                self.insertSubview(playerView, at: 0)
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.player?.view.frame = self.bounds

        self.controlView.frame = self.bounds
    }
    
    private var isPlayingBeforePause = false
    private var status: PlayerStatus = .pasue(false) {
        didSet {
            if oldValue != self.status {
                self.controlView.status = self.status

                if case .playing = self.status {
                    self.resume()
                } else if case .pasue = self.status {
                    self.suspend()
                    self.showBottomIfNeed()
                }
            }
        }
    }
    
    public override func viewWillAppear() {
        self.addObervers()
        self.playIfNeed()
    }
    
    public override func viewDidDisappear() {
        self.removeObervers()
        
        if case .playing = self.status {
            self.isPlayingBeforePause = true
            self.pause()
        } else {
            self.isPlayingBeforePause = false
        }
    }
    
    private func handlerEvent(_ event: PKLiveVideoControlView.Event) {
        switch event {
        case .play:
            self.play()
        case .pause:
            self.pause()
        case .landscape:
            self.delegate?.rotate("landscape")
//            self.supportedOrientationMask = .landscapeRight
//            QMUIHelper.rotate(to: QMUIHelper.deviceOrientation(with: .landscapeRight))
        case .portrait:
//            self.supportedOrientationMask = [.landscapeRight, .portrait]
//            QMUIHelper.rotate(to: .portrait)
            self.delegate?.rotate("portrait")
        case .seekBegain:
            break
        case .seek(let value):
            self.player?.currentPlaybackTime = value
            if self.player?.playbackState == .stopped {
                self.player?.play()
            }
        }
        self.autoHiddenBottomCount = 0
    }

    @objc private func tapGestureRecognized(_ gesture: UITapGestureRecognizer) {
        self.changeBottomStatus()
    }

    private var isTimerSuspend = true
    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(wallDeadline: DispatchWallTime.now(), repeating: .seconds(1))
        timer.setEventHandler(handler: { [weak weakSelf = self] in
            weakSelf?.updateTime()
        })
        return timer
    }()
    
    
    private var autoHiddenBottomCount: Int = 0
    
    private func changeBottomStatus() {
        if self.controlView.isBottomHidden {
            self.delegate?.changeAppBar("false")
//            self.navigationController?.navigationBar.isHidden = false
            self.controlView.changeBottomStatus(false)
            self.controlView.refreshControl(self.player)
            self.autoHiddenBottomCount = 0
        } else {
            self.delegate?.changeAppBar("true")
//            self.navigationController?.navigationBar.isHidden = true
            self.controlView.changeBottomStatus(true)
        }
    }

    private func hiddenBottomIfNeed() {
        if !(self.controlView.isBottomHidden), case .playing = self.status, !self.controlView.isSlider {
//            self.navigationController?.navigationBar.isHidden = true
            self.delegate?.changeAppBar("true")
            self.controlView.changeBottomStatus(true)
        }
    }
    private func showBottomIfNeed() {
        if self.controlView.isBottomHidden {
            self.delegate?.changeAppBar("false")
//            self.navigationController?.navigationBar.isHidden = false
            self.controlView.changeBottomStatus(false)
            self.controlView.refreshControl(self.player)
            self.autoHiddenBottomCount = 0
        }
    }
    
    private var recordDuration = 0
    
    private func updateTime() {
        self.controlView.refreshControl(self.player)
        self.autoHiddenBottomCount += 1
        
        let currentDuration = Int(self.player?.currentPlaybackTime ?? 0)
        if currentDuration > self.recordDuration {
            self.recordDuration = currentDuration
        }
        
        if self.autoHiddenBottomCount > 6 {
            self.autoHiddenBottomCount = 0
            self.hiddenBottomIfNeed()
        }
    }
    
    private func resume() {
        if self.isTimerSuspend {
            self.isTimerSuspend = false
            self.timer.resume()
        }
    }

    private func suspend() {
        if !self.isTimerSuspend {
            self.isTimerSuspend = true
            self.timer.suspend()
            self.controlView.refreshControl(self.player)
        }
    }
    
    private func addObervers() {
        self.removeObervers()
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerLoadStateDidChange(_:)), name: .IJKMPMoviePlayerLoadStateDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerPlaybackDidFinish(_:)), name: .IJKMPMoviePlayerPlaybackDidFinish, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.mediaIsPreparedToPlayDidChange(_:)), name: .IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerPlaybackStateDidChange(_:)), name: .IJKMPMoviePlayerPlaybackStateDidChange, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.playerWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // NotificationCenter.default.addObserver(self, selector: #selector(self.networkStatusDidChanged(_:)), name: Notification.Name("com.alamofire.networking.reachability.change"), object: nil)
    }

    private func removeObervers() {
        NotificationCenter.default.removeObserver(self, name: .IJKMPMoviePlayerPlaybackStateDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .IJKMPMoviePlayerPlaybackDidFinish, object: nil)
        NotificationCenter.default.removeObserver(self, name: .IJKMPMoviePlayerLoadStateDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        // NotificationCenter.default.removeObserver(self, name: Notification.Name("com.alamofire.networking.reachability.change"), object: nil)
    }

    @objc private func playerLoadStateDidChange(_ notification: Notification) {
        let loadState: IJKMPMovieLoadState? = self.player?.loadState
        if loadState?.contains(.playthroughOK) ?? false {
            debugPrint("[media player]PlayerLoadStateDidChange IJKMPMovieLoadStatePlaythroughOK")
            
        } else if loadState?.contains(.stalled) ?? false {
            debugPrint("[media player]PlayerLoadStateDidChange IJKMPMovieLoadStateStalled")
            if !(NetworkReachabilityManager.default?.isReachable ?? false) {
                self.isPlayingBeforePause = false
                self.pause()
            } else {
                self.status = .playing(true)
            }
        } else {
            debugPrint("[media player]PlayerLoadStateDidChange else")
        }
    }

    @objc private func playerPlaybackDidFinish(_ notification: Notification) {
        let mReason = notification.userInfo?[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] as? NSNumber
        let reason = IJKMPMovieFinishReason(rawValue: mReason?.intValue ?? 0) ?? IJKMPMovieFinishReason.playbackEnded
        if reason == .playbackEnded {
            debugPrint("[media player]PlayerPlaybackDidFinish IJKMPMovieFinishReasonPlaybackEnded")
            
        } else if reason == .userExited {
            debugPrint("[media player]PlayerPlaybackDidFinish IJKMPMovieFinishReasonUserExited")
        } else {
            debugPrint("[media player]PlayerPlaybackDidFinish IJKMPMovieFinishReasonPlaybackError")
            self.status = .pasue(true)
        }
    }

    @objc private func mediaIsPreparedToPlayDidChange(_ notification: Notification) {
        if self.player?.isPreparedToPlay ?? false {
            self.controlView.prepareForControlView()
            self.play()
            debugPrint("[media player]mediaIsPreparedToPlayDidChange true")
        } else {
            debugPrint("[media player]mediaIsPreparedToPlayDidChange false")
        }
    }

    @objc private func playerPlaybackStateDidChange(_ notification: Notification) {
        let playbackState = self.player?.playbackState ?? IJKMPMoviePlaybackState.stopped
        switch playbackState {
        case .stopped:
            debugPrint("[media player]playerPlaybackStateDidChange stop")
            self.status = .pasue(false)
        case .playing:
            debugPrint("[media player]playerPlaybackStateDidChange playing")
            let loadState: IJKMPMovieLoadState? = self.player?.loadState
            if loadState?.contains(.stalled) ?? false {
                self.status = .playing(true)
            } else {
                self.status = .playing(false)
            }
            //用于处理加载完成，但是页面不在显示，或者应用处于后台
            if !self.qmui_visible || UIApplication.shared.applicationState == .inactive {
                if case .playing = self.status {
                    self.isPlayingBeforePause = true
                    self.pause()
                } else {
                    self.isPlayingBeforePause = false
                }
            }
        case .paused:
            debugPrint("[media player]playerPlaybackStateDidChange paused")
            if !(NetworkReachabilityManager.default?.isReachable ?? false) {
                self.status = .pasue(true)
            } else {
                self.status = .pasue(false)
            }
        case .interrupted:
            debugPrint("[media player]playerPlaybackStateDidChange interrupted")
            self.status = .pasue(false)
        case .seekingForward:
            debugPrint("[media player]playerPlaybackStateDidChange seekingForward")
            break
        case .seekingBackward:
            debugPrint("[media player]playerPlaybackStateDidChange seekingBackward")
            break
        default:
            debugPrint("[media player]playerPlaybackStateDidChange other")
            self.status = .pasue(false)
        }
    }

    @objc private func playerWillResignActive(_ notification: Notification) {
        if case .playing = self.status {
            self.isPlayingBeforePause = true
            self.pause()
        } else {
            self.isPlayingBeforePause = false
        }
    }

    @objc private func playerDidBecomeActive(_ notification: Notification) {
        self.playIfNeed()
    }
    
    // @objc private func networkStatusDidChanged(_ notification: Notification) {
    //     if !(NetworkReachabilityManager.default?.isReachable ?? false) {
    //         self.isPlayingBeforePause = false
    //         if case .playing = self.status {
    //             self.pause()
    //         }
    //     }
    // }

    private func playIfNeed() {
        if self.isPlayingBeforePause {
            self.play()
        }
    }

    private func play() {
        if !(NetworkReachabilityManager.default?.isReachable ?? false) {
            self.pause()
            return
        }
        if !(self.player?.isPreparedToPlay ?? false) {
            self.setupPlayer()
            self.status = .playing(true)
            self.player?.prepareToPlay()
            return
        }
        if self.player?.playbackState == .stopped {
            self.player?.currentPlaybackTime = 0
        }
        self.player?.play()
    }

    private func pause() {
        self.player?.pause()
    }
}
