# Getting started with FoliBusAPI

## Overview

The package ships two products: **`FoliBusAPI`** (core logic, pure Foundation) and **`FoliBusUI`** (SwiftUI integration). Import `FoliBusAPI` for direct client usage, or `FoliBusUI` for the `@FoliService` property wrapper. Both can be imported together.

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

The facade backs onto a configurable provider. Replace it at launch or reset it for testing:

```swift
// Configure with a custom provider at app launch
await FoliBusAPI.configure(MyCustomProvider())

// Reset between test cases
await FoliBusAPI.reset()
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
- ``Foli/CacheBehavior/cachedOnly`` for offline-first scenarios (fails if nothing is cached)
- ``Foli/CacheBehavior/noCache`` for deterministic tests or one-off reads

When using ``Foli/CacheBehavior/staleWhileRevalidate``, the client serves the currently cached value immediately and kicks off a best-effort background refresh. If metadata revalidation fails transiently, the stale cached value remains usable until a later refresh succeeds.

## Handle errors

Fetch methods throw two distinct error types depending on the failure:

- ``Foli/APIError`` &mdash; network, transport, decoding, or entity-lookup failures (`.networkError`, `.invalidResponse`, `.decodingError`, `.notFound`).
- ``Foli/CacheError`` &mdash; cache-specific failures (`.cacheMiss` when using `.cachedOnly` and nothing is cached).

```swift
do {
    let routes = try await client.fetchRoutes()
} catch let error as Foli.APIError {
    // Handle network/transport/decoding/lookup errors
    print("API error: \(error.localizedDescription)")
} catch let error as Foli.CacheError {
    // Handle cache-specific errors (e.g., .cacheMiss with .cachedOnly)
    print("Cache error: \(error.localizedDescription)")
}
```

## Concurrency

Concurrent calls to the same fetch method are automatically deduplicated &mdash; you don't need to implement your own request coalescing. If two callers request `fetchRoutes()` simultaneously, only one network request is made and both receive the same result.

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
- See ``Foli/CacheBehavior`` for the complete cache policy reference
- See ``Foli/APIError`` and ``Foli/CacheError`` for error handling details
