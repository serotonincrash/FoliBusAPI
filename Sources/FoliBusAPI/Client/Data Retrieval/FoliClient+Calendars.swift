import Foundation

// MARK: - Calendars (GTFS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    /// Fetch the complete list of weekly service calendars from GTFS.
    /// - Returns: An array of all calendar records.
    internal func fetchCalendarsFromNetwork() async throws -> [Foli.Calendar] {
        try await dedup.performDeduplicated(.calendars) { [self] in
            let calendarList = try await requestGTFS("/calendar", as: Foli.CalendarList.self)
            return calendarList.calendars
        }
    }

    /// Fetch the complete list of weekly service calendars from GTFS.
    /// - Returns: An array of all calendar records.
    func fetchCalendars() async throws -> [Foli.Calendar] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadCalendars() {
                await rebuildCalendarIndex(using: cached)
                return cached
            }
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleCalendars() {
                await rebuildCalendarIndex(using: staleCached)
                await refreshCacheInBackground(
                    for: .calendars,
                    fetch: { [self] in try await fetchCalendarsFromNetwork() },
                    save: { [cache] calendars in try await cache?.saveCalendars(calendars) }
                )
                return staleCached
            }
            fallthrough

        case .forceRefresh:
            let calendars = try await fetchCalendarsFromNetwork()
            await rebuildCalendarIndex(using: calendars)
            try? await cache?.saveCalendars(calendars)
            return calendars

        case .cachedOnly:
            guard let cached = try await cache?.loadCalendars() else {
                throw Foli.APIError.noData
            }
            await rebuildCalendarIndex(using: cached)
            return cached

        case .noCache:
            let calendars = try await fetchCalendarsFromNetwork()
            await rebuildCalendarIndex(using: calendars)
            return calendars
        }
    }

    /// Fetch a specific calendar by service ID.
    /// - Parameter serviceId: The service ID to fetch.
    /// - Returns: The calendar if found.
    func fetchCalendar(forServiceId serviceId: String) async throws -> Foli.Calendar? {
        _ = try await fetchCalendars()
        return await indexedCalendar(for: serviceId)
    }
}
