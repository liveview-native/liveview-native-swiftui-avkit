import SwiftUI
import AVKit
import AVFoundation
import Combine
import LiveViewNative

class VideoPlayerObserver: ObservableObject {
    @Published var timeControlStatus: AVPlayer.TimeControlStatus = .waitingToPlayAtSpecifiedRate

    private var player: AVPlayer
    private var timeControlStatusObservation: AnyCancellable?

    init(player: AVPlayer) {
        self.player = player

        observeTimeControlStatus()
    }

    private func observeTimeControlStatus() {
        timeControlStatusObservation = player
            .publisher(for: \.timeControlStatus)
            .sink { [weak self] status in
                self?.timeControlStatus = status

                print("timeControlStatus updated: \(status.rawValue)")
            }
    }

    deinit {
        timeControlStatusObservation?.cancel()
    }
}

struct VideoPlayerView<R: RootRegistry>: View {
    @ObservedElement private var element: ElementNode
    @LiveBinding(attribute: "time-control-status") private var timeControlStatus: String
    @LiveContext<R> private var context
    @StateObject private var observer: VideoPlayerObserver
    var url: URL
    private let player: AVPlayer
    
    init(element: ElementNode) {
        let player = AVPlayer()

        if let urlAttr = element.attributeValue(for: "url") {
            self.url = URL(string: urlAttr)!
        } else {
            self.url = URL(string: "")!
        }
        self.player = player
        _observer = StateObject(wrappedValue: VideoPlayerObserver(player: player))
    }

    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .onAppear {
                    testAction()
                    player.replaceCurrentItem(with: AVPlayerItem(url: url))
                }
                .onReceive($element) {
                    print("onReceive")
                }
            Button(action: testAction) {
                Text("Set State")
            }
        }
    }
    
    func testAction() {
        $timeControlStatus.wrappedValue = "foo"
    }
}
