# liveview-native-avkit

## About

`liveview-native-avkit` is an add-on library for [LiveView Native](https://github.com/liveview-native/live_view_native). It adds [AVKit](https://developer.apple.com/documentation/avkit) support for video playback and other audiovisual capabilities.

## Usage

Add this library as a package to your LiveView Native application's Xcode project using its repo URL. Then, create an `AggregateRegistry` to include the provided `AVKitRegistry` within your native app builds:

```diff
import SwiftUI
import LiveViewNative
+ import LiveViewNativeAVKit
+ 
+ struct MyRegistry: CustomRegistry {
+     typealias Root = AppRegistries
+ }
+ 
+ struct AppRegistries: AggregateRegistry {
+     typealias Registries = Registry2<
+         MyRegistry,
+         AVKitRegistry<Self>
+     >
+ }

@MainActor
struct ContentView: View {
-     @StateObject private var session: LiveSessionCoordinator<EmptyRegistry> = {
+     @StateObject private var session: LiveSessionCoordinator<AppRegistries> = {
        var config = LiveSessionConfiguration()
        config.navigationMode = .enabled
        
        return LiveSessionCoordinator(URL(string: "http://localhost:4000/")!, config: config)
    }()

    var body: some View {
        LiveView(session: session)
    }
}
```

To render a video player within a SwiftUI HEEx template, use the `VideoPlayer` element with a `url`:

```elixir
defmodule MyAppWeb.AVKitLive do
  use Phoenix.LiveView
  use LiveViewNative.LiveView

  @impl true
  def render(%{platform_id: :swiftui} = assigns) do
    ~Z"""
    ~Z"""
    <VStack>
      <VideoPlayer url="http://127.0.0.1:4000/videos/sample.mp4" />
    </VStack>
    """swiftui
  end
end
```

![LiveView Native AVKit screenshot](./docs/example.png)

## Learn more

  * Official website: https://native.live
  * Docs: https://hexdocs.pm/live_view_native_platform
  * Source: https://github.com/liveviewnative/live_view_native_platform
