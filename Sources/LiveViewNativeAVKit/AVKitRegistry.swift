//
//  AVKitRegistry.swift
//  LiveViewNativeAVKit
//
//  Created by May Matyi on 5/18/23.
//

import LiveViewNative
import LiveViewNativeStylesheet
import SwiftUI

/// The main LiveView Native registry for the LiveViewNativeAVKit add-on library.
///
/// Use this view in your LiveView view tree using the ``CustomRegistry`` (see <doc:AddCustomElement>).
#if swift(>=5.8)
@_documentation(visibility: public)
#endif
public struct AVKitRegistry<Root: RootRegistry>: CustomRegistry {
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
