# Real-time data

## Overview

The Föli API serves two categories of data:

- **GTFS static data** — routes, stops, trips, stop times, shapes, agencies, calendars, and GeoJSON layers. These change infrequently (typically daily) and are cacheable. See <doc:CachingStrategies> for details.
- **SIRI real-time data** — vehicle arrivals, live vehicle locations, and service alerts. These change every few seconds and are never cached to disk.

Real-time endpoints live on a separate base URL from GTFS endpoints and use the [SIRI](https://en.wikipedia.org/wiki/Service_Interface_for_Real_Time_Information) standard for public transit data exchange. The alerts endpoint uses a proprietary format with optional gzip compression.

This article covers the three real-time data categories and how to work with them effectively.

## Stop monitoring (arrivals)

Stop monitoring returns the next arrivals and departures at a specific stop. Each arrival includes planned (aimed) and estimated (expected) times, delay information, and the vehicle's current location.

### Fetching arrivals

```swift
let arrivals = try await client.fetchArrivals(for: "1000")
```

Stop IDs can also be passed as integers:

```swift
let arrivals = try await client.fetchArrivals(for: 1000)
```

The method returns `[Foli.Arrival]`, sorted by arrival time. If the server has no real-time data for the requested stop, the call throws ``Foli/APIError/serverError(_:)``.

### Understanding arrival times

Each ``Foli/Arrival`` carries both planned and estimated times:

```swift
let arrival = arrivals.first!

// Planned (schedule) times
let planned = arrival.aimedArrivalDate

// Estimated (real-time) times
let estimated = arrival.expectedArrivalDate

// Computed delay
let delay = arrival.arrivalDelay  // seconds (expected - aimed)
print(arrival.isLate)   // true if delay > 0
print(arrival.isOnTime) // true if delay == 0
print(arrival.isEarly)  // true if delay < 0
```

The raw `delay` property (an optional `Int` from the server) may not always be present. The computed ``Foli/Arrival/arrivalDelay`` property calculates the difference from `aimedArrivalTime` and `expectedArrivalTime` regardless.

### Time until arrival

```swift
let minutes = arrival.formattedTimeUntilArrival()
// "5 min", "Due", or "1h 15m"
```

### Vehicle location on arrivals

Some arrivals include the vehicle's current GPS coordinates:

```swift
if let location = arrival.location {
    print("Vehicle at \(location.latitude), \(location.longitude)")
}
```

The ``Foli/Arrival/monitored`` property indicates whether the vehicle produces real-time information. Unmonitored vehicles still appear in the results but only carry schedule data.

## Vehicle monitoring

Vehicle monitoring returns the current location and status of every active vehicle in the Föli transit system.

### Fetching all vehicles

```swift
let vehicles = try await client.fetchVehicleLocations()
```

This returns `[Foli.VehicleLocation]`, one per active vehicle. The response can be large — the VM endpoint returns all vehicles across the entire transit system.

> Important: The vehicle monitoring endpoint has high bandwidth usage. Use a minimum polling interval of 3 seconds.

### Filtering by line

Fetch vehicles for a single line:

```swift
let line14 = try await client.fetchVehicleLocations(for: "14")
```

Or multiple lines at once:

```swift
let lines = try await client.fetchVehicleLocations(for: ["14", "2A", "61"])
```

Both overloads fetch all vehicles and filter client-side. When tracking multiple lines, it is more efficient to call ``FoliClient/fetchVehicleLocations()`` once and filter the results yourself rather than calling the per-line overload multiple times:

```swift
let allVehicles = try await client.fetchVehicleLocations()
let lineRefSet: Set<String> = ["14", "2A"]
let filtered = allVehicles.filter { lineRefSet.contains($0.lineRef) }
```

### Working with vehicle data

Each ``Foli/VehicleLocation`` includes rich trip context:

```swift
let vehicle = vehicles.first!

// Location
print(vehicle.latitude, vehicle.longitude)

// Trip identity
print(vehicle.lineRef)            // e.g. "14"
print(vehicle.publishedLineName)  // e.g. "14"
print(vehicle.directionRef)       // "1" or "2"
print(vehicle.vehicleRef)         // unique vehicle ID

// Origin and destination
print(vehicle.originName)
print(vehicle.destinationName)
```

### Delay parsing

Vehicle delay is encoded as an ISO 8601 duration string (e.g., `"PT120S"`, `"-PT60S"`). Use the computed property to parse it:

```swift
if let seconds = vehicle.delayInSeconds {
    if vehicle.isLate {
        print("Running \(Int(seconds))s late")
    } else if vehicle.isEarly {
        print("Running \(Int(-seconds))s early")
    }
}
```

### Stop calls

Each vehicle carries arrays of previous and onward stop calls (``Foli/VehicleLocation/StopCall``):

```swift
// Previous stops the vehicle has already served
if let previous = vehicle.previousCalls {
    for call in previous {
        print("Stopped at \(call.stopPointName ?? call.stopPointRef)")
    }
}

// Upcoming stops
if let onward = vehicle.onwardCalls {
    for call in onward {
        print("Next: \(call.stopPointName ?? call.stopPointRef)")
    }
}
```

The next stop is also available directly on the vehicle:

```swift
if let nextStop = vehicle.nextStopPointName {
    print("Approaching \(nextStop)")
}
if let eta = vehicle.timeUntilNextStop() {
    print("ETA: \(Int(eta / 60)) minutes")
}
```

### Data validity

Each vehicle location carries a ``Foli/VehicleLocation/validUntilTime`` timestamp:

```swift
if !vehicle.isValid() {
    print("Stale vehicle data — refresh needed")
}
```

## Alerts and cancellations

The alerts system provides service messages, trip cancellations, and emergency notifications. Unlike SIRI endpoints, the alerts endpoint uses a separate base URL and may return gzip-compressed responses.

### Fetching alerts

Fetch all alerts (messages and cancellations together):

```swift
let response = try await client.fetchAlerts()
```

The ``Foli/AlertsResponse`` contains:

- ``Foli/AlertsResponse/messages`` — informational alerts
- ``Foli/AlertsResponse/cancellations`` — trip cancellations
- ``Foli/AlertsResponse/globalMessage`` — a system-wide message, if any
- ``Foli/AlertsResponse/emergencyMessage`` — an emergency override, if any

For narrower queries:

```swift
let messages = try await client.fetchAlertMessages()
let cancellations = try await client.fetchCancellations()
```

### Alert priority

Alerts use a numeric priority where lower values indicate higher importance. Alerts with priority at or below 100 are considered high-priority:

```swift
let important = response.highPriorityMessages
let sorted = response.messagesByPriority

for alert in response.messages where alert.isHighPriority {
    print("Important: \(alert.message)")
}
```

### Filtering alerts by route or stop

```swift
// Alerts affecting a specific route
let routeAlerts = response.messages(affectingRoute: "14")

// Alerts affecting a specific stop
let stopAlerts = response.messages(affectingStop: "1000")

// Cancellations affecting a specific stop
let cancelled = response.cancellations(affectingStop: "1000")
```

You can also check individual alerts:

```swift
if alert.affects(route: "14") {
    print("Route 14 is affected")
}
```

### Translations and localization

Alerts support multilingual content through ``Foli/AlertTranslation``:

```swift
let content = alert.localized(language: "en")
print(content.header ?? "No header")
print(content.message)
print(content.information ?? "")
```

If no translation exists for the requested language, the method falls back to the alert's default (Finnish) content.

### Alert timing

Alerts are valid during specific time periods:

```swift
for period in alert.activePeriods {
    print("Active from \(period.start) to \(period.end)")
}

if let timeUntilActive = alert.timeUntilActive() {
    print("Becomes active in \(Int(timeUntilActive / 60)) minutes")
}

if let timeUntilExpiry = alert.timeUntilExpiry() {
    print("Expires in \(Int(timeUntilExpiry / 60)) minutes")
}
```

The ``Foli/Alert/isActive`` property indicates whether the alert should be displayed at the current moment.

### Trip cancellations

``Foli/TripCancellation`` represents a cancelled trip:

```swift
for cancellation in response.cancellations {
    print("Line \(cancellation.line) cancelled at \(cancellation.departureDate)")
    print("Cause: \(cancellation.cause)")

    for stop in cancellation.activeStops {
        print("  Stop \(stop.stop) at \(stop.arrivalDate)")
    }
}
```

### Alert categories

Fetch category descriptions to interpret alert category tags:

```swift
let categories = try await client.fetchAlertCategories()
for category in categories {
    print("\(category.category): \(category.description(language: "en"))")
}
```

## Deduplication

All real-time fetch methods are automatically deduplicated through ``FoliDedup``. When multiple callers request the same resource concurrently, only one network request is made.

### How deduplication works

Each fetch method registers a ``Foli/DedupeKey`` before executing the network call:

- `fetchArrivals(for: "1000")` registers `.stopMonitoring("1000")`
- `fetchVehicleLocations()` registers `.vehicleMonitoring`
- `fetchAlerts()` registers `.alerts`

If a second caller requests the same key while the first request is still in flight, the second caller awaits the same underlying task instead of starting a new one.

```swift
// Both calls share a single network request
async let a = client.fetchArrivals(for: "1000")
async let b = client.fetchArrivals(for: "1000")
let (arrivalsA, arrivalsB) = try await (a, b)  // identical results
```

Different stop IDs produce different keys and do not share requests:

```swift
// These make separate network requests
async let a = client.fetchArrivals(for: "1000")
async let b = client.fetchArrivals(for: "2000")
```

### Implications for polling

Deduplication is safe for polling patterns. If a timer fires before the previous request completes, the second call simply awaits the existing request rather than duplicating it. This prevents request accumulation during slow network conditions.

> Important: Deduplication correctness for hung operations depends on the transport layer timing out (e.g., `URLSessionConfiguration.timeoutIntervalForRequest`). A never-completing request blocks every caller sharing the same key until the transport gives up. Configure appropriate timeouts at the transport or caller level.

## Polling strategies

Real-time data requires periodic polling since the Föli API does not provide push-based updates. Here are recommended patterns.

### Timer-based polling with AsyncStream

```swift
func pollArrivals(stopId: String, every interval: Duration) -> AsyncStream<[Foli.Arrival]> {
    AsyncStream { continuation in
        let task = Task {
            while !Task.isCancelled {
                do {
                    let arrivals = try await client.fetchArrivals(for: stopId)
                    continuation.yield(arrivals)
                } catch {
                    // Handle or log the error, continue polling
                    print("Poll error: \(error)")
                }
                try? await Task.sleep(for: interval)
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}
```

### Recommended polling intervals

| Endpoint | Minimum Interval | Notes |
|----------|-----------------|-------|
| Stop monitoring (`fetchArrivals`) | 5–10 seconds | Small payload per stop |
| Vehicle monitoring (`fetchVehicleLocations`) | 3 seconds | Large payload, high bandwidth |
| Alerts (`fetchAlerts`) | 30–60 seconds | Data changes infrequently |
| Alert messages (`fetchAlertMessages`) | 30–60 seconds | Subset of full alerts |
| Cancellations (`fetchCancellations`) | 30–60 seconds | Subset of full alerts |

### Lifecycle management

Start and stop polling based on view lifecycle:

```swift
struct StopView: View {
    @State private var arrivals: [Foli.Arrival] = []
    private let client = FoliClient()

    var body: some View {
        List(arrivals) { arrival in
            Text("\(arrival.lineRef) — \(arrival.formattedTimeUntilArrival())")
        }
        .task {
            while !Task.isCancelled {
                do {
                    arrivals = try await client.fetchArrivals(for: "1000")
                } catch {
                    break
                }
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }
}
```

The `.task` modifier automatically cancels the polling loop when the view disappears. The `Task.isCancelled` check exits the loop promptly.

### Polling multiple resources

When polling multiple endpoints, use separate tasks with independent intervals:

```swift
.task {
    // Poll arrivals every 10 seconds
    while !Task.isCancelled {
        if let arrivals = try? await client.fetchArrivals(for: "1000") {
            self.arrivals = arrivals
        }
        try? await Task.sleep(for: .seconds(10))
    }
}
.task {
    // Poll alerts every 60 seconds
    while !Task.isCancelled {
        if let alerts = try? await client.fetchAlertMessages() {
            self.alerts = alerts
        }
        try? await Task.sleep(for: .seconds(60))
    }
}
```

Deduplication ensures that even if multiple views poll the same endpoint, only one network request is made per polling cycle.

## Error handling

All real-time fetch methods throw ``Foli/APIError`` on failure. The two most common cases are:

- ``Foli/APIError/networkError(_:)`` — connection failure, timeout, or DNS error
- ``Foli/APIError/serverError(_:)`` — the server returned an error status

```swift
do {
    let vehicles = try await client.fetchVehicleLocations()
} catch let error as Foli.APIError {
    switch error {
    case .networkError(let underlying):
        print("Network failure: \(underlying)")
    case .serverError(let status):
        print("Server error: \(status)")
    default:
        print("Unexpected: \(error)")
    }
}
```

For polling loops, catch errors without breaking the loop so polling resumes on transient failures:

```swift
while !Task.isCancelled {
    do {
        let arrivals = try await client.fetchArrivals(for: "1000")
        handleArrivals(arrivals)
    } catch {
        print("Transient error, retrying next cycle: \(error)")
    }
    try? await Task.sleep(for: .seconds(10))
}
```

## Next steps

- Read <doc:CachingStrategies> for GTFS static data caching
- Read <doc:TransportAndTesting> for transport injection and testing strategy
- Explore ``FoliClient`` for the full async API surface
- See ``Foli/Arrival`` for the complete arrival model reference
- See ``Foli/VehicleLocation`` for the complete vehicle location model reference
- See ``Foli/Alert`` and ``Foli/TripCancellation`` for alert model details
