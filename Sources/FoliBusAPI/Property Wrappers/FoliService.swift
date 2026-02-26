import SwiftUI

// MARK: - FoliService Property Wrapper

/// A property wrapper that provides a service interface for fetching Foli transit data
/// with dynamic parameters, compatible with dependency injection.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@propertyWrapper
public struct FoliService: DynamicProperty, Sendable {
    
    private let client: FoliClient
    
    // MARK: - Arrivals State
    
    @State private var arrivalsData: [String: [Foli.Arrival]] = [:]
    @State private var arrivalsLoading: Set<String> = []
    @State private var arrivalsErrors: [String: Foli.APIError] = [:]
    @State private var arrivalsRefreshTasks: [String: Task<Void, Never>] = [:]
    
    // MARK: - Stops State
    
    @State private var stopsData: [Foli.Stop] = []
    @State private var stopsLoading = false
    @State private var stopsError: Foli.APIError?
    
    // MARK: - Stop (by ID) State
    
    @State private var stopData: [String: Foli.Stop] = [:]
    @State private var stopLoading: Set<String> = []
    @State private var stopErrors: [String: Foli.APIError] = [:]
    
    // MARK: - Routes State
    
    @State private var routesData: [Foli.Route] = []
    @State private var routesLoading = false
    @State private var routesError: Foli.APIError?
    
    // MARK: - Route (by ID) State
    
    @State private var routeData: [String: Foli.Route] = [:]
    @State private var routeLoading: Set<String> = []
    @State private var routeErrors: [String: Foli.APIError] = [:]
    @State private var routeRefreshTasks: [String: Task<Void, Never>] = [:]
    
    public init(client: FoliClient = .shared) {
        self.client = client
    }
    
    public var wrappedValue: FoliService {
        self
    }
    
    public var projectedValue: FoliServiceProjection {
        FoliServiceProjection(service: self)
    }
}

// MARK: - ResourceState

public extension FoliService {
    enum ResourceState<T> {
        case idle
        case loading
        case success(T)
        case error(Foli.APIError)
    }
}

// MARK: - FoliServiceProjection

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public struct FoliServiceProjection: Sendable {
    let service: FoliService
}

// MARK: - Arrivals API

public extension FoliService {
    
    /// Get the state of arrivals for a stop, fetching automatically if idle
    /// - Parameter stopId: The stop ID
    /// - Returns: Current resource state
    func arrivals(for stopId: String) -> ResourceState<[Foli.Arrival]> {
        // Auto-fetch only if truly idle (not loading, no data, no error)
        let isLoading = arrivalsLoading.contains(stopId)
        let hasData = arrivalsData[stopId] != nil
        let hasError = arrivalsErrors[stopId] != nil
        
        if !isLoading && !hasData && !hasError {
            fetchArrivals(for: stopId)
        }
        
        // Return current state
        if isLoading {
            return .loading
        } else if let data = arrivalsData[stopId] {
            return .success(data)
        } else if let error = arrivalsErrors[stopId] {
            return .error(error)
        }
        return .idle
    }
    
    func arrivals(for stopId: Int) -> ResourceState<[Foli.Arrival]> {
        arrivals(for: String(stopId))
    }
    
    /// Start auto-refreshing arrivals for a stop
    /// - Parameters:
    ///   - stopId: The stop ID
    ///   - interval: Refresh interval in seconds
    func startMonitoringArrivals(for stopId: String, interval: TimeInterval) {
        startMonitoringArrivals(for: String(stopId), interval: interval)
    }
    
    func startMonitoringArrivals(for stopId: Int, interval: TimeInterval) {
        let stopId = String(stopId)
        
        // Cancel existing monitor for this stop
        arrivalsRefreshTasks[stopId]?.cancel()
        arrivalsRefreshTasks.removeValue(forKey: stopId)
        
        // Start monitoring with periodic refreshes
        arrivalsRefreshTasks[stopId] = Task { @MainActor in
            while !Task.isCancelled {
                fetchArrivals(for: stopId)
                
                // Wait for interval, but check if cancelled
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                
                // Exit if this stop is no longer being monitored (task was cancelled)
                if arrivalsRefreshTasks[stopId] == nil {
                    return
                }
            }
        }
    }
    
    /// Stop auto-refreshing arrivals for a stop
    func stopMonitoringArrivals(for stopId: String) {
        arrivalsRefreshTasks[stopId]?.cancel()
        arrivalsRefreshTasks.removeValue(forKey: stopId)
    }
    
    func stopMonitoringArrivals(for stopId: Int) {
        stopMonitoringArrivals(for: String(stopId))
    }
    
    /// Manually refresh arrivals for a stop
    func refreshArrivals(for stopId: String) {
        fetchArrivals(for: stopId)
    }
    
    func refreshArrivals(for stopId: Int) {
        refreshArrivals(for: String(stopId))
    }
    
