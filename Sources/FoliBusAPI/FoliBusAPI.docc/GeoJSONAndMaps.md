# GeoJSON and maps

## Overview

In addition to GTFS transit data, the Föli API publishes geographic information as GeoJSON. `FoliBusAPI` models GeoJSON responses with ``Foli/FeatureCollection``, ``Foli/Feature``, ``Foli/Geometry``, and ``Foli/FeatureProperties``. Layer metadata is represented by ``Foli/GeoJSONLayer``.

This article covers how to discover layers, fetch points of interest and service boundaries, and bridge the data to MapKit.

## GeoJSON types

A ``Foli/FeatureCollection`` is the top-level response for all geographic endpoints. It contains an array of ``Foli/Feature`` values, each combining a ``Foli/Geometry`` with ``Foli/FeatureProperties`` metadata.

``Foli/Geometry`` supports three shapes:

- ``Foli/Geometry/point(_:)`` &mdash; a single `[longitude, latitude]` coordinate.
- ``Foli/Geometry/multiPolygon(_:)`` &mdash; area boundaries.
- ``Foli/Geometry/multiLineString(_:)`` &mdash; linear boundaries.

Properties carry names in Finnish, Swedish, and English, plus a category, address, popup HTML, and optional icon.

```swift
import FoliBusAPI

let client = try FoliClient(cacheBehavior: .cachedOrFetch)
let poi = try await client.fetchPointsOfInterest()

for feature in poi.features {
    let name = feature.properties.localizedName(language: "en") ?? "Unnamed"
    let category = feature.properties.category ?? "unknown"
    print("\(category): \(name)")
}
```

## Fetch layer metadata

Call ``FoliClient/fetchGeoJSONLayers()`` to see which layers are available and where to fetch them.

```swift
let layers = try await client.fetchGeoJSONLayers()

for layer in layers {
    print("Layer: \(layer.name.en)")
    print("URL: \(layer.httpsURL)")
}
```

Each ``Foli/GeoJSONLayer`` includes a localized name (``Foli/GeoJSONLayer/LayerName``) and display metadata (``Foli/GeoJSONLayer/LayerMetadata``) that tells you which property keys hold the feature name and popup content.

## Points of interest

Fetch every POI, or filter by category.

```swift
// All points of interest
let allPOIs = try await client.fetchPointsOfInterest()

// Filtered by category (e.g., service points)
let servicePoints = try await client.fetchPointsOfInterest(inCategory: "service_points")
```

For point features, you can extract a ``Foli/Coordinate`` directly:

```swift
let coordinate = feature.coordinate
```

This uses ``Foli/Feature/coordinate``, which returns `nil` if the geometry is not a valid `Point`.

## Service boundaries

``FoliClient/fetchServiceBounds(resolution:format:)`` returns the geographic area served by Föli. Choose a resolution and geometry format that fit your use case.

```swift
let compact = try await client.fetchServiceBounds(resolution: .compact, format: .multiPolygon)
let precise = try await client.fetchServiceBounds(resolution: .strict, format: .multiPolygon)
let outline = try await client.fetchServiceBounds(resolution: .normal, format: .multiLineString)
```

Resolutions:

- ``FoliClient/BoundsResolution/strict`` &mdash; precise municipal boundaries, larger payload.
- ``FoliClient/BoundsResolution/normal`` &mdash; balanced resolution for general use.
- ``FoliClient/BoundsResolution/compact`` &mdash; mobile-friendly, smallest payload.

Formats:

- ``FoliClient/BoundsFormat/multiPolygon`` &mdash; polygon area.
- ``FoliClient/BoundsFormat/multiLineString`` &mdash; linear outline.

## MapKit integration

``Foli/Coordinate`` converts directly to `CLLocationCoordinate2D` via ``Foli/Coordinate/toCLCoordinate()``.

```swift
import MapKit

let coordinate = Foli.Coordinate(latitude: 60.4518, longitude: 22.2666)
let clCoordinate = coordinate.toCLCoordinate()

let annotation = MKPointAnnotation()
annotation.coordinate = clCoordinate
annotation.title = "Kauppatori"
```

### Annotations from POI features

```swift
func annotations(from features: [Foli.Feature]) -> [MKPointAnnotation] {
    features.compactMap { feature in
        guard let coordinate = feature.coordinate?.toCLCoordinate() else { return nil }
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = feature.properties.localizedName(language: "en")
        annotation.subtitle = feature.properties.address
        return annotation
    }
}

let pois = try await client.fetchPointsOfInterest(inCategory: "bike_parking")
let annotations = annotations(from: pois.features)
```

### Boundaries as overlays

Convert a `MultiPolygon` feature into `MKPolygon` overlays:

```swift
func polygons(from feature: Foli.Feature) -> [MKPolygon] {
    guard case .multiPolygon(let multiPolygon) = feature.geometry else { return [] }

    return multiPolygon.flatMap { polygon in
        polygon.map { ring in
            let coordinates = ring.map {
                CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
            }
            return MKPolygon(coordinates: coordinates, count: coordinates.count)
        }
    }
}

let bounds = try await client.fetchServiceBounds(resolution: .normal, format: .multiPolygon)
let overlays = bounds.features.flatMap { polygons(from: $0) }
```

For `MultiLineString` results, use `MKPolyline` instead:

```swift
func polylines(from feature: Foli.Feature) -> [MKPolyline] {
    guard case .multiLineString(let multiLineString) = feature.geometry else { return [] }

    return multiLineString.map { line in
        let coordinates = line.map {
            CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
        }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}
```

## Building polylines from shape points

GTFS shapes are ordered ``Foli/ShapePoint`` values, keyed by shape ID. Resolve a route's shape IDs first, then convert the points into `CLLocationCoordinate2D` and render them as an `MKPolyline`.

```swift
let shapeIds = try await client.fetchShapeIds(forRoute: route.id)
let points = try await client.fetchShapePoints(forShape: shapeIds[0])

let coordinates = points.map {
    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
}

let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
```

To select the most representative shape for a route, use ``FoliClient/fetchMostCommonShapeId(forRoute:)``:

```swift
if let shapeId = try await client.fetchMostCommonShapeId(forRoute: route.id) {
    let points = try await client.fetchShapePoints(forShape: shapeId)
    let coordinates = points.map {
        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
    let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
}
```

## Putting it together

A simple MapKit view can combine service bounds, POIs, and route shapes:

```swift
import SwiftUI
import MapKit
import FoliBusAPI

struct TransitMapView: View {
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 60.45, longitude: 22.27),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    var body: some View {
        Map(position: $cameraPosition) {
            // Add annotations, polylines, and overlays here
        }
        .mapStyle(.standard)
    }
}
```

Use ``Foli/Coordinate/toCLCoordinate()`` whenever you need to move from `FoliBusAPI` model coordinates to MapKit coordinates, whether for stops, POIs, shapes, or boundary geometry.
