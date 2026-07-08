# Transport and testing

## Overview

`FoliClient` depends on ``FoliTransport`` rather than calling `URLSession` directly. This keeps request execution behind a small abstraction boundary:

- production code can use the `FoliClient(session:cacheBehavior:cacheTTL:)` convenience initializer that injects a `URLSession` for regular networking
- tests inject a lightweight mock transport
- request construction, response validation, and decoding live in ``FoliRequester``, which ``FoliClient`` delegates to

## Production usage

```swift
let client = FoliClient(session: .shared, cacheBehavior: .cachedOrFetch)
```

## When to inject a custom transport

Custom transports are useful when you want to:

- return deterministic fixture payloads in tests
- log or instrument outgoing requests
- route requests through an alternate networking layer
- isolate request execution from the rest of the client's decoding logic

## Testing transport

Tests in this package use an actor-backed mock transport to:

- return fixture data deterministically
- record outgoing requests for assertions
- avoid shared global state from `URLProtocol`-based mocking
- stay friendly to Swift Concurrency and parallel test execution

A minimal test double looks like this:

```swift
actor MockTransport: FoliTransport {
    private let handler: @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    private(set) var requests: [URLRequest] = []

    init(handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)) {
        self.handler = handler
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let (response, data) = try handler(request)
        return (data, response)
    }
}
```

## Example fixture-based test

```swift
let payload = Data("[]".utf8)
let transport = MockTransport { request in
    let response = HTTPURLResponse(
        url: try #require(request.url),
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
    )!
    return (response, payload)
}

let client = FoliClient(transport: transport, cacheBehavior: .noCache)
let routes = try await client.fetchRoutes()
```

## Why this design

This transport seam is intentionally narrow. `FoliClient` only needs one capability from a networking layer: execute a `URLRequest` and return `(Data, URLResponse)`. Modeling that capability directly makes the package easier to test and evolve.

## FoliRequester

Request construction, response validation, and JSON decoding live in ``FoliRequester``, a `Sendable` value type that owns the transport, decoder, and four base URLs. Because `FoliRequester` is not actor-isolated, JSON decoding for large GTFS payloads (routes, stops, trips) runs on the cooperative thread pool rather than blocking `FoliClient`'s executor. `FoliClient` holds a `requester` reference and forwards its request methods.

The request methods accept an optional `headers` parameter for per-call request customization. For example, the alerts endpoint declares `Accept-Encoding: gzip` via this parameter rather than hard-coding it in the transport layer.

## Testing framework

Tests use the [swift-testing](https://developer.apple.com/xcode/testing/) framework (`import Testing`), where `#require` is the equivalent of `XCTUnwrap` and `#expect` is the equivalent of `XCTAssertEqual`. The mock examples above use swift-testing syntax.
