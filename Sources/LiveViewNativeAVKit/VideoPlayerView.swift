//
//  AVKitRegistry.swift
//  LiveViewNativeAVKit
//
//  Created by May Matyi on 5/18/23.
//

import SwiftUI
import AVFoundation
import AVKit
import Combine
import LiveViewNative
import CoreMedia

class VideoPlayerObserver<R: RootRegistry>: ObservableObject {
    @Published var isMuted: Bool = false
    @Published var timeControlStatus: AVPlayer.TimeControlStatus = .waitingToPlayAtSpecifiedRate
    @Published var assigns: Assigns = Assigns()

    var player: AVPlayer
    var interval: CMTime

    class Assigns: ObservableObject {
        @Published var playbackTime: Float64

        init() {
            self.playbackTime = 0.0
        }
    }

    init(interval: CMTime) {
        self.player = AVPlayer()
        self.interval = interval

        // Add time observer. Invoke closure on the main queue.
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
            [weak self] time in self?.assigns.playbackTime = CMTimeGetSeconds(time)
        }
    }
}

struct VideoPlayerView<R: RootRegistry>: View {
    @Event("on-pause", type: "click") private var pause
    @Event("on-play", type: "click") private var play
    @LiveBinding(attribute: "is-muted") private var isMuted: Bool
    @LiveBinding(attribute: "playback-time") private var playbackTime: Float64
    @LiveBinding(attribute: "playback-time-update-interval") private var playbackTimeUpdateInterval: Float64
    @LiveBinding(attribute: "time-control-status") private var timeControlStatus: String
    @LiveContext<R> private var context
    @ObservedElement private var element: ElementNode
    @StateObject private var observer: VideoPlayerObserver<R>
    var autoplay: Bool = false
    var url: URL

    init(element: ElementNode) {
        if let value = element.attributeValue(for: "autoplay") {
            self.autoplay = Bool(value)!
        }
        if let value = element.attributeValue(for: "url") {
            self.url = URL(string: value)!
        } else {
            self.url = URL(string: "")!
        }
        let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        _observer = StateObject(wrappedValue: VideoPlayerObserver(interval: interval))
    }

    var body: some View {
        VideoPlayer(player: self.observer.player)
            .onAppear {
                timeControlStatus = "paused"
                observer.player.replaceCurrentItem(with: AVPlayerItem(url: url))

                if self.autoplay {
                    self.observer.player.play()
                }
            }
            .onReceive(context.coordinator.receiveEvent("pause"), perform: performPause)
            .onReceive(context.coordinator.receiveEvent("play"), perform: performPlay)
            .onReceive(context.coordinator.receiveEvent("seek"), perform: performSeek)
            .onReceive(observer.assigns.$playbackTime.throttle(for: AVKitHelpers.floatToStride(float: playbackTimeUpdateInterval), scheduler: RunLoop.current, latest: true)) { value in playbackTime = value }
            .onReceive(observer.player.publisher(for: \.isMuted)) { value in isMuted = value }
            .onReceive(observer.player.publisher(for: \.timeControlStatus)) { value in syncTimeControlStatus(status: value) }
    }

    func performPlay(params: Dictionary<String, Any>) {
        observer.player.play()
    }

    func performPause(params: Dictionary<String, Any>) {
        observer.player.pause()
    }

    func performSeek(params: Dictionary<String, Any>) {
        switch (params["playback_time"]) {
        case .some(let value):
            let castValue = value as! Float64
            let to = AVKitHelpers.floatToCMTime(float: castValue)
            let toleranceBefore = AVKitHelpers.floatToCMTime(float: 0.0)
            let toleranceAfter = AVKitHelpers.floatToCMTime(float: 0.0)

            observer.player.seek(to: to, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
            playbackTime = CMTimeGetSeconds(observer.player.currentTime())

        case .none:
            return
        }
    }

    func syncTimeControlStatus(status: AVPlayer.TimeControlStatus) {
        switch (status) {
        case .paused:
            if timeControlStatus != "" && timeControlStatus != "paused" {
                pause(value: ["playback_time": playbackTime])
            }
            playbackTime = CMTimeGetSeconds(observer.player.currentTime())
            timeControlStatus = "paused"
        case .playing:
            if timeControlStatus != "" && timeControlStatus != "playing" {
                play(value: ["playback_time": playbackTime])
            }
            playbackTime = CMTimeGetSeconds(observer.player.currentTime())
            timeControlStatus = "playing"
        case .waitingToPlayAtSpecifiedRate:
            timeControlStatus = "waiting_to_play_at_specified_rate"
        @unknown default:
            timeControlStatus = "unknown"
        }
    }
}
