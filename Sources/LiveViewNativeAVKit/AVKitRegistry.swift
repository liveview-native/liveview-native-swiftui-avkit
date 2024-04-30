//
//  AVKitRegistry.swift
//  LiveViewNativeAVKit
//
//  Created by May Matyi on 5/18/23.
//

import LiveViewNative
import LiveViewNativeStylesheet
import SwiftUI

public extension Addons {
    public typealias AVKit = AvKit
    
    /// The main LiveView Native registry for the LiveViewNativeAVKit add-on library.
    ///
    /// Use this view in your LiveView view tree using the ``CustomRegistry`` (see <doc:AddCustomElement>).
    #if swift(>=5.8)
    @_documentation(visibility: public)
    #endif
    @Addon
    public struct AvKit<Root: RootRegistry> {
        public enum TagName: String {
            case videoPlayer = "VideoPlayer"
        }
        
        public static func lookup(_ name: TagName, element: ElementNode) -> some View {
            switch name {
            case .videoPlayer:
                VideoPlayer<Root>()
            }
        }
    }
}
