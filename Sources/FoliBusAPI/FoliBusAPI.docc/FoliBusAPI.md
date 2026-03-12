# ``FoliBusAPI``

A Swift package for working with the Föli public transport APIs.

## Overview

`FoliBusAPI` provides async Swift interfaces for:

- SIRI stop monitoring and arrival data
- GTFS routes, stops, trips, stop times, and calendar dates
- Optional local caching for static GTFS resources
- SwiftUI-oriented service access through ``FoliService`` and client providers

The package is built around ``FoliClient``, which is an actor responsible for request execution, response decoding, in-flight deduplication, and cache coordination.

## Topics

### Essentials

- ``FoliClient``
- ``FoliService``
- ``FoliBusAPI``
- ``FoliClientConfiguration``
- ``FoliClientProviding``

### Transport and requests

- ``FoliTransport``
- ``URLSessionTransport``
- <doc:TransportAndTesting>

### Models and errors

- ``Foli``
- ``Foli/APIError``
- ``FoliArrivalResponse``

### Articles

- <doc:GettingStarted>
- <doc:TransportAndTesting>
