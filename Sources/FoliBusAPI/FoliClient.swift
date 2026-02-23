import Foundation

/// Main client for interacting with the Foli public transport API
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public actor FoliClient {
    
    /// Shared singleton instance
    public static let shared = FoliClient()
    
    /// Base URL for the Foli API
    private let baseURL = "https://data.foli.fi/siri"
    
    /// URLSession for making network requests
    private let session: URLSession
    
    /// Custom initializer for dependency injection (useful for testing)
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Stop List
    
    /// Fetch the complete list of all known stops
    /// - Returns: An array of all stops
    public func fetchStopList() async throws -> [Foli.Stop] {
        let url = try makeEndpointURL(path: "/sm")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FoliAPIError.invalidResponse
        }
        
        do {
            let stopList = try JSONDecoder().decode(FoliStopList.self, from: data)
            return stopList.stops
        } catch {
            throw FoliAPIError.decodingError(error)
        }
    }
    
    /// Fetch stop list as a FoliStopList model
    /// - Returns: FoliStopList containing all stops
    public func fetchStops() async throws -> FoliStopList {
        let stops = try await fetchStopList()
        return FoliStopList(stops: stops)
    }
    
    // MARK: - Stop Monitoring
    
    /// Fetch real-time monitoring data for a specific stop
    /// - Parameter stopId: The ID of the stop to monitor
    /// - Returns: Stop monitoring response with arrival/departure information
    public func fetchStopMonitoring(for stopId: String) async throws -> FoliStopMonitoringResponse {
        let url = try makeEndpointURL(path: "/sm/\(stopId)")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FoliAPIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(FoliStopMonitoringResponse.self, from: data)
        } catch {
            throw FoliAPIError.decodingError(error)
        }
    }
    
    /// Fetch real-time monitoring data for a specific stop using numeric ID
    /// - Parameter stopId: The numeric ID of the stop to monitor
    /// - Returns: Stop monitoring response with arrival/departure information
    public func fetchStopMonitoring(for stopId: Int) async throws -> FoliStopMonitoringResponse {
        return try await fetchStopMonitoring(for: String(stopId))
    }
    
    /// Fetch arrivals only for a specific stop
    /// - Parameter stopId: The ID of the stop to monitor
    /// - Returns: Array of vehicle arrivals
    public func fetchArrivals(for stopId: String) async throws -> [FoliVehicleArrival] {
        let response = try await fetchStopMonitoring(for: stopId)
        guard response.isValid else {
            throw FoliAPIError.serverError(response.status)
        }
        return response.result
    }
    
    /// Fetch arrivals only for a specific stop using numeric ID
    /// - Parameter stopId: The numeric ID of the stop to monitor
    /// - Returns: Array of vehicle arrivals
    public func fetchArrivals(for stopId: Int) async throws -> [FoliVehicleArrival] {
        return try await fetchArrivals(for: String(stopId))
    }
    
    // MARK: - Helper Methods
    
    /// Constructs a full URL for a given endpoint path
    /// - Parameter path: The endpoint path (e.g., "/sm" or "/sm/4")
    /// - Returns: A complete URL
    private func makeEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw FoliAPIError.invalidURL
        }
        return url
    }
}
