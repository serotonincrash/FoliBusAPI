# Getting started with FoliBusAPI

## Overview

Use ``FoliClient`` when you want direct control over caching and transport behavior, or use the higher-level ``FoliBusAPI`` convenience API for simple access.

## Create a client

```swift
import FoliBusAPI

let client = FoliClient(
    cacheBehavior: .forceRefresh,
    cacheTimeout: .default
)
```

## Fetch routes

```swift
let routes = try await client.fetchRoutes()
```

## Fetch arrivals (stop monitoring)

```swift
let arrivals = try await client.fetchArrivals(for: "1000")
```

## Use the convenience facade

If you don't need to manage a client directly, use ``FoliBusAPI`` static entry points:

```swift
let routes = try await FoliBusAPI.fetchRoutes()
let arrivals = try await FoliBusAPI.fetchArrivals(for: "1000")
```

## Choose a cache behavior

For GTFS-backed resources, cache behavior is configured when creating the client.

```swift
let client = FoliClient(cacheBehavior: .staleWhileRevalidate)
```

Common choices:

- ``Foli/CacheBehavior/cachedOrFetch`` for a normal cache-first strategy
- ``Foli/CacheBehavior/staleWhileRevalidate`` for fast UI reads plus background refresh
- ``Foli/CacheBehavior/forceRefresh`` when freshness matters most
- ``Foli/CacheBehavior/noCache`` for deterministic tests or one-off reads

When using ``Foli/CacheBehavior/staleWhileRevalidate``, the client serves the currently cached value immediately and kicks off a best-effort background refresh. If metadata revalidation fails transiently, the stale cached value remains usable until a later refresh succeeds.

## SwiftUI integration

If you're integrating into SwiftUI, inject a client provider and use the ``FoliService`` property wrapper to resolve a client from the environment.

```swift
import SwiftUI
import FoliBusUI

@main
struct DemoApp: App {
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

## Inject an explicit client into SwiftUI

```swift
import SwiftUI
import FoliBusUI

struct ContentView: View {
    let client = FoliClient(cacheBehavior: .cachedOrFetch)
    @FoliService(client: client) var foliService

    var body: some View {
        Text("Foli service ready")
    }
}
```

## Next steps

- Read <doc:TransportAndTesting> for transport injection and testing strategy
- Explore ``FoliClient`` for the full async API surface
- Explore ``FoliBusAPI`` for shared convenience entry points
