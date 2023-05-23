//
//  LVNVideoPlayer.swift
//  Scratchboard
//
//  Created by May Matyi on 5/22/23.
//

import SwiftUI
import LiveViewNative
import AVKit

#if swift(>=5.8)
@_documentation(visibility: public)
#endif
struct LVNVideoPlayer: View {
    var element: ElementNode

    public var body: some View {
        if let url = element.attributeValue(for: "url") {
            VideoPlayer(player: AVPlayer(url:  URL(string: url)!))
        } else {
            VideoPlayer(player: nil)
        }
    }
}
