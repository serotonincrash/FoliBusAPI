# ``FoliBusAPI``

A Swift package for working with the Föli public transport APIs.

## Overview

`FoliBusAPI` provides async Swift interfaces for:

- SIRI stop monitoring and arrival data
- GTFS routes, stops, trips, stop times, and calendar dates
- Optional local caching for static GTFS resources
- SwiftUI-oriented service access through ``FoliService`` (in the ``FoliBusUI`` target) and client providers

The package is built around ``FoliClient``, an actor that coordinates request execution, caching, in-flight deduplication, and in-memory lookup indexes. Rather than owning all of this logic directly, `FoliClient` delegates to dedicated extracted types: ``FoliRequester`` (transport, URL construction, and JSON decoding), ``FoliDedup`` (request coalescing), ``FoliIndexes`` (entity lookup dictionaries), and ``FoliRefreshTracker`` (background refresh bookkeeping). The ``FoliBusAPI`` static facade provides a convenient entry point backed by a configurable provider &mdash; replace it at app launch via ``FoliBusAPI/configure(_:)`` or reset it between tests via ``FoliBusAPI/reset()``.

## Architecture

The package ships two products:

- **`FoliBusAPI`** &mdash; core logic target (pure Foundation). Contains ``FoliClient``, models, caching, transport, and the static facade. No SwiftUI dependency.
- **`FoliBusUI`** &mdash; SwiftUI integration target. Contains the `@FoliService` property wrapper, `EnvironmentValues` extension, and SwiftUI convenience extensions on models. Depends on `FoliBusAPI`.

Import `FoliBusAPI` for non-UI usage (server-side, CLI, tests), `FoliBusUI` for SwiftUI integration, or both.

## Topics

### Essentials

- ``FoliClient``
- ``FoliBusAPI``
- ``FoliClientConfiguration``
- ``FoliClientProviding``

### Caching

- ``Foli/CacheBehavior``
- ``Foli/CacheTimeout``
- ``Foli/Resource``

### Transport and requests

- ``FoliTransport``
- <doc:TransportAndTesting>

### Models and errors

- ``Foli``
- ``Foli/APIError``
- ``Foli/CacheError``
- ``Foli/DedupeKey``

### Articles

- <doc:GettingStarted>
- <doc:TransportAndTesting>
