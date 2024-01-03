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
/// ```elixir
/// defmodule MyApp.VideoPlayerLive do
///   use Phoenix.LiveView
///   use LiveViewNative.LiveView
/// 
///   native_binding :is_muted, Atom, false
///   native_binding :time_control_status, String, ""
///   native_binding :playback_time, Float, 5.0
///   native_binding :playback_time_update_interval, Float, 0.05
/// 
///   @impl true
///   def render(%{platform_id: :swiftui} = assigns) do
///     ~SWIFTUI"""
///     <VStack id="webview-example">
///       <VStack>
///         <%= @playback_time %>
///       </VStack>
///       <VideoPlayer
///         autoplay
///         is-muted="is_muted"
///         playback-time="playback_time"
///         playback-time-update-interval="playback_time_update_interval"
///         on-play="handle_play"
///         on-pause="handle_pause"
///         time-control-status="time_control_status"
///         url="http://192.168.1.143:4000/videos/sample2.mp4"
///         volume="volume" />
///     </VStack>
///     """
///   end
/// end
/// ```
///
/// ## Attributes
/// * ``autoplay``
/// * ``url``
///
/// ## Bindings
/// * ``isMuted``
/// * ``playbackTime``
/// * ``playbackTimeUpdateInterval``
/// * ``timeControlStatus``
///
/// ## Events
/// - ``pauseEvent``
/// - ``playEvent``
#if swift(>=5.8)
@_documentation(visibility: public)
#endif
struct VideoPlayerView<R: RootRegistry>: View {
    @StateObject private var coordinator = VideoPlayerCoordinator()
    
    /// The URL of the video to play.
    @Attribute("url", transform: {
        guard let value = $0?.value else { throw AttributeDecodingError.missingAttribute(Self.self) }

        return URL(string: value)!
    }) private var url: URL
    
    /// If true, the video will play when the view appears.
    @Attribute("autoplay") private var autoplay: Bool
    
    @Attribute("phx-debounce") private var debounce: Double?
    @Attribute("phx-throttle") private var throttle: Double?

    /// A boolean indicating whether the video player is muted.
    @ChangeTracked(attribute: "is-muted") private var isMuted: Bool = false

    /// The current playback time of the video player in seconds.
    @Attribute("playback-time") private var playbackTime: Double?
    /// The name of the change event. Used by ``playbackTime`` to bypass the default debounce/throttle behavior.
    @Attribute("phx-change") private var changeEventName: String

    /// The current time control status of the video player (playing, paused, etc.).
    @ChangeTracked(attribute: "time-control-status") private var timeControlStatus: TimeControlStatus = .paused

    @LiveContext<R> private var context
    @ObservedElement private var element: ElementNode
    
    var body: some View {
        VideoPlayer(player: coordinator.player) {
            context.buildChildren(of: element)
        }
        // remote changes
        .onChange(of: url) { newValue in
            coordinator.setPlayerItem(newValue)
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
            guard let playbackTime else { return }
            Task {
                // send a change event without automatic debouncing, the observer handles the debounce instead.
                try await context.coordinator.pushEvent(
                    type: "click",
                    event: changeEventName,
                    value: ["playback-time": playbackTime],
                    target: element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        .onReceive(coordinator.player.publisher(for: \.timeControlStatus)) {
            timeControlStatus = .init($0)
        }
        // setup
        .task {
            coordinator.setPlayerItem(url)
        }
        .onChange(of: debounce ?? throttle) {
            coordinator.setupTimeObserver($0)
        }
        .onChange(of: coordinator.player.currentItem) { item in
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
