# Caching strategies

## Overview

`FoliClient` caches GTFS static resources (routes, stops, trips, stop times, shapes, agencies, calendars, and GeoJSON data) to reduce network traffic and improve responsiveness. Real-time SIRI data (arrivals, vehicle locations, alerts) is never persisted — only deduplicated in flight.

Caching is configured along two axes:

- ``Foli/CacheBehavior`` controls *when* cached data is used versus fetched from the network
- ``Foli/CacheTTL`` controls *how long* cached data remains fresh

## How caching works

### Disk cache

The package ships with ``Foli/DiskCache``, an actor-isolated file-based cache that stores serialized resources under the application support directory. The cache is initialized automatically when you create a ``FoliClient`` — if disk access is unavailable (e.g., sandbox restrictions), the client falls back to `.noCache` behavior transparently.

```swift
let client = FoliClient(
    cacheBehavior: .cachedOrFetch,
    cacheTTL: .default
)
```

### Resource keys

Every cacheable resource is identified by a ``Foli/Resource`` case:

```swift
// Each fetch method maps to a resource key
let routes = try await client.fetchRoutes()      // .routes
let stops = try await client.fetchStops()        // .stops
let trips = try await client.fetchTrips()        // .trips
```

Resource keys are distinct from ``Foli/DedupeKey``, which identifies in-flight requests for deduplication. Resource keys persist across app launches; deduplication keys exist only for the lifetime of a request.

### Dataset metadata

The Föli API publishes GTFS data as versioned datasets. The cache tracks which dataset ID was used for each cached resource and can revalidate whether the dataset is still current without re-downloading the full payload.

## Cache behaviors

``Foli/CacheBehavior`` determines the balance between data freshness and network efficiency.

### cachedOrFetch

The default behavior. Returns cached data if available and still valid (according to ``Foli/CacheTTL``); otherwise fetches from the network and updates the cache.

```swift
let client = FoliClient(cacheBehavior: .cachedOrFetch)

// First call: network fetch, cache write
// Subsequent calls (within TTL): cache hit, no network
// After TTL expires: network fetch, cache update
let routes = try await client.fetchRoutes()
```

**When to use:** General-purpose caching where you want to avoid redundant network calls but ensure data doesn't become too stale.

### staleWhileRevalidate

Returns stale cached data immediately (even if expired) and kicks off a background refresh. The caller gets a fast response while the cache updates asynchronously.

```swift
let client = FoliClient(cacheBehavior: .staleWhileRevalidate)

// Returns cached data instantly, even if expired
// Background task fetches fresh data and updates cache
// Next call returns the updated data
let routes = try await client.fetchRoutes()
```

**Background refresh errors:** Since the refresh runs in the background, errors are not thrown to the caller. Register a handler to observe them:

```swift
await client.setOnBackgroundRefreshError { resource, error in
    logger.error("Background refresh failed for \(resource): \(error)")
}
```

**When to use:** UI that needs to display data quickly while ensuring eventual consistency. The stale data remains usable until a background refresh succeeds.

### forceRefresh

Always fetches from the network and updates the cache. Ignores any existing cached data.

```swift
let client = FoliClient(cacheBehavior: .forceRefresh)

// Always network fetch, always cache write
let routes = try await client.fetchRoutes()
```

**When to use:** User-initiated refresh actions, pull-to-refresh, or when freshness is critical.

### cachedOnly

Returns cached data if available and valid; throws ``Foli/CacheError/cacheMiss(_:)`` otherwise. Never makes network requests.

```swift
let client = FoliClient(cacheBehavior: .cachedOnly)

do {
    let routes = try await client.fetchRoutes()
} catch let error as Foli.CacheError {
    // No cached data available
    print("Cache miss: \(error.localizedDescription)")
}
```

**When to use:** Offline-first scenarios, airplane mode, or when you want to avoid network access entirely.

### noCache

Fetches from the network without reading or writing the cache. Bypasses caching entirely.

```swift
let client = FoliClient(cacheBehavior: .noCache)

// Always network fetch, no cache interaction
let routes = try await client.fetchRoutes()
```

**When to use:** Deterministic testing, one-off reads, or when caching is inappropriate.

### Behavior comparison

| Behavior | Reads Cache | Writes Cache | Network Call |
|----------|-------------|--------------|--------------|
| `cachedOrFetch` | Yes (if valid) | Yes | Only if needed |
| `staleWhileRevalidate` | Yes (even stale) | Yes | Background |
| `forceRefresh` | No | Yes | Always |
| `cachedOnly` | Yes (if valid) | No | Never |
| `noCache` | No | No | Always |

