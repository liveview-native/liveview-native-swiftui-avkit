//
//  AVKitRegistry.swift
//  LiveViewNativeAVKit
//
//  Created by May Matyi on 5/18/23.
//

import SwiftUI
import AVFoundation
import AVKit
import LiveViewNative
import CoreMedia

/// A native video player view. It can be rendered in a LiveViewNative app using the `VideoPlayer` element.
/// 
/// ```elixir
///   defmodule MyApp.VideoPlayerLive do
///     use Phoenix.LiveView
///     use LiveViewNative.LiveView
///   
///     native_binding :is_muted, Atom, false
///     native_binding :time_control_status, String, ""
///     native_binding :playback_time, Float, 5.0
///     native_binding :playback_time_update_interval, Float, 0.05
///   
///     @impl true
///     def render(%{platform_id: :swiftui} = assigns) do
///       ~SWIFTUI"""
///       <VStack id="webview-example">
///         <VStack>
///           <%= @playback_time %>
///         </VStack>
///         <VideoPlayer
///           autoplay="true"
///           is-muted="is_muted"
///           playback-time="playback_time"
///           playback-time-update-interval="playback_time_update_interval"
///           on-play="handle_play"
///           on-pause="handle_pause"
///           time-control-status="time_control_status"
///           url="http://192.168.1.143:4000/videos/sample2.mp4"
///           volume="volume" />
///       </VStack>
///       """
///     end
///   end
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
    /// An event that is fired when the video player is paused.
    #if swift(>=5.8)
    @_documentation(visibility: public)
    #endif
    @Event("on-pause", type: "click") private var pause

    /// An event that is fired when the video player is played.
    #if swift(>=5.8)
    @_documentation(visibility: public)
    #endif
    @Event("on-play", type: "click") private var play

    /// A boolean indicating whether the video player is muted.
    #if swift(>=5.8)
    @_documentation(visibility: public)
    #endif
    @LiveBinding(attribute: "is-muted") private var isMuted: Bool

    /// The current playback time of the video player in seconds.
    #if swift(>=5.8)
    @_documentation(visibility: public)
    #endif
    @LiveBinding(attribute: "playback-time") private var playbackTime: Float64

    /// The interval at which the playback time is updated.
    #if swift(>=5.8)
    @_documentation(visibility: public)
    #endif
    @LiveBinding(attribute: "playback-time-update-interval") private var playbackTimeUpdateInterval: Float64

    /// The current time control status of the video player (playing, paused, etc.).
    #if swift(>=5.8)
    @_documentation(visibility: public)
    #endif
    @LiveBinding(attribute: "time-control-status") private var timeControlStatus: String

    /// If true, the video will play when the view appears.
    #if swift(>=5.8)
    @_documentation(visibility: public)
    #endif
    var autoplay: Bool = false

    /// The URL of the video to play.
    #if swift(>=5.8)
    @_documentation(visibility: public)
    #endif
    var url: URL

    @LiveContext<R> private var context
    @ObservedElement private var element: ElementNode
    @StateObject private var observer: VideoPlayerObserver<R>

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
            .onReceive(observer.player.publisher(for: \.isMuted)) { value in isMuted = value }
            .onReceive(observer.player.publisher(for: \.timeControlStatus)) { value in syncTimeControlStatus(status: value) }
            /// This is a workaround for SwiftUI not supporting `onReceive` for `AVPlayer`'s `currentTime` property.
            .onReceive(observer.assigns.$playbackTime.throttle(for: .init(playbackTimeUpdateInterval), scheduler: RunLoop.current, latest: true)) { value in playbackTime = value }
    }

    func performPlay(params: Dictionary<String, Any>) {
        observer.player.play()
    }

    func performPause(params: Dictionary<String, Any>) {
        observer.player.pause()
    }

    func performSeek(params: Dictionary<String, Any>) {
        guard let value = params["playback_time"] as? Float64 else { return }
        
        let to = CMTimeMakeWithSeconds(value, preferredTimescale: 1)
        let toleranceBefore = CMTimeMakeWithSeconds(0.0, preferredTimescale: 1)
        let toleranceAfter = CMTimeMakeWithSeconds(0.0, preferredTimescale: 1)

        observer.player.seek(to: to, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)

        // Always update playback time when seeking.
        playbackTime = CMTimeGetSeconds(observer.player.currentTime())
    }

    func syncTimeControlStatus(status: AVPlayer.TimeControlStatus) {
        switch (status) {
        case .paused:
            /// Call `pauseEvent`` if the time control status has changed to paused from another state.
            if timeControlStatus != "" && timeControlStatus != "paused" {
                pause(value: ["playback_time": playbackTime])
            }
            playbackTime = CMTimeGetSeconds(observer.player.currentTime())
            timeControlStatus = "paused"

        case .playing:
            /// Call `playEvent` if the time control status has changed to paused from another state.
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

/// An observer for a `VideoPlayerView` that watches for changes to an `AVPlayer` instance
/// along with other properties through the `VideoPlayerObserver.Assigns` class.
#if swift(>=5.8)
@_documentation(visibility: public)
#endif
class VideoPlayerObserver<R: RootRegistry>: ObservableObject {
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
