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
    /// - Parameter serviceId: The service ID to fetch.
    /// - Returns: The calendar if found.
    func fetchCalendar(forServiceId serviceId: String) async throws -> Foli.Calendar {
        guard let calendar = try await client.fetchCalendar(forServiceId: serviceId) else {
            throw Foli.APIError.notFound
        }
        return calendar
    }
}
