# SwiftUI integration

## Overview

`FoliBusUI` is the SwiftUI layer of the package. It provides the ``FoliService`` property wrapper, the `\.foliClientProvider` environment key, and SwiftUI-friendly extensions on models such as ``Foli/Route/color``. Together they make it easy to load transit data into views while keeping client configuration at the app root.

## Set up the environment

Configure a provider at the root of your app so every view can resolve the same ``FoliClient`` instance through the environment.

```swift
import SwiftUI
import FoliBusUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    \.foliClientProvider,
                    DefaultFoliClientProvider(
                        configuration: FoliClientConfiguration(
                            cacheBehavior: .staleWhileRevalidate,
                            cacheTTL: .default
                        )
                    )
                )
        }
    }
}
```

`DefaultFoliClientProvider` conforms to ``FoliClientProviding`` and reuses a single client, so you don't create a new client for every view.

## Use @FoliService in views

Once the environment is configured, add ``FoliService`` to any view.

```swift
import SwiftUI
import FoliBusAPI
import FoliBusUI

struct RoutesView: View {
    @FoliService var foliService

    @State private var routes: [Foli.Route] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading routes...")
                } else if let errorMessage {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                } else {
                    List(routes) { route in
                        RouteRow(route: route)
                    }
                }
            }
            .navigationTitle("Routes")
            .task {
                await loadRoutes()
            }
        }
    }

    private func loadRoutes() async {
        isLoading = true
        errorMessage = nil
        do {
            routes = try await foliService.fetchRoutes()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
```

## Inject an explicit client

If a view needs a different client (for example, a preview or a screen that always refreshes), pass one directly to the property wrapper.

```swift
struct ArrivalsView: View {
    let stopId: String

    @FoliService(client: FoliClient(cacheBehavior: .forceRefresh)) var foliService

    @State private var arrivals: [Foli.Arrival] = []

    var body: some View {
        List(arrivals) { arrival in
            Text("\(arrival.lineRef) - \(arrival.destinationDisplay)")
        }
        .task {
            arrivals = (try? await foliService.fetchArrivals(for: stopId)) ?? []
        }
    }
}
```

An explicit client always takes precedence over the environment provider for that view.

## Common patterns

### Loading a list

Use `.task` so loading starts when the view appears and is cancelled when it disappears.

```swift
struct StopsView: View {
    @FoliService var foliService
    @State private var stops: [Foli.Stop] = []

    var body: some View {
        List(stops) { stop in
            VStack(alignment: .leading) {
                Text(stop.name)
                    .font(.headline)
                if let coordinate = stop.location {
                    Text("\(coordinate.latitude), \(coordinate.longitude)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            stops = (try? await foliService.fetchStops()) ?? []
        }
    }
}
```

### Displaying arrivals

```swift
struct StopDetailView: View {
    let stop: Foli.Stop
    @FoliService var foliService
    @State private var arrivals: [Foli.Arrival] = []

    var body: some View {
        List(arrivals) { arrival in
            HStack {
                Text(arrival.lineRef)
                    .font(.headline)
                    .frame(width: 40, alignment: .leading)
                Text(arrival.destinationDisplay)
                Spacer()
                Text(arrival.formattedTimeUntilArrival())
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(stop.name)
        .task(id: stop.id) {
            await loadArrivals()
        }
    }

    private func loadArrivals() async {
        do {
            arrivals = try await foliService.fetchArrivals(for: stop.id)
        } catch {
            arrivals = []
        }
    }
}
```

### Route colors

``Foli/Route`` exposes `color` and `textColor` as SwiftUI ``Color`` values when the route includes hex colors.

```swift
struct RouteRow: View {
    let route: Foli.Route

    var body: some View {
        HStack {
            Text(route.shortName)
                .font(.headline)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(route.color ?? .gray)
                .foregroundStyle(route.textColor ?? .white)
                .clipShape(Capsule())

            Text(route.displayName)
                .lineLimit(1)

            Spacer()
        }
    }
}
```

## State management with .task

SwiftUI's `.task` is the simplest way to tie a view's lifetime to an async operation. It automatically cancels the task when the view disappears and restarts it when the dependency given to `.task(id:)` changes.

For data that should refresh periodically while the view is visible, combine `.task` with a timer:

```swift
struct LiveArrivalsView: View {
    let stopId: String
    @FoliService var foliService
    @State private var arrivals: [Foli.Arrival] = []

    var body: some View {
        List(arrivals) { arrival in
            ArrivalRow(arrival: arrival)
        }
        .task(id: stopId) {
            await refreshLoop()
        }
    }

    private func refreshLoop() async {
        while !Task.isCancelled {
            do {
                arrivals = try await foliService.fetchArrivals(for: stopId)
            } catch {
                arrivals = []
            }
            try? await Task.sleep(for: .seconds(30))
        }
    }
}
```

Because `.task` cancels on disappearance, the refresh loop stops automatically when the user navigates away.

## Error handling in views

``FoliClient`` throws ``Foli/APIError`` for network, decoding, and lookup failures, and ``Foli/CacheError`` for cache-specific problems such as a `.cacheMiss` with ``Foli/CacheBehavior/cachedOnly``. In views you usually want to present a friendly message:

```swift
private func load() async {
    do {
        routes = try await foliService.fetchRoutes()
        errorMessage = nil
    } catch let error as Foli.APIError {
        errorMessage = "Transit data unavailable: \(error.localizedDescription)"
    } catch let error as Foli.CacheError {
        errorMessage = "Cache error: \(error.localizedDescription)"
    } catch {
        errorMessage = "Unexpected error: \(error.localizedDescription)"
    }
}
```

For read-only views, `(try? await foliService.fetchStops()) ?? []` is often enough.

## Background and foreground lifecycle

Data loaded into `@State` is part of the view's state and survives backgrounding on iOS. If you need to refresh when the app returns to the foreground, observe `scenePhase`:

```swift
struct ContentView: View {
    @FoliService var foliService
    @Environment(\.scenePhase) private var scenePhase
    @State private var arrivals: [Foli.Arrival] = []
    let stopId = "1000"

    var body: some View {
        List(arrivals) { ArrivalRow(arrival: $0) }
            .task(id: stopId) {
                await loadArrivals()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await loadArrivals() }
                }
            }
    }

    private func loadArrivals() async {
        arrivals = (try? await foliService.fetchArrivals(for: stopId)) ?? []
    }
}
```

## Testing with mock providers

The environment seam makes previews and tests easy. Create a lightweight provider that returns a fixed client, or a custom transport that serves fixture data.

```swift
struct MockFoliClientProvider: FoliClientProviding {
    private let sharedClient: FoliClient

    init(transport: FoliTransport) {
        self.sharedClient = FoliClient(transport: transport, cacheBehavior: .noCache)
    }

    func client() -> FoliClient { sharedClient }
}
```

Use it in a preview:

```swift
#Preview {
    RoutesView()
        .environment(
            \.foliClientProvider,
            MockFoliClientProvider(transport: FixtureTransport())
        )
}
```

For more on mock transports and fixture-based testing, see the Transport and testing article in the `FoliBusAPI` documentation.
