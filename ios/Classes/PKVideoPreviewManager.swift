//
//  PKVideoPreviewManager.swift
//  video_native_preview
//
//  Created by dujianjie on 2022/9/14.
//

import Foundation
import Alamofire
import IJKMediaFrameworkWithSSL

protocol PKVideoPreviewManagerDelegate: NSObjectProtocol {
    
    func configVideoView(videoView: UIView?)
    
    func didPreparePlay()
    func didPlaying()
    func didBuffering()
    func didFinishPlay()
    func didPlayInterrupt(event: PKVideoPreviewManager.InterruptType)
    func didPlayError(_ error: Any?)
    func shouldContinuousUpdateTime() -> Bool
    func didUpdateTime(currentTime: TimeInterval, playableTime: TimeInterval, totalTime: TimeInterval)
    func didUpdateDegree(degree: PKVideoPreviewManager.Degree)
}

extension PKVideoPreviewManagerDelegate {
    func didPreparePlay() {
        
    }
    
    func didPlaying() {
        
    }
    
    func didBuffering() {
        
    }
    
    func didFinishPlay() {
        
    }
    
    func didPlayInterrupt(event: PKVideoPreviewManager.InterruptType) {
        
    }
    
    func didPlayError(_ error: Any?) {
        
    }
    
    func shouldContinuousUpdateTime() -> Bool {
        true
    }
    
    func didUpdateTime(currentTime: TimeInterval, playableTime: TimeInterval, totalTime: TimeInterval) {
        
    }
    
    func didUpdateDegree(degree: PKVideoPreviewManager.Degree) {
        
    }
}

class PKVideoPreviewManager: NSObject {
    enum InterruptType {
        case noNetwork
        case loseWifi
        case hasWifi
    }
    
    enum Degree {
        case normal // LandscapeRight
        case piDivideTwo // Portrait
        case onePi // LandscapeLeft
        case onePointFivePi // PortraitUpsideDown
    }
    
    var videoUrl: URL?
    
    var ijkPlayer: IJKMediaPlayback? { self.player }
    
    /// resumePlayer完成后自动播放
    var playWhenResumed = false  {
        didSet {
            if playWhenResumed == oldValue {
                return
            }
            let isPrepared = self.player?.loadState.contains(.playthroughOK) ?? false
            if isPrepared && (self.player?.isPlaying() ?? false) && !self.isPausePlay && !self.isFinishPlay {
                self.checkBeforePlay()
            }
        }
    }
    /// 4G下自动播放
    var autoPlayViaWlan = false
    /// 进入后台暂停播放
    var pauseInBackground = true
    
    fileprivate(set) var duration: TimeInterval = 0
    fileprivate(set) var currentDuration: TimeInterval = 0
    fileprivate(set) var degree: Degree = .normal
    
    weak var delegate: PKVideoPreviewManagerDelegate? = nil
    
    var totalDuration: TimeInterval { self.player?.duration ?? 0.0 }
    
    
    fileprivate var isTimerRunning = false
    
    fileprivate var isEnterBackground = false
    
    fileprivate var shouldUpdateTime = true
    
    fileprivate var isPausePlay = false
    
    fileprivate var isFinishPlay = false
    
    fileprivate var isSeekingTime = false
    
    fileprivate var penddingSeekTime: TimeInterval = 0
    
    fileprivate var networkStatus = NetworkReachabilityManager.default?.status ?? .unknown
    
    fileprivate var player: IJKMediaPlayback? = nil
    
    fileprivate var timer: DispatchSourceTimer? = nil
    
