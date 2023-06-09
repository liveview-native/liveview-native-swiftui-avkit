//
//  AVKitHelpers.swift
//
//
//  Created by May Matyi on 6/7/23.
//

import AVFoundation
import AVKit

/// Helper functions for converting LiveViewNative compatible types to AVKit types
/// and vice versa.
#if swift(>=5.8)
@_documentation(visibility: public)
#endif
class AVKitHelpers {
    static func floatToStride(float: Float64) -> RunLoop.SchedulerTimeType.Stride {
        return RunLoop.SchedulerTimeType.Stride(float)
    }

    static func floatToCMTime(float: Float64) -> CMTime {
        return CMTimeMakeWithSeconds(float, preferredTimescale: 1)
    }
}
