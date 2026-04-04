import Foundation

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension FoliClient {
    // MARK: - Request Helpers

    /// Constructs a full URL for a given SIRI endpoint path
    /// - Parameter path: The endpoint path (e.g., "/sm" or "/sm/4")
    /// - Returns: A complete URL
    internal func makeEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    /// Constructs a full URL for a given GTFS endpoint path
    /// - Parameter path: The endpoint path (e.g., "/routes" or "/stops")
    /// - Returns: A complete URL
    internal func makeGTFSEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: gtfsBaseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    /// Constructs a full URL for a given Alerts endpoint path
    /// - Parameter path: The endpoint path (e.g., "/alerts" or "/alerts/messages")
    /// - Returns: A complete URL
    internal func makeAlertsEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: alertsBaseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    /// Constructs a full URL for a given GeoJSON endpoint path
    /// - Parameter path: The endpoint path (e.g., "/geojson/layers" or "/geojson/poi")
    /// - Returns: A complete URL
    internal func makeGeoJSONEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: geoJSONBaseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    /// Fetch and decode a response from a SIRI endpoint.
    internal func requestSIRI<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        let url = try makeEndpointURL(path: path)
        return try await request(url, as: type)
    }

    /// Fetch and decode a response from a GTFS endpoint.
    internal func requestGTFS<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        let url = try makeGTFSEndpointURL(path: path)
        return try await request(url, as: type)
    }

    /// Fetch and decode a response from an Alerts endpoint.
    internal func requestAlerts<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        let url = try makeAlertsEndpointURL(path: path)
        var request = URLRequest(url: url)
        // Alerts endpoint supports gzip compression
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        return try await requestWithCustomURLRequest(request, as: type)
    }

    /// Fetch and decode a response from a GeoJSON endpoint.
    internal func requestGeoJSON<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        let url = try makeGeoJSONEndpointURL(path: path)
        return try await request(url, as: type)
    }

    private func request<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        let request = URLRequest(url: url)
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
