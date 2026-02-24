import SwiftUI

// MARK: - Route List Property Wrapper

/// A property wrapper that fetches and holds the complete list of all routes
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@propertyWrapper
public struct FoliRoutes: DynamicProperty, Sendable {
    
    @State private var routes: [Foli.Route] = []
    @State private var isLoading = false
    @State private var error: Foli.APIError?
    
    private let client: FoliClient
    
    /// Create a new FoliRoutes property wrapper
    /// - Parameter client: The FoliClient to use (defaults to shared)
    public init(client: FoliClient = .shared) {
        self.client = client
    }
    
    /// The wrapped value - the array of all routes
    public var wrappedValue: [Foli.Route] {
        get { routes }
        nonmutating set { routes = newValue }
    }
    
    /// The projected value provides access to loading state, error, refresh control, and convenience methods
    public var projectedValue: FoliRoutesProjection {
        FoliRoutesProjection(
            routes: $routes,
            isLoading: $isLoading,
            error: $error,
            refresh: refresh
        )
    }
    
    /// Refresh the route list by fetching all routes from the API
    public func refresh() {
        Task { @MainActor in
            isLoading = true
            error = nil
            
            do {
                let newRoutes = try await client.fetchRoutes()
                routes = newRoutes
            } catch let apiError as Foli.APIError {
                self.error = apiError
            } catch {
                self.error = .networkError(error)
            }
            
            isLoading = false
        }
    }
}

/// Projection values for FoliRoutes property wrapper
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public struct FoliRoutesProjection: Sendable {
    /// Binding to the routes array
    public var routes: Binding<[Foli.Route]>
    
    /// Binding to the loading state
    public var isLoading: Binding<Bool>
    
    /// Binding to the error state
    public var error: Binding<Foli.APIError?>
    
    /// Function to refresh the data
    public let refresh: @Sendable () -> Void
    
    /// Get routes sorted by short name
    public var sortedByShortName: [Foli.Route] {
        routes.wrappedValue.sorted { $0.shortName < $1.shortName }
    }
    
    /// Get routes sorted by long name
    public var sortedByLongName: [Foli.Route] {
        routes.wrappedValue.sorted { $0.longName < $1.longName }
    }
    
    /// Get routes sorted by ID
    public var sortedById: [Foli.Route] {
        routes.wrappedValue.sorted { $0.id < $1.id }
    }
    
    /// Get only bus routes
    public var busRoutes: [Foli.Route] {
        routes.wrappedValue.filter { $0.isBus }.sorted { $0.shortName < $1.shortName }
    }
    
    /// Get only tram routes
    public var tramRoutes: [Foli.Route] {
        routes.wrappedValue.filter { $0.isTram }.sorted { $0.shortName < $1.shortName }
    }
    
    /// Search for routes by name, short name, or ID
    /// - Parameter query: The search query
    /// - Returns: Array of matching routes sorted by short name
    public func search(query: String) -> [Foli.Route] {
        let filtered = routes.wrappedValue.filter { route in
            route.shortName.localizedCaseInsensitiveContains(query) ||
            route.longName.localizedCaseInsensitiveContains(query) ||
            route.id.contains(query)
        }
        return filtered.sorted { $0.shortName < $1.shortName }
    }
    
    /// Find routes that match a given line reference
    /// - Parameter lineRef: The line reference (e.g., "15")
    /// - Returns: Array of matching routes
    public func findRoutes(byLineRef lineRef: String) -> [Foli.Route] {
        return routes.wrappedValue.filter { $0.shortName == lineRef }
    }
}
