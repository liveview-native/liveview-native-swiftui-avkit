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
    /// An alias for the ``AvKit`` addon, with proper capitalization when using it as a type.
    public typealias AVKit = AvKit
    
    /// The main LiveView Native registry for the LiveViewNativeAVKit add-on library.
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
