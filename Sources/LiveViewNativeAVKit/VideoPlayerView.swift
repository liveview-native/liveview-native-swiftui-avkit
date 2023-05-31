import SwiftUI
import AVKit
import AVFoundation
import Combine
import LiveViewNative

class VideoPlayerObserver<R: RootRegistry>: ObservableObject {
    @Published var timeControlStatus: AVPlayer.TimeControlStatus = .waitingToPlayAtSpecifiedRate
    @Published var timeControlStatusAsString: String = "waiting_to_play_at_specified_rate"

    var player: AVPlayer
    private var timeControlStatusObservation: AnyCancellable?

    init() {
        self.player = AVPlayer()
    }
}

struct VideoPlayerView<R: RootRegistry>: View {
    @ObservedElement private var element: ElementNode
    @LiveBinding(attribute: "time-control-status") private var timeControlStatus: String
    @LiveContext<R> private var context
    @StateObject private var observer: VideoPlayerObserver<R>
    var url: URL
    
    init(element: ElementNode) {
        if let urlAttr = element.attributeValue(for: "url") {
            self.url = URL(string: urlAttr)!
        } else {
            self.url = URL(string: "")!
        }
        _observer = StateObject(wrappedValue: VideoPlayerObserver())
    }

    var body: some View {
        VideoPlayer(player: self.observer.player)
            .onAppear {
                $timeControlStatus.wrappedValue = self.observer.timeControlStatusAsString

                self.observer.player.replaceCurrentItem(with: AVPlayerItem(url: url))
            }
            .onReceive(observer.player.publisher(for: \.timeControlStatus)) { status in
                switch (status) {
                case .paused:
                    timeControlStatus = "paused"
                case .playing:
                    timeControlStatus = "playing"
                case .waitingToPlayAtSpecifiedRate:
                    timeControlStatus = "waiting_to_play_at_specified_rate"
                @unknown default:
                    timeControlStatus = "unknown"
                }
            }
    }
    
    func pushTimeControlStatus(timeControlStatus: String) {
        $timeControlStatus.wrappedValue = timeControlStatus
    }
}
