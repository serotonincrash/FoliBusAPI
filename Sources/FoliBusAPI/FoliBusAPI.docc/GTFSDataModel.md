# GTFS data model

## Overview

The Föli API exposes static transit data in the shape of the [General Transit Feed Specification](https://gtfs.org) (GTFS). `FoliBusAPI` models the most common GTFS entities under the ``Foli`` namespace, keeping field names close to the raw feed so documentation and upstream data line up.

The core graph is straightforward:

- An ``Foli/Agency`` operates one or more ``Foli/Route`` values.
- Each route has many ``Foli/Trip`` values, representing individual vehicle runs.
- A trip stops at several ``Foli/Stop`` values, ordered by ``Foli/StopTime`` entries.
- Trips are scheduled by a ``Foli/Calendar`` (weekly pattern) and optional ``Foli/CalendarDate`` exceptions.
- Trips and routes reference ``Foli/ShapePoint`` values for map geometry.

This article explains those relationships and shows how to fetch and navigate related data with ``FoliClient``.

## Agency → Route → Trip → StopTime → Stop

The GTFS feed is relational: entities reference each other by identifier rather than being nested.

```swift
import FoliBusAPI

let client = FoliClient(cacheBehavior: .cachedOrFetch)

// 1. Start with the agency.
let agencies = try await client.fetchAgencies()

// 2. List routes for an agency.
let routes = try await client.fetchRoutes()
let agencyRoutes = routes.filter { $0.agencyId == agencies.first?.id }

// 3. Pick a route and fetch its trips.
let route = agencyRoutes.first!
let trips = try await client.fetchTrips(forRoute: route.id)

// 4. For a trip, fetch its stop times.
let trip = trips.first!
let stopTimes = try await client.fetchStopTimes(forTrip: trip.tripId)

// 5. Resolve the actual stops.
let stopIds = stopTimes.compactMap { $0.stopId }
let allStops = try await client.fetchStops()
let tripStops = allStops.filter { stopIds.contains($0.id) }
```

Common identifiers:

- ``Foli/Route/id`` matches ``Foli/Trip/routeId``.
- ``Foli/Trip/serviceId`` matches ``Foli/Calendar/id`` and ``Foli/CalendarDate/serviceId``.
- ``Foli/Trip/shapeId`` matches ``Foli/ShapePoint/shapeId``.
- ``Foli/StopTime/tripId`` matches ``Foli/Trip/tripId``.
- ``Foli/StopTime/stopId`` matches ``Foli/Stop/id``.

## Routes

``Foli/Route`` carries the line metadata passengers usually see first: ``Foli/Route/shortName``, ``Foli/Route/longName``, and optional ``Foli/Route/colorHex`` / ``Foli/Route/textColorHex`` for display. Use ``Foli/Route/displayName`` or ``Foli/Route/fullDisplayName`` when you need a consistent label.

```swift
let routes = try await client.fetchRoutes()
let buses = routes.filter(\.isBus)
let sorted = buses.sorted { $0.shortName < $1.shortName }
```

## Trips

A ``Foli/Trip`` is one vehicle run along a route. It carries the headsign (``Foli/Trip/tripHeadsign``), direction (``Foli/Trip/directionId``), and references the service calendar and shape.

```swift
let trips = try await client.fetchTrips(forRoute: route.id)
let outbound = trips.filter { $0.directionId == 0 }
let inbound = trips.filter { $0.directionId == 1 }
```

To find the most representative shape ID for a route, use the helper on ``FoliClient``:

```swift
let shapeId = try await client.fetchMostCommonShapeId(forRoute: route.id)
// Shape points are fetched by route ID.
let points = try await client.fetchShapePoints(forRoute: route.id)
```

## Stop times

``Foli/StopTime`` is the timetable entry that joins a trip to a stop. Times are strings in `HH:MM:SS` format and may exceed `24:00:00` for trips that cross midnight.

```swift
let stopTimes = try await client.fetchStopTimes(forTrip: trip.tripId)
let ordered = stopTimes.sorted { $0.stopSequence < $1.stopSequence }

for entry in ordered {
    print("\(entry.stopSequence): \(entry.arrivalTime) - \(entry.departureTime)")
}
```

## Stops and collection helpers

``Foli/Stop`` holds the passenger-facing stop name, coordinates, zone, and accessibility information. The ``Foli/Stop/location`` property returns a ``Foli/Coordinate`` when both latitude and longitude are present.

The package adds helpers to any `Collection` of stops via `FoliStop+Collections.swift`:

```swift
let stops = try await client.fetchStops()

// Search by name or ID
let results = stops.search("Kauppatori")

// Only stops with coordinates
let located = stops.withLocation()

// Group by fare zone
let byZone = stops.groupedByZone()

// Nearest stops to a coordinate
let here = Foli.Coordinate(latitude: 60.4518, longitude: 22.2666)
let nearest = stops.nearest(to: here)
let nearby = stops.sortedByDistance(from: here).prefix(10)

// Filter to a bounding box
let box = stops.within(latRange: 60.4...60.5, lonRange: 22.2...22.3)
```

## Calendars and calendar dates

``Foli/Calendar`` describes the weekly operating pattern for a service ID, with boolean flags for each day and a date range (`YYYYMMDD`) that the pattern is valid for. ``Foli/CalendarDate`` adds exceptions: service added or removed on a specific date.

```swift
let calendars = try await client.fetchCalendars()
let calendarDates = try await client.fetchCalendarDates()

let serviceId = trip.serviceId
let calendar = calendars.first { $0.id == serviceId }

let exceptions = calendarDates.filter { $0.serviceId == serviceId }
let added = exceptions.filter(\.isServiceAdded)
let removed = exceptions.filter(\.isServiceRemoved)
```

Both ``Foli/Calendar/startDate`` / ``Foli/Calendar/endDate`` and ``Foli/CalendarDate/date`` parse the raw `YYYYMMDD` string into a `Date` when valid.

## Shapes and route geometry

Route geometry is stored as ordered ``Foli/ShapePoint`` values grouped by `shapeId`. Use ``FoliClient/fetchShapeRouteIDs()`` to discover which routes have shapes, then fetch the points by route or by shape ID.

```swift
let routesWithShapes = try await client.fetchShapeRouteIDs()

for routeId in routesWithShapes.prefix(5) {
    let points = try await client.fetchShapePoints(forRoute: routeId)
    print("Route \(routeId): \(points.count) shape points")
}
```

For a single representative polyline per route, combine the shape helpers:

```swift
_ = try await client.fetchMostCommonShapeId(forRoute: route.id)
let points = try await client.fetchShapePoints(forRoute: route.id)
let coordinates = points.map { Foli.Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
```

See <doc:GeoJSONAndMaps> for turning shapes and other geographic data into MapKit annotations and overlays.

## Data freshness: static vs real-time

The Föli API mixes two kinds of data:

- **Static GTFS data** (routes, stops, trips, stop times, calendars, shapes) changes rarely and is a good fit for caching. Use ``Foli/CacheBehavior/cachedOrFetch`` or ``Foli/CacheBehavior/staleWhileRevalidate`` to avoid re-downloading large feeds on every launch.
- **Real-time data** (arrivals, vehicle monitoring, service alerts) is time-sensitive and should usually be fetched fresh. Use ``Foli/CacheBehavior/forceRefresh`` or ``Foli/CacheBehavior/noCache`` for these endpoints.

The same client can be reused for both; the cache behavior only applies to cacheable GTFS resources. For more on cache policies and transport injection, see <doc:TransportAndTesting>.