    // MARK: - Internal
    
    private func fetchArrivals(for stopId: String) {
        Task { @MainActor in
            // Skip if already loading this stop
            guard !arrivalsLoading.contains(stopId) else { return }
            
            arrivalsLoading.insert(stopId)
            arrivalsErrors.removeValue(forKey: stopId)
            
            do {
                let newArrivals = try await client.fetchArrivals(for: stopId)
                arrivalsData[stopId] = newArrivals
            } catch let apiError as Foli.APIError {
                arrivalsErrors[stopId] = apiError
            } catch {
                arrivalsErrors[stopId] = .networkError(error)
            }
            
            arrivalsLoading.remove(stopId)
        }
    }
}

// MARK: - Stops API

public extension FoliService {
    
    /// Get the state of all stops, fetching automatically if idle
    func stops() -> ResourceState<[Foli.Stop]> {
        if !stopsLoading && stopsData.isEmpty && stopsError == nil {
            fetchStops()
        }
        
        if stopsLoading {
            return .loading
        } else if !stopsData.isEmpty {
            return .success(stopsData)
        } else if let error = stopsError {
            return .error(error)
        }
        return .idle
    }
    
    /// Manually refresh all stops
    func refreshStops() {
        fetchStops()
    }
    
    private func fetchStops() {
        Task { @MainActor in
            guard !stopsLoading else { return }
            
            stopsLoading = true
            stopsError = nil
            
            do {
                stopsData = try await client.fetchStops()
            } catch let apiError as Foli.APIError {
                stopsError = apiError
            } catch {
                stopsError = .networkError(error)
            }
            
            stopsLoading = false
        }
    }
    
    // MARK: - Convenience Methods
    
    var sortedStops: [Foli.Stop] {
        stopsData.sorted { $0.stopName < $1.stopName }
    }
    
    var sortedStopsById: [Foli.Stop] {
        stopsData.sorted { $0.id < $1.id }
    }
    
    func searchStops(query: String) -> [Foli.Stop] {
        stopsData.filter { stop in
            stop.stopName.localizedCaseInsensitiveContains(query) || stop.id.contains(query)
        }.sorted { $0.stopName < $1.stopName }
    }
}

// MARK: - Stop (by ID) API

public extension FoliService {
    
    /// Get a specific stop by ID, fetching automatically if idle
    func stop(id stopId: String) -> ResourceState<Foli.Stop> {
        let isLoading = stopLoading.contains(stopId)
        let hasData = stopData[stopId] != nil
        let hasError = stopErrors[stopId] != nil
        
        if !isLoading && !hasData && !hasError {
            fetchStop(for: stopId)
        }
        
        if isLoading {
            return .loading
        } else if let stop = stopData[stopId] {
            return .success(stop)
        } else if let error = stopErrors[stopId] {
            return .error(error)
        }
        return .idle
    }
    
    func stop(id stopId: Int) -> ResourceState<Foli.Stop> {
        stop(id: String(stopId))
    }
    
    func refreshStop(id stopId: String) {
        fetchStop(for: stopId)
    }
    
    func refreshStop(id stopId: Int) {
        refreshStop(id: String(stopId))
    }
    
    private func fetchStop(for stopId: String) {
        Task { @MainActor in
            guard !stopLoading.contains(stopId) else { return }
            
            stopLoading.insert(stopId)
            stopErrors.removeValue(forKey: stopId)
            
            do {
                if let stop = try await client.fetchStop(byId: stopId) {
                    stopData[stopId] = stop
                } else {
                    stopErrors[stopId] = .noData
                }
            } catch let apiError as Foli.APIError {
                stopErrors[stopId] = apiError
            } catch {
                stopErrors[stopId] = .networkError(error)
            }
            
            stopLoading.remove(stopId)
        }
    }
}

// MARK: - Routes API

public extension FoliService {
    
    /// Get the state of all routes, fetching automatically if idle
    func routes() -> ResourceState<[Foli.Route]> {
        if !routesLoading && routesData.isEmpty && routesError == nil {
            fetchRoutes()
        }
        
        if routesLoading {
            return .loading
        } else if !routesData.isEmpty {
            return .success(routesData)
        } else if let error = routesError {
            return .error(error)
        }
        return .idle
    }
    
    func refreshRoutes() {
        fetchRoutes()
    }
    
    private func fetchRoutes() {
        Task { @MainActor in
            guard !routesLoading else { return }
            
            routesLoading = true
            routesError = nil
            
            do {
                routesData = try await client.fetchRoutes()
            } catch let apiError as Foli.APIError {
                routesError = apiError
            } catch {
                routesError = .networkError(error)
            }
            
            routesLoading = false
        }
    }
    
    // MARK: - Convenience Methods
    
    var sortedRoutesByShortName: [Foli.Route] {
        routesData.sorted { $0.shortName < $1.shortName }
    }
    
