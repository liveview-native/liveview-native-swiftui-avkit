# AVKit for LiveView Native SwiftUI

`liveview-native-swiftui-avkit` is an add-on library for [LiveView Native](https://github.com/liveview-native/live_view_native). It adds [AVKit](https://developer.apple.com/documentation/avkit) support for video playback and other audiovisual capabilities.

## Installation

1. In Xcode, select *File → Add Packages...*
2. Enter the package URL `https://github.com/liveview-native/liveview-native-swiftui-avkit`
3. Select *Add Package*

## Usage

Import `LiveViewNativeAVKit` and add the `AVKitRegistry` to the list of addons on your `LiveView`:

```swift
import SwiftUI
import LiveViewNative
import LiveViewNativeAVKit

struct ContentView: View {
    var body: some View {
        #LiveView(
            .localhost,
            addons: [AVKitRegistry<_>.self]
        )
    }
}
```

Now you can use the `VideoPlayer` element in your template.

<table>

<tr>
<td>

```html
<VideoPlayer
  url="videos/sample.mov"
  autoplay
  isMuted
  playbackTime={28}
  phx-debounce={1000}
  phx-change="player-changed"
/>
```
</td>

<td>
<img src="./docs/example.png" alt="LiveView Native AVKit screenshot" width="300" />
</td>

</tr>

</table>

## Learn more

You can view documentation on the elements and attributes in this addon from Xcode:

1. In Xcode, select *Product → Build Documentation* in the menu bar
2. Select *Window → Developer Documentation* (Xcode should open this for you after the documentation is built)
3. Select *LiveViewNativeAVKit* in the sidebar