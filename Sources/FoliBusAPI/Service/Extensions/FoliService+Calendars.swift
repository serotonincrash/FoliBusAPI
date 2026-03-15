import Foundation

// MARK: - Calendar API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    /// Fetch all weekly service calendars from the API.
    /// - Returns: Array of all calendar records.
    func fetchCalendars() async throws -> [Foli.Calendar] {
        try await client.fetchCalendars()
    }

    /// Fetch a specific calendar by service ID.
    /// - Parameter serviceID: The service ID to fetch.
    /// - Returns: The calendar if found.
    func fetchCalendar(serviceID: String) async throws -> Foli.Calendar {
        guard let calendar = try await client.fetchCalendar(serviceID: serviceID) else {
            throw Foli.APIError.noData
        }
        return calendar
    }

    /// Fetch a specific calendar by service ID.
    /// - Parameter serviceId: The service ID to fetch.
    /// - Returns: The calendar if found.
    @available(*, deprecated, renamed: "fetchCalendar(serviceID:)")
    func fetchCalendar(serviceId: String) async throws -> Foli.Calendar {
        try await fetchCalendar(serviceID: serviceId)
    }
}
