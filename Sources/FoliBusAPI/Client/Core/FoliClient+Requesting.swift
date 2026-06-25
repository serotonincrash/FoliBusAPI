import Foundation

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension FoliClient {
    // MARK: - Request Forwarders

    /// Fetch and decode a response from a SIRI endpoint.
    internal nonisolated func requestSIRI<T: Decodable>(_ path: String, as type: T.Type = T.self, headers: [String: String] = [:]) async throws -> T {
        try await requester.requestSIRI(path, as: type, headers: headers)
    }

    /// Fetch and decode a response from a GTFS endpoint.
    internal nonisolated func requestGTFS<T: Decodable>(_ path: String, as type: T.Type = T.self, headers: [String: String] = [:]) async throws -> T {
        try await requester.requestGTFS(path, as: type, headers: headers)
    }

    /// Fetch and decode a response from an Alerts endpoint.
    internal nonisolated func requestAlerts<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        try await requester.requestAlerts(path, as: type)
    }

    /// Fetch and decode a response from a GeoJSON endpoint.
    internal nonisolated func requestGeoJSON<T: Decodable>(_ path: String, as type: T.Type = T.self, headers: [String: String] = [:]) async throws -> T {
        try await requester.requestGeoJSON(path, as: type, headers: headers)
    }
}