## Cache TTL (time to live)

``Foli/CacheTTL`` controls how long cached data remains fresh before requiring revalidation.

```swift
// Default: 24-hour validity
let client = FoliClient(cacheTTL: .default)

// Short-lived: 1-hour validity (useful during development)
let client = FoliClient(cacheTTL: .shortLived)

// Long-lived: 7-day validity (minimizes network traffic)
let client = FoliClient(cacheTTL: .longLived)

// Custom duration
let client = FoliClient(cacheTTL: .init(validityDuration: 2 * 60 * 60)) // 2 hours
```

**Choosing a TTL:** Shorter durations ensure fresher data but increase network usage. GTFS data typically updates daily, so `.default` (24 hours) is appropriate for most production use cases. Use `.shortLived` during development or when GTFS updates frequently.

## Dataset revalidation

When using `.staleWhileRevalidate`, the client performs a lightweight metadata check before downloading a full dataset. If the dataset ID hasn't changed, the cache is considered current and no download occurs.

```swift
// Internally, the client:
// 1. Fetches dataset metadata (small JSON)
// 2. Compares dataset ID with cached version
// 3. If unchanged: cache remains valid, no download
// 4. If changed: downloads new dataset, updates cache
```

This optimization means stale-while-revalidate rarely downloads full datasets when the underlying GTFS data hasn't changed.

## Cache management

### Clearing cache

Clear all cached data:

```swift
try await client.clearCache()
```

Clear a specific resource:

```swift
try await client.clearCache(for: .routes)
```

### Checking cache state

Check if valid cached data exists:

```swift
let hasCachedRoutes = await client.hasValidCache(for: .routes)
```

Get the age of cached data in seconds:

```swift
if let age = await client.cacheAge(for: .routes) {
    print("Routes cached \(Int(age / 60)) minutes ago")
}
```

Get the dataset ID being used:

```swift
if let datasetId = try await client.currentDatasetId(for: .routes) {
    print("Using dataset: \(datasetId)")
}
```

### Manual revalidation

Force a revalidation check without fetching the full resource:

```swift
let isStillCurrent = try await client.revalidateCache(for: .routes)
if !isStillCurrent {
    print("Dataset has been updated")
}
```

## Performance considerations

### Request deduplication

Concurrent calls to the same fetch method are automatically deduplicated. If two callers request `fetchRoutes()` simultaneously, only one network request is made and both receive the same result.

```swift
// Both calls share a single network request
async let routes1 = client.fetchRoutes()
async let routes2 = client.fetchRoutes()
let (r1, r2) = try await (routes1, routes2) // r1 === r2
```

### In-memory indexes

`FoliClient` maintains in-memory lookup dictionaries for fast entity resolution. When you fetch routes, stops, trips, agencies, or calendars, the client rebuilds indexes automatically:

```swift
// Fetch all stops (triggers index rebuild)
let stops = try await client.fetchStops()

// Later: O(1) lookup by ID
if let stop = await client.stop(for: "1234") {
    print(stop.name)
}
```

Index rebuilds are idempotent — if the data hasn't changed, no work is performed.

### Background refresh cancellation

When using `.staleWhileRevalidate`, if you request the same resource again before the background refresh completes, the previous refresh is cancelled and a new one starts. This prevents stale refresh tasks from accumulating.

### Large payloads

GTFS datasets (routes, stops, trips, stop times) can be large. JSON decoding runs on the cooperative thread pool rather than blocking the client's actor executor, keeping the client responsive.

### Disk cache initialization

If the disk cache fails to initialize (e.g., insufficient permissions, read-only filesystem), the client falls back to `.noCache` behavior automatically. This is logged but not thrown as an error.

## Error handling

Cache operations can throw two distinct error types:

- ``Foli/APIError`` — network, transport, decoding, or entity-lookup failures
- ``Foli/CacheError`` — cache-specific failures (`.cacheMiss` when using `.cachedOnly` and nothing is cached)

```swift
do {
    let routes = try await client.fetchRoutes()
} catch let error as Foli.APIError {
    // Network/transport/decoding error
    print("API error: \(error.localizedDescription)")
} catch let error as Foli.CacheError {
    // Cache-specific error
    print("Cache error: \(error.localizedDescription)")
}
```

## Next steps

- Read <doc:RealTimeData> for working with real-time SIRI data
- Read <doc:TransportAndTesting> for transport injection and testing strategy
- Explore ``FoliClient`` for the full async API surface
- See ``Foli/CacheBehavior`` for the complete cache policy reference
- See ``Foli/CacheTTL`` for TTL configuration options
