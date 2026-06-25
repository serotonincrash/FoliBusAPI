# ``FoliBusAPI``

A Swift package for working with the Föli public transport APIs.

## Overview

`FoliBusAPI` provides async Swift interfaces for:

- SIRI stop monitoring and arrival data
- GTFS routes, stops, trips, stop times, and calendar dates
- Optional local caching for static GTFS resources
- SwiftUI-oriented service access through ``FoliService`` (in the ``FoliBusUI`` target) and client providers

The package is built around ``FoliClient``, which is an actor responsible for request execution, response decoding, in-flight deduplication, and cache coordination. The ``FoliBusAPI`` static facade provides a convenient entry point backed by a configurable provider &mdash; replace it at app launch via ``FoliBusAPI/configure(_:)`` or reset it between tests via ``FoliBusAPI/reset()``.

## Topics

### Essentials

- ``FoliClient``
- ``FoliBusAPI``
- ``FoliClientConfiguration``
- ``FoliClientProviding``

### Transport and requests

- ``FoliTransport``
- <doc:TransportAndTesting>

### Models and errors

- ``Foli``
- ``Foli/APIError``

### Articles

- <doc:GettingStarted>
- <doc:TransportAndTesting>