    var sortedRoutesById: [Foli.Route] {
        routesData.sorted { $0.id < $1.id }
    }
    
    func searchRoutes(query: String) -> [Foli.Route] {
        routesData.filter { route in
            route.shortName.localizedCaseInsensitiveContains(query) ||
            route.longName.localizedCaseInsensitiveContains(query) ||
            route.id.contains(query)
        }.sorted { $0.shortName < $1.shortName }
    }
    
    func findRoutes(byLineRef lineRef: String) -> [Foli.Route] {
        routesData.filter { $0.shortName == lineRef }
    }
}

// MARK: - Route (by ID) API

public extension FoliService {
    
    /// Get a specific route by ID, fetching automatically if idle
    func route(id routeId: String) -> ResourceState<Foli.Route> {
        let isLoading = routeLoading.contains(routeId)
        let hasData = routeData[routeId] != nil
        let hasError = routeErrors[routeId] != nil
        
        if !isLoading && !hasData && !hasError {
            fetchRoute(for: routeId)
        }
        
        if isLoading {
            return .loading
        } else if let route = routeData[routeId] {
            return .success(route)
        } else if let error = routeErrors[routeId] {
            return .error(error)
        }
        return .idle
    }
    
    /// Start auto-refreshing a route
    func startMonitoringRoute(id routeId: String, interval: TimeInterval) {
        // Cancel existing monitor
        routeRefreshTasks[routeId]?.cancel()
        routeRefreshTasks.removeValue(forKey: routeId)
        
        routeRefreshTasks[routeId] = Task { @MainActor in
            while !Task.isCancelled {
                fetchRoute(for: routeId)
                
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                
                if routeRefreshTasks[routeId] == nil {
                    return
                }
            }
        }
    }
    
    /// Stop auto-refreshing a route
    func stopMonitoringRoute(id routeId: String) {
        routeRefreshTasks[routeId]?.cancel()
        routeRefreshTasks.removeValue(forKey: routeId)
    }
    
    func refreshRoute(id routeId: String) {
        fetchRoute(for: routeId)
    }
    
    private func fetchRoute(for routeId: String) {
        Task { @MainActor in
            guard !routeLoading.contains(routeId) else { return }
            
            routeLoading.insert(routeId)
            routeErrors.removeValue(forKey: routeId)
            
            do {
                if let route = try await client.fetchRoute(byId: routeId) {
                    routeData[routeId] = route
                } else {
                    routeErrors[routeId] = .noData
                }
            } catch let apiError as Foli.APIError {
                routeErrors[routeId] = apiError
            } catch {
                routeErrors[routeId] = .networkError(error)
            }
            
            routeLoading.remove(routeId)
        }
    }
}

// MARK: - Cache Management

public extension FoliService {
    
    func clearAll() {
        Task { @MainActor in
            // Clear arrivals
            arrivalsData.removeAll()
            arrivalsErrors.removeAll()
            arrivalsLoading.removeAll()
            arrivalsRefreshTasks.values.forEach { $0.cancel() }
            arrivalsRefreshTasks.removeAll()
            
            // Clear stops
            stopsData.removeAll()
            stopsError = nil
            stopsLoading = false
            
            stopData.removeAll()
            stopErrors.removeAll()
            stopLoading.removeAll()
            
            // Clear routes
            routesData.removeAll()
            routesError = nil
            routesLoading = false
            
            routeData.removeAll()
            routeErrors.removeAll()
            routeLoading.removeAll()
            routeRefreshTasks.values.forEach { $0.cancel() }
            routeRefreshTasks.removeAll()
        }
    }
    
    func clearArrivals(for stopId: String) {
        Task { @MainActor in
            stopMonitoringArrivals(for: stopId)
            arrivalsData.removeValue(forKey: stopId)
            arrivalsErrors.removeValue(forKey: stopId)
        }
    }
    
    func clearArrivals(for stopId: Int) {
        clearArrivals(for: String(stopId))
    }
    
    func clearAllArrivals() {
        Task { @MainActor in
            arrivalsData.removeAll()
            arrivalsErrors.removeAll()
            arrivalsLoading.removeAll()
            arrivalsRefreshTasks.values.forEach { $0.cancel() }
            arrivalsRefreshTasks.removeAll()
        }
    }
    
    func clearStops() {
        Task { @MainActor in
            stopsData.removeAll()
            stopsError = nil
            stopsLoading = false
            stopData.removeAll()
            stopErrors.removeAll()
            stopLoading.removeAll()
        }
    }
    
    func clearRoutes() {
        Task { @MainActor in
            routesData.removeAll()
            routesError = nil
            routesLoading = false
            routeData.removeAll()
            routeErrors.removeAll()
            routeLoading.removeAll()
            routeRefreshTasks.values.forEach { $0.cancel() }
            routeRefreshTasks.removeAll()
        }
    }
}