    fileprivate lazy var timerQueue: DispatchQueue = DispatchQueue(label: "com.cvte.video.player.queue")
    deinit {
        if isTimerRunning {
            self.timer?.cancel()
        } else {
            self.timer?.resume()
            self.timer?.cancel()
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupPlayerForLiveConcatVideo() {
        #if DEBUG
        IJKFFMoviePlayerController.setLogReport(true)
        IJKFFMoviePlayerController.setLogLevel(IJKLogLevel(1))
        #else
        IJKFFMoviePlayerController.setLogReport(false)
        IJKFFMoviePlayerController.setLogLevel(IJKLogLevel(4))
        #endif
        
        if let videoUrl = self.videoUrl, let options = IJKFFOptions.byDefault() {
            options.setFormatOptionValue("rtmp,concat,ffconcat,file,subfile,http,https,tls,rtp,tcp,udp,crypto", forKey: "protocol_whitelist")
            options.setPlayerOptionIntValue(1, forKey: "enable-accurate-seek")
            options.setFormatOptionIntValue(0, forKey: "safe")
            self.player = IJKFFMoviePlayerController(contentURL: videoUrl, with: options)
            self.player?.scalingMode = .aspectFit
            self.commonSetupPlayer()
        }
    }
    
    func resumePlayer() {
        self.addPlayerNotificationObservers()
        self.player?.prepareToPlay()
    }
    
    func stopPlayer(andRemoveView: Bool = true) {
        self.removePlayerNotificationObservers()
        self.shouldUpdateTime = false
        self.stopTimer()
        if andRemoveView {
            self.player?.view.removeFromSuperview()
        }
        self.player?.shutdown()
        self.player = nil
    }

    var isPlaying: Bool {
        self.player?.isPlaying() ?? false
    }
    
    func checkBeforePlay() {
        if self.checkNetworkReachable() {
            if self.autoPlayViaWlan || self.checkWifiReachable() {
                self.play()
            } else {
                self.delegate?.didPlayInterrupt(event: .loseWifi)
            }
        } else {
            self.delegate?.didPlayInterrupt(event: .noNetwork)
        }
    }
    
    func play() {
        self.isPausePlay = false
        self.isFinishPlay = false
        self.shouldUpdateTime = true
        if !(self.player?.isPlaying() ?? false) {
            self.player?.play()
        }
        self.updateTime()
    }

    func pause() {
        self.isPausePlay = true
        if self.player?.isPlaying() ?? false {
            self.player?.pause()
        }
        self.updateTime()
    }
    
    func beginSeekTime() {
        self.isSeekingTime = true
    }
  
    func endSeekTime() {
        self.isSeekingTime = false
    }
    
    func seek(to time: TimeInterval, shouldUpdatePlayer: Bool) {
        self.penddingSeekTime = time
        if shouldUpdatePlayer {
            self.player?.currentPlaybackTime = time
        }
        self.updateTime()
    }

    fileprivate func commonSetupPlayer() {
        self.player?.shouldAutoplay = false
        self.setupVideoDegree()
        self.delegate?.configVideoView(videoView: self.player?.view)
    }
    
    fileprivate func setupVideoDegree() {
        DispatchQueue.global().async {
            
            self.degree = .normal
            
            debugPrint("PlayerVideoDegree did update: \(self.degree)")
            
            DispatchQueue.main.async {
                self.delegate?.didUpdateDegree(degree: self.degree)
            }
        }
    }
    
    fileprivate func checkNetworkReachable() -> Bool {
        NetworkReachabilityManager.default?.isReachable ?? false
    }
    
    fileprivate func checkWifiReachable() -> Bool {
        NetworkReachabilityManager.default?.isReachableOnEthernetOrWiFi ?? false
    }

    fileprivate func addPlayerNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidEnterBackground(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.networkStatusDidChanged(_:)), name: Notification.Name("com.alamofire.networking.reachability.change"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerLoadStateDidChange(_:)), name: NSNotification.Name.IJKMPMoviePlayerLoadStateDidChange, object: self.player)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerPlaybackDidFinish(_:)), name: NSNotification.Name.IJKMPMoviePlayerPlaybackDidFinish, object: self.player)
        NotificationCenter.default.addObserver(self, selector: #selector(self.mediaIsPreparedToPlayDidChange(_:)), name: NSNotification.Name.IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: self.player)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerPlaybackStateDidChange(_:)), name: NSNotification.Name.IJKMPMoviePlayerPlaybackStateDidChange, object: self.player)
    }
 
    fileprivate func removePlayerNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKMPMoviePlayerPlaybackStateDidChange, object: self.player)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: self.player)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKMPMoviePlayerPlaybackDidFinish, object: self.player)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKMPMoviePlayerLoadStateDidChange, object: self.player)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("com.alamofire.networking.reachability.change"), object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    fileprivate func updateTime() {
        var position: TimeInterval = 0
        self.penddingSeekTime = 0
        if let mPosition = self.isSeekingTime ? self.penddingSeekTime : self.player?.currentPlaybackTime, mPosition > 0 {
            position = mPosition
        }
        if position.isNaN {
            position = 0
        }
        var duration: TimeInterval = self.player?.duration ?? 0
        if duration.isNaN {
            duration = 0
        }
        var playable: TimeInterval = self.player?.playableDuration ?? 0
        if playable.isNaN {
            playable = 0
        }
        
        //解决webm文件获取不到总时长，可以用playable替代
        if  duration <= 0 && playable > 0 {
            duration = playable
        }
        
        if !self.isSeekingTime && self.isFinishPlay {
            position = duration
        }
        
        debugPrint("PlayerTimeStateDidUpdate current: \(position), bufferd: \(self.player?.bufferingProgress ?? 0), playable: \(playable), total: \(duration)")
        
        DispatchQueue.main.async {
            self.delegate?.didUpdateTime(currentTime: position, playableTime: playable, totalTime: duration)
        }
        
        let shouldContinuousTime: Bool = self.delegate?.shouldContinuousUpdateTime() ?? true
        if shouldContinuousTime && self.shouldUpdateTime && !self.isSeekingTime {
            self.startTimer()
        } else {
            self.stopTimer()
        }
    }

    fileprivate func startTimer() {
        if self.isTimerRunning {
            return
        }
        self.isTimerRunning = true
        self.timer = DispatchSource.makeTimerSource(queue: self.timerQueue)
        self.timer?.schedule(wallDeadline: DispatchWallTime.now(), repeating: .milliseconds(500))
        self.timer?.setEventHandler(handler: { [weak weakSelf = self] in
            weakSelf?.updateTime()
        })
        self.timer?.resume()
    }

    fileprivate func stopTimer() {
        if self.timer == nil {
            return
        }
        if self.isTimerRunning {
            self.isTimerRunning = false
            self.timer?.cancel()
            self.timer = nil
        }
    }
    
    @objc private func playerDidEnterBackground(_ notification: Notification) {
        guard self.pauseInBackground else { return }
        self.isEnterBackground = true
        if self.isFinishPlay || self.isPausePlay {
            return
        }
        if (self.player?.isPreparedToPlay ?? false) && (self.player?.isPlaying() ?? false) {
            self.pause()
            self.isPausePlay = false
        }
    }

    @objc private func playerDidBecomeActive(_ notification: Notification) {
        guard self.pauseInBackground else { return }
        self.isEnterBackground = false
        if self.isFinishPlay || self.isPausePlay {
            return
        }
        if self.player?.isPreparedToPlay ?? false {
            if self.checkNetworkReachable() && (self.autoPlayViaWlan || self.checkWifiReachable()) {
                self.play()
            }
        }
    }
 
    @objc private func networkStatusDidChanged(_ notification: Notification) {
        var status: NetworkReachabilityManager.NetworkReachabilityStatus = .unknown
        if let mStatus = notification.object as? NetworkReachabilityManager.NetworkReachabilityStatus {
            status = mStatus
        }
        if self.isPausePlay || self.isFinishPlay {
            self.networkStatus = status
            return
        }
        switch status {
        case .notReachable: self.delegate?.didPlayInterrupt(event: .noNetwork)
        case .reachable(let type):
            switch type {
            case .cellular:
                if case .reachable(let networkType) = self.networkStatus, networkType == .ethernetOrWiFi {
                    self.delegate?.didPlayInterrupt(event: .loseWifi)
                }
            case .ethernetOrWiFi: self.delegate?.didPlayInterrupt(event: .hasWifi)
            }
        default: break
        }
        self.networkStatus = status
    }
    
    @objc private func playerLoadStateDidChange(_ notification: Notification) {
        let loadState: IJKMPMovieLoadState? = self.player?.loadState
        if loadState?.contains(.playthroughOK) ?? false {
            debugPrint("PlayerLoadStateDidChange IJKMPMovieLoadStatePlaythroughOK")
            self.delegate?.didPreparePlay()
            if self.isEnterBackground || self.isPausePlay || self.isFinishPlay {
                return
            }
            if self.playWhenResumed {
                self.checkBeforePlay()
            }
        } else if loadState?.contains(.stalled) ?? false {
            debugPrint("PlayerLoadStateDidChange IJKMPMovieLoadStateStalled")
            self.delegate?.didBuffering()
        } else {
            debugPrint("PlayerLoadStateDidChange else")
        }
    }
    
    @objc private func playerPlaybackDidFinish(_ notification: Notification) {
        let mReason = notification.userInfo?[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] as? NSNumber
        let reason = IJKMPMovieFinishReason(rawValue: mReason?.intValue ?? 0) ?? IJKMPMovieFinishReason.playbackEnded
        if reason == .playbackEnded {
            debugPrint("PlayerPlaybackDidFinish IJKMPMovieFinishReasonPlaybackEnded");
            self.shouldUpdateTime = false
            self.isFinishPlay = true
            self.delegate?.didFinishPlay()
        } else if reason == .userExited {
            debugPrint("PlayerPlaybackDidFinish IJKMPMovieFinishReasonUserExited");
        } else {
            debugPrint("PlayerPlaybackDidFinish IJKMPMovieFinishReasonPlaybackError");
            self.delegate?.didPlayError(notification.userInfo?["error"])
        }
    }
  
    @objc private func mediaIsPreparedToPlayDidChange(_ notification: Notification) {
        debugPrint("MediaIsPreparedToPlayDidChange")
    }

    @objc private func playerPlaybackStateDidChange(_ notification: Notification) {
        let playbackState = self.player?.playbackState ?? IJKMPMoviePlaybackState.stopped
        switch playbackState {
        case .stopped:
            debugPrint("PlayerPlaybackStateDidChange IJKMPMoviePlaybackStateStopped: \(playbackState)")
        case .playing:
            debugPrint("PlayerPlaybackStateDidChange IJKMPMoviePlaybackStatePlaying: \(playbackState)")
            if self.isEnterBackground || self.isPausePlay {
                self.player?.pause()
                return
            }
            self.delegate?.didPlaying()
        case .paused:
            debugPrint("PlayerPlaybackStateDidChange IJKMPMoviePlaybackStatePaused: \(playbackState)")
        case .interrupted:
            debugPrint("PlayerPlaybackStateDidChange IJKMPMoviePlaybackStateInterrupted: \(playbackState)")
        case .seekingForward:
            debugPrint("PlayerPlaybackStateDidChange IJKMPMoviePlaybackStateSeekingForward: \(playbackState)")
        case .seekingBackward:
            debugPrint("PlayerPlaybackStateDidChange IJKMPMoviePlaybackStateSeekingBackward: \(playbackState)")
        default:
            debugPrint("PlayerPlaybackStateDidChange IJKMPMoviePlayBackStateDidChange: \(playbackState)")
        }
    }
}
