import Foundation

/// Owns the HTTP transport, decoder, base URLs, and all request/decode logic
/// that was previously on the ``FoliClient`` actor itself.
///
/// Extracting these into a plain ``Sendable`` value type means JSON decoding
/// for large GTFS payloads (routes, stops, trips) no longer runs on the
/// actor's executor and therefore no longer blocks unrelated ``FoliClient`` calls.
internal struct FoliRequester: Sendable {
    internal let transport: any FoliTransport
    internal let decoder = JSONDecoder()
    internal let baseURL = "https://data.foli.fi/siri"
    internal let rootURL = "https://data.foli.fi"

    internal init(transport: any FoliTransport) {
        self.transport = transport
    }

    // MARK: - Path Component Encoding

    /// Percent-encodes a raw value for safe interpolation into a URL path segment.
    ///
    /// Endpoint paths are built by interpolating caller-supplied IDs (e.g.
    /// `"/shapes/\(shapeId)"`). Those IDs are opaque strings from GTFS data or
    /// caller input and may contain characters like `/`, `?`, `#`, or spaces
    /// that would otherwise be misinterpreted as path separators or query
    /// delimiters, silently producing the wrong URL (or `Foli.APIError.invalidURL`)
    /// instead of a request to the intended, distinct path segment.
    /// - Parameter raw: The unencoded path component.
    /// - Returns: A percent-encoded string safe to interpolate into a URL path.
    internal static func pathComponent(_ raw: String) -> String {
        raw.addingPercentEncoding(withAllowedCharacters: Self.allowedPathComponentCharacters) ?? raw
    }

    /// Alphanumerics plus RFC 3986 "unreserved" punctuation (`-`, `.`, `_`, `~`) that
    /// real GTFS IDs commonly contain (e.g. shape ID `"0_7"`, trip ID
    /// `"0000null__1901generatedBlock"`). Everything else — `/`, `?`, `#`, spaces,
    /// etc. — gets percent-encoded so it can't be misread as a path separator or
    /// query delimiter.
    private static let allowedPathComponentCharacters: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()

    // MARK: - URL Construction

    /// Constructs a full URL from a base URL and endpoint path.
    /// - Returns: A complete URL.
    /// - Throws: ``Foli/APIError/invalidURL`` if the combined string is not a valid URL.
    private func makeURL(base: String, path: String) throws -> URL {
        guard let url = URL(string: base + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    // MARK: - Request + Decode

    /// Fetch and decode a response from a SIRI endpoint.
    internal func requestSIRI<T: Decodable>(_ path: String, as type: T.Type = T.self, headers: [String: String] = [:]) async throws -> T {
        try await request(makeURL(base: baseURL, path: path), as: type, headers: headers)
    }

    /// Fetch and decode a response from a GTFS endpoint.
    internal func requestGTFS<T: Decodable>(_ path: String, as type: T.Type = T.self, headers: [String: String] = [:]) async throws -> T {
        try await request(makeURL(base: rootURL + "/gtfs", path: path), as: type, headers: headers)
    }

    /// Fetch and decode a response from an Alerts endpoint.
    internal func requestAlerts<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        // gzip is an alerts-endpoint declaration, not a transport concern
        return try await request(makeURL(base: rootURL, path: path), as: type, headers: ["Accept-Encoding": "gzip"])
    }

    /// Fetch and decode a response from a GeoJSON endpoint.
    internal func requestGeoJSON<T: Decodable>(_ path: String, as type: T.Type = T.self, headers: [String: String] = [:]) async throws -> T {
        try await request(makeURL(base: rootURL, path: path), as: type, headers: headers)
    }

    // MARK: - Private Helpers

    private func request<T: Decodable>(_ url: URL, as type: T.Type, headers: [String: String]) async throws -> T {
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return try await requestWithCustomURLRequest(request, as: type)
    }

    private func requestWithCustomURLRequest<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        do {
            let (data, response) = try await transport.data(for: request)

            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? -1
            guard (200...299).contains(statusCode) else {
                // The Föli GTFS API answers 404 `path_not_exists` for collection
                // endpoints whose entity currently has no entries — e.g.
                // `/trips/route/8` (line 3T) outside its service window. "No trips
                // right now" is an empty collection, not a transport failure, so a
                // 404 decodes as `[]` when the response type allows it. Object-shaped
                // types (SIRI responses) can't decode `[]` and keep invalidResponse.
                if statusCode == 404,
                   let empty = try? decoder.decode(T.self, from: Data("[]".utf8)) {
                    return empty
                }
                throw Foli.APIError.invalidResponse
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw Foli.APIError.decodingError(error)
            }
        } catch let error as Foli.APIError {
            throw error
        } catch is CancellationError {
            // Preserve cancellation semantics: a cancelled caller must see
            // CancellationError, not a spurious network failure.
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw Foli.APIError.networkError(error)
        }
    }
}
