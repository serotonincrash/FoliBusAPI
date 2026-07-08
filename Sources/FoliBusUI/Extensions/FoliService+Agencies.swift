import Foundation
import FoliBusAPI

// MARK: - Agencies API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
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
