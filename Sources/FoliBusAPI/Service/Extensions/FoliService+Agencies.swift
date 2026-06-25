import Foundation

// MARK: - Agencies API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    /// Fetch all agencies from the API.
    /// - Returns: Array of all agencies.
    func fetchAgencies() async throws -> [Foli.Agency] {
        try await client.fetchAgencies()
    }

    /// Fetch a specific agency by ID.
    /// - Parameter agencyID: The agency ID to fetch.
    /// - Returns: The agency if found.
    func fetchAgency(id agencyID: String) async throws -> Foli.Agency {
        guard let agency = try await client.fetchAgency(id: agencyID) else {
            throw Foli.APIError.notFound
        }
        return agency
    }
}
