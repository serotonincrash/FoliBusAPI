import Foundation
import FoliBusAPI

// MARK: - Agencies API

public extension FoliService {
    /// Fetch all agencies from the API.
    /// - Returns: Array of all agencies.
    func fetchAgencies() async throws -> [Foli.Agency] {
        try await client.fetchAgencies()
    }

    /// Fetch a specific agency by ID.
    /// - Parameter agencyId: The agency ID to fetch.
    /// - Returns: The agency if found.
    /// - Throws: ``Foli/APIError/notFound`` if no agency matches the ID.
    func fetchAgency(id agencyId: String) async throws -> Foli.Agency {
        guard let agency = try await client.agency(for: agencyId) else {
            throw Foli.APIError.notFound
        }
        return agency
    }
}
