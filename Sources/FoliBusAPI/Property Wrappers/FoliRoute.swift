import SwiftUI

// MARK: - Route Property Wrapper

/// A property wrapper that fetches and holds data for a specific route
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@propertyWrapper
public struct FoliRoute: DynamicProperty, Sendable {
    
    @State private var route: Foli.Route?
    @State private var isLoading = false
    @State private var error: Foli.APIError?
    
    private let routeId: String
    private let client: FoliClient
    private let refreshInterval: TimeInterval?
    
    /// Create a new FoliRoute property wrapper
    /// - Parameters:
    ///   - id: The ID of the route to fetch
    ///   - client: The FoliClient to use (defaults to shared)
    ///   - refreshInterval: Optional interval in seconds to auto-refresh data (nil for manual refresh only)
    public init(
        id: String,
        client: FoliClient = .shared,
        refreshInterval: TimeInterval? = nil
    ) {
        self.routeId = id
        self.client = client
        self.refreshInterval = refreshInterval
    }
    
    /// The wrapped value - the route data
    public var wrappedValue: Foli.Route? {
        get { route }
        nonmutating set { route = newValue }
    }
    
    /// The projected value provides access to loading state, error, and refresh control
    public var projectedValue: FoliRouteProjection {
        FoliRouteProjection(
            route: $route,
            isLoading: $isLoading,
            error: $error,
            refresh: refresh,
            routeId: routeId
        )
    }
    
    /// Refresh the route data
    public func refresh() {
        Task { @MainActor in
            isLoading = true
            error = nil
            
            do {
                let fetchedRoute = try await client.fetchRoute(byId: routeId)
                route = fetchedRoute
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

/// Projection values for FoliRoute property wrapper
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public struct FoliRouteProjection: Sendable {
    /// Binding to the route
    public var route: Binding<Foli.Route?>
    
    /// Binding to the loading state
    public var isLoading: Binding<Bool>
    
    /// Binding to the error state
    public var error: Binding<Foli.APIError?>
    
    /// Function to refresh the data
    public let refresh: @Sendable () -> Void
    
    /// The route ID being monitored
    public let routeId: String
    
    /// Whether a route is loaded
    public var hasRoute: Bool {
        route.wrappedValue != nil
    }
}
