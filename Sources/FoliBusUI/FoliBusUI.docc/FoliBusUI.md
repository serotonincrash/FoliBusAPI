# ``FoliBusUI``

SwiftUI integration layer for the Föli transit API.

## Overview

`FoliBusUI` provides SwiftUI-friendly wrappers and extensions for consuming Föli transit data in your views. Use the ``FoliService`` property wrapper to access transit data with automatic environment-based client resolution.

### Quick Start

Set up the client provider at your app's root:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    \.foliClientProvider,
                    DefaultFoliClientProvider(
                        configuration: FoliClientConfiguration(cacheBehavior: .forceRefresh)
                    )
                )
        }
    }
}
```

Then use it in your views:

```swift
struct StopsView: View {
    @FoliService var foliService
    
    @State private var stops: [Foli.Stop] = []
    
    var body: some View {
        List(stops) { stop in
            Text(stop.name)
        }
        .task {
            stops = (try? await foliService.fetchStops()) ?? []
        }
    }
}
```

## Topics

### Essentials

- ``FoliService``

### Environment

- ``FoliClientProviding``
- ``DefaultFoliClientProvider``

### Model Extensions

- ``Foli/Route/color``
- ``Foli/Route/textColor``
