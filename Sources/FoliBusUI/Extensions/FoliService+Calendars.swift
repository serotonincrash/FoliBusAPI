import Foundation
import FoliBusAPI

// MARK: - Calendar API

public extension FoliService {
    /// Fetch all weekly service calendars from the API.
    /// - Returns: Array of all calendar records.
    func fetchCalendars() async throws -> [Foli.Calendar] {
        try await client.fetchCalendars()
    }

    /// Fetch a specific calendar by service ID.
    /// - Parameter serviceId: The service ID to fetch.
    /// - Returns: The calendar if found.
    /// - Throws: ``Foli/APIError/notFound`` if no calendar matches the service ID.
    func fetchCalendar(forServiceId serviceId: String) async throws -> Foli.Calendar {
        guard let calendar = try await client.fetchCalendar(forServiceId: serviceId) else {
            throw Foli.APIError.notFound
        }
        return calendar
    }
}
