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
    internal let gtfsBaseURL = "https://data.foli.fi/gtfs"
    internal let alertsBaseURL = "https://data.foli.fi"
    internal let geoJSONBaseURL = "https://data.foli.fi"

    internal init(transport: any FoliTransport) {
        self.transport = transport
    }

    // MARK: - URL Construction

    /// Constructs a full URL for a given SIRI endpoint path.
    /// - Parameter path: The endpoint path (e.g., "/sm" or "/sm/4").
    /// - Returns: A complete URL.
    internal func makeEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    /// Constructs a full URL for a given GTFS endpoint path.
    /// - Parameter path: The endpoint path (e.g., "/routes" or "/stops").
    /// - Returns: A complete URL.
    internal func makeGTFSEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: gtfsBaseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    /// Constructs a full URL for a given Alerts endpoint path.
    /// - Parameter path: The endpoint path (e.g., "/alerts" or "/alerts/messages").
    /// - Returns: A complete URL.
    internal func makeAlertsEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: alertsBaseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    /// Constructs a full URL for a given GeoJSON endpoint path.
    /// - Parameter path: The endpoint path (e.g., "/geojson/layers" or "/geojson/poi").
    /// - Returns: A complete URL.
    internal func makeGeoJSONEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: geoJSONBaseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    // MARK: - Request + Decode

    /// Fetch and decode a response from a SIRI endpoint.
    internal func requestSIRI<T: Decodable>(_ path: String, as type: T.Type = T.self, headers: [String: String] = [:]) async throws -> T {
        let url = try makeEndpointURL(path: path)
        return try await request(url, as: type, headers: headers)
    }

    /// Fetch and decode a response from a GTFS endpoint.
    internal func requestGTFS<T: Decodable>(_ path: String, as type: T.Type = T.self, headers: [String: String] = [:]) async throws -> T {
        let url = try makeGTFSEndpointURL(path: path)
        return try await request(url, as: type, headers: headers)
    }

    /// Fetch and decode a response from an Alerts endpoint.
    internal func requestAlerts<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        let url = try makeAlertsEndpointURL(path: path)
        // gzip is an alerts-endpoint declaration, not a transport concern
        return try await request(url, as: type, headers: ["Accept-Encoding": "gzip"])
    }

    /// Fetch and decode a response from a GeoJSON endpoint.
    internal func requestGeoJSON<T: Decodable>(_ path: String, as type: T.Type = T.self, headers: [String: String] = [:]) async throws -> T {
        let url = try makeGeoJSONEndpointURL(path: path)
        return try await request(url, as: type, headers: headers)
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

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw Foli.APIError.invalidResponse
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw Foli.APIError.decodingError(error)
            }
        } catch let error as Foli.APIError {
            throw error
        } catch {
            throw Foli.APIError.networkError(error)
        }
    }
}
