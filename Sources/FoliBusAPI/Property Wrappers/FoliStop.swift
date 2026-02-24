import SwiftUI

// MARK: - Stop Monitoring Property Wrapper

/// A property wrapper that fetches and holds vehicle arrival data for a specific stop
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@propertyWrapper
public struct FoliStop: DynamicProperty, Sendable {
    
    @State private var arrivals: [Foli.Arrival] = []
    @State private var isLoading = false
    @State private var error: Foli.APIError?
    
    private let stopId: String
    private let client: FoliClient
    private let refreshInterval: TimeInterval?
    
    /// Create a new FoliStop property wrapper
    /// - Parameters:
    ///   - id: The ID of the stop to monitor
    ///   - client: The FoliClient to use (defaults to shared)
    ///   - refreshInterval: Optional interval in seconds to auto-refresh data (nil for manual refresh only)
    public init(
        id: String,
        client: FoliClient = .shared,
        refreshInterval: TimeInterval? = nil
    ) {
        self.stopId = id
        self.client = client
        self.refreshInterval = refreshInterval
    }
    
    /// Create a new FoliStop property wrapper with a numeric stop ID
    /// - Parameters:
    ///   - id: The numeric ID of the stop to monitor
    ///   - client: The FoliClient to use (defaults to shared)
    ///   - refreshInterval: Optional interval in seconds to auto-refresh data (nil for manual refresh only)
    public init(
        id: Int,
        client: FoliClient = .shared,
        refreshInterval: TimeInterval? = nil
    ) {
        self.stopId = String(id)
        self.client = client
        self.refreshInterval = refreshInterval
    }
    
    /// The wrapped value - the array of arrivals at the monitored stop
    public var wrappedValue: [Foli.Arrival] {
        get { arrivals }
        nonmutating set { arrivals = newValue }
    }
    
    /// The projected value provides access to loading state, error, and refresh control
    public var projectedValue: FoliStopProjection {
        FoliStopProjection(
            arrivals: $arrivals,
            isLoading: $isLoading,
            error: $error,
            refresh: refresh,
            stopId: stopId
        )
    }
    
    /// Refresh the stop monitoring data
    public func refresh() {
        Task { @MainActor in
            isLoading = true
            error = nil
            
            do {
                let newArrivals = try await client.fetchArrivals(for: stopId)
                arrivals = newArrivals
            } catch let apiError as Foli.APIError {
                self.error = apiError
            } catch {
                self.error = .networkError(error)
            }
            
            isLoading = false
        }
    }
    
    /// Internal task for auto-refresh
    @State private var refreshTask: Task<Void, Never>?
    
    /// Start auto-refreshing if a refresh interval is set
    public func startAutoRefresh() {
        guard let refreshInterval = refreshInterval else { return }
        
        refreshTask = Task { @MainActor in
            while !Task.isCancelled {
                refresh()
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            }
        }
    }
    
    /// Stop auto-refreshing
    public func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}

/// Projection values for FoliStop property wrapper
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public struct FoliStopProjection: Sendable {
    /// Binding to the arrivals array
    public var arrivals: Binding<[Foli.Arrival]>
    
    /// Binding to the loading state
    public var isLoading: Binding<Bool>
    
    /// Binding to the error state
    public var error: Binding<Foli.APIError?>
    
    /// Function to refresh the data
    public let refresh: @Sendable () -> Void
    
    /// The stop ID being monitored
    public let stopId: String
}
