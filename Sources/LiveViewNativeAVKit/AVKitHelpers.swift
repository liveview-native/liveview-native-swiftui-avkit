//
//  AVKitHelpers.swift
//
//
//  Created by May Matyi on 6/7/23.
//

import AVFoundation
import AVKit

class AVKitHelpers {
    static func floatToStride(float: Float64) -> RunLoop.SchedulerTimeType.Stride {
        return RunLoop.SchedulerTimeType.Stride(float)
    }

    static func floatToCMTime(float: Float64) -> CMTime {
        return CMTimeMakeWithSeconds(float, preferredTimescale: 1)
    }
}
