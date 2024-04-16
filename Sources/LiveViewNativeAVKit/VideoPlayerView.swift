//
//  AVKitRegistry.swift
//  LiveViewNativeAVKit
//
//  Created by May Matyi on 5/18/23.
//

import SwiftUI
import Combine
import AVFoundation
import AVKit
import LiveViewNative
import CoreMedia

/// A native video player view. It can be rendered in a LiveViewNative app using the `VideoPlayer` element.
///
/// - Note: You must include a `phx-throttle` or `phx-debounce` attribute to receive updates to the `playbackTime`.
///
/// ```elixir
/// <VideoPlayer
///   autoplay
///   isMuted
///   url="videos/sample.mov"
///   playbackTime={30}
///   phx-debounce={1000}
///   phx-change="player-changed"
/// />
/// ```
///
/// ## Attributes
/// * ``autoplay``
/// * ``url``
/// * ``isMuted``
/// * ``playbackTime``
/// * ``timeControlStatus``
@_documentation(visibility: public)
@LiveElement
struct VideoPlayer<Root: RootRegistry>: View {
    @LiveElementIgnored
    @StateObject private var coordinator = VideoPlayerCoordinator()
    
    /// The URL of the video to play.
    @_documentation(visibility: public)
    private var url: String?
    
    /// If true, the video will play when the view appears.
    @_documentation(visibility: public)
    private var autoplay: Bool = false
    
    @_documentation(visibility: public)
    @LiveAttribute(.init(name: "phx-debounce"))
    private var debounce: Double?
    @_documentation(visibility: public)
    @LiveAttribute(.init(name: "phx-throttle"))
    private var throttle: Double?

    /// A boolean indicating whether the video player is muted.
    @_documentation(visibility: public)
    @ChangeTracked(attribute: "isMuted")
    private var isMuted: Bool = false

    /// The current playback time of the video player in seconds.
    @_documentation(visibility: public)
    private var playbackTime: Double?
    /// The name of the change event. Used by ``playbackTime`` to bypass the default debounce/throttle behavior.
    @_documentation(visibility: public)
    @LiveAttribute(.init(name: "phx-change"))
    private var changeEventName: String?

    /// The current time control status of the video player (playing, paused, etc.).
    @_documentation(visibility: public)
    @ChangeTracked(attribute: "timeControlStatus")
    private var timeControlStatus: TimeControlStatus = .paused
    
    var body: some View {
        AVKit.VideoPlayer(player: coordinator.player) {
            $liveElement.children()
        }
        // remote changes
        .onChange(of: url) { newValue in
            guard let url = newValue.flatMap({ URL(string: $0, relativeTo: $liveElement.context.url) })
            else { return }
            coordinator.setPlayerItem(url)
        }
        .onChange(of: isMuted) {
            coordinator.player.isMuted = $0
        }
        .onChange(of: playbackTime) {
            if let playbackTime = $0,
               playbackTime != coordinator.playbackTime.value
            {
                coordinator.player.seek(to: CMTimeMakeWithSeconds(playbackTime, preferredTimescale: 1))
            }
        }
        .onChange(of: timeControlStatus) {
            switch $0 {
            case .paused:
                coordinator.player.pause()
            case .playing:
                coordinator.player.play()
            default:
                break
            }
        }
        // local changes
        .onReceive(coordinator.player.publisher(for: \.isMuted)) {
            isMuted = $0
        }
        .onReceive(coordinator.playbackTime) { playbackTime in
            guard let playbackTime,
                  let changeEventName
            else { return }
            Task {
                // send a change event without automatic debouncing, the observer handles the debounce instead.
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: changeEventName,
                    value: ["playback-time": playbackTime],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        .onReceive(coordinator.player.publisher(for: \.timeControlStatus)) {
            timeControlStatus = .init($0)
        }
        // setup
        .task {
            guard let url = url.flatMap({ URL(string: $0, relativeTo: $liveElement.context.url) })
            else { return }
            coordinator.setPlayerItem(url)
        }
        .onChange(of: debounce ?? throttle) {
            coordinator.setupTimeObserver($0)
        }
        .onChange(of: coordinator.player.currentItem) { item in
            coordinator.player.isMuted = isMuted
            coordinator.player.seek(to: CMTimeMakeWithSeconds(playbackTime ?? 0, preferredTimescale: 1))
            coordinator.setupTimeObserver(debounce ?? throttle)
            if autoplay {
                coordinator.player.play()
            }
        }
    }
    
    /// An observer for a `VideoPlayerView` that watches for changes to an `AVPlayer` instance
    /// along with other properties through the `VideoPlayerObserver.Assigns` class.
    final class VideoPlayerCoordinator: ObservableObject {
        let player: AVPlayer = .init()
        
        var timeObserver: Any?
        
        var playbackTime = CurrentValueSubject<Double?, Never>(nil)
        
        init() {}
        
        func setPlayerItem(_ url: URL) {
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
        }
        
        func setupTimeObserver(_ interval: Double?) {
            if let timeObserver {
                player.removeTimeObserver(timeObserver)
            }
            if let interval {
                player.addPeriodicTimeObserver(
                    forInterval: CMTime(seconds: interval / 1000, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                    queue: .main
                ) { [weak self] time in
                    self?.playbackTime.value = CMTimeGetSeconds(time)
                }
            }
        }
    }
}

enum TimeControlStatus: String, AttributeDecodable, Codable, Equatable {
    case playing
    case paused
    case waitingToPlayAtSpecifiedRate
    
    init(_ value: AVPlayer.TimeControlStatus) {
        switch value {
        case .paused:
            self = .paused
        case .waitingToPlayAtSpecifiedRate:
            self = .waitingToPlayAtSpecifiedRate
        case .playing:
            self = .playing
        }
    }
}
