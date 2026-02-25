import SwiftUI

// MARK: - Stop List Property Wrapper

/// A property wrapper that fetches and holds the complete list of all stops
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@propertyWrapper
public struct FoliStops: DynamicProperty, Sendable {
    
    @State private var stops: [Foli.Stop] = []
    @State private var isLoading = false
    @State private var error: Foli.APIError?
    
    private let client: FoliClient
    @State private var _needsRefresh = true
    
    /// Create a new FoliStops property wrapper
    /// - Parameter client: The FoliClient to use (defaults to shared)
    public init(client: FoliClient = .shared) {
        self.client = client
    }
    
    /// The wrapped value - the array of all stops
    public var wrappedValue: [Foli.Stop] {
        get {
            if _needsRefresh {
                _needsRefresh = false
                Task { @MainActor in
                    self.refresh()
                }
            }
            return stops
        }
        nonmutating set { stops = newValue }
    }
    
    /// The projected value provides access to loading state, error, refresh control, and convenience methods
    public var projectedValue: FoliStopsProjection {
        FoliStopsProjection(
            stops: $stops,
            isLoading: $isLoading,
            error: $error,
            refresh: refresh
        )
    }
    
    /// Refresh the stop list by fetching all stops from the API
    public func refresh() {
        Task { @MainActor in
            isLoading = true
            error = nil
            
            do {
                let newStops = try await client.fetchStops()
                stops = newStops
            } catch let apiError as Foli.APIError {
                self.error = apiError
            } catch {
                self.error = .networkError(error)
            }
            
            isLoading = false
        }
    }
}

/// Projection values for FoliStops property wrapper
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public struct FoliStopsProjection: Sendable {
    /// Binding to the stops array
    public var stops: Binding<[Foli.Stop]>
    
    /// Binding to the loading state
    public var isLoading: Binding<Bool>
    
    /// Binding to the error state
    public var error: Binding<Foli.APIError?>
    
    /// Function to refresh the data
    public let refresh: @Sendable () -> Void
    
    /// Get stops sorted by name
    public var sortedStops: [Foli.Stop] {
        stops.wrappedValue.sorted { $0.stopName < $1.stopName }
    }
    
    /// Get stops sorted by ID
    public var sortedById: [Foli.Stop] {
        stops.wrappedValue.sorted { $0.id < $1.id }
    }
    
    /// Search for stops by name or ID
    /// - Parameter query: The search query
    /// - Returns: Array of matching stops sorted by name
    public func search(query: String) -> [Foli.Stop] {
        let filtered = stops.wrappedValue.filter { stop in
            stop.stopName.localizedCaseInsensitiveContains(query) || stop.id.contains(query)
        }
        return filtered.sorted { $0.stopName < $1.stopName }
    }
}
