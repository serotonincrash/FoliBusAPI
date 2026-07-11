import Foundation

// MARK: - Calendars (GTFS)

public extension FoliClient {
    /// Fetch the complete list of weekly service calendars from GTFS.
    /// - Returns: An array of all calendar records.
    internal func fetchCalendarsFromNetwork() async throws -> [Foli.Calendar] {
        try await dedup.performDeduplicated(forKey: .resource(.calendars)) { [self] in
            let calendarList = try await requestGTFS("/calendar", as: Foli.CalendarList.self)
            return calendarList.calendars
        }
    }

    /// Fetch the complete list of weekly service calendars from GTFS.
    /// - Returns: An array of all calendar records.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchCalendars() async throws -> [Foli.Calendar] {
        try await resolveCached(
            for: .calendars,
            load: { [cache] in try await cache?.loadCalendars() },
            loadStale: { [cache] in try await cache?.loadStaleCalendars() },
            save: { [cache] calendars in try await cache?.saveCalendars(calendars) },
            fetch: { [self] in try await fetchCalendarsFromNetwork() },
            rebuildIndex: { [self] calendars in await indexes.rebuildCalendars(using: calendars) }
        )
    }

    /// Fetch a specific calendar by service ID.
    /// - Parameter serviceId: The service ID to fetch.
    /// - Returns: The calendar if found.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchCalendar(forServiceId serviceId: String) async throws -> Foli.Calendar? {
        _ = try await fetchCalendars()
        return await indexes.calendar(for: serviceId)
    }
}
