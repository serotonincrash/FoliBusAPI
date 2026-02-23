import Foundation

/// Main module entry point for the FoliBusAPI package
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public final class FoliBusAPI {
    
    /// Shared singleton instance of the API client
    public static let client = FoliClient.shared
    
    /// Initialize a new FoliBusAPI instance
    public init() {}
    
    // MARK: - Convenience Methods
    
    /// Fetch stop monitoring data for a stop
    /// - Parameter stopId: The stop ID to monitor
    /// - Returns: Array of vehicle arrivals
    public static func fetchArrivals(for stopId: String) async throws -> [FoliVehicleArrival] {
        return try await client.fetchArrivals(for: stopId)
    }
    
    /// Fetch stop monitoring data for a stop
    /// - Parameter stopId: The stop ID to monitor
    /// - Returns: Array of vehicle arrivals
    public static func fetchArrivals(for stopId: Int) async throws -> [FoliVehicleArrival] {
        return try await client.fetchArrivals(for: stopId)
    }
    
    /// Fetch stop monitoring data for a stop
    /// - Parameter stop: The stop to monitor
    /// - Returns: Array of vehicle arrivals
    public static func fetchArrivals(for stop: Foli.Stop) async throws -> [FoliVehicleArrival] {
        return try await client.fetchArrivals(for: stop.id)
    }
    
    /// Fetch the complete list of stops
    /// - Returns: Array of all stops
    public static func fetchStops() async throws -> [Foli.Stop] {
        return try await client.fetchStopList()
    }
}

