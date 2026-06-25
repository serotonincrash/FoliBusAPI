import Foundation

// MARK: - Agencies (GTFS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    /// Fetch the complete list of agencies from GTFS.
    /// - Returns: An array of all agencies.
    internal func fetchAgenciesFromNetwork() async throws -> [Foli.Agency] {
        try await dedup.performDeduplicated(.agencies) { [self] in
            let agencyList = try await requestGTFS("/agency", as: Foli.AgencyList.self)
            return agencyList.agencies
        }
    }

    /// Fetch the complete list of agencies from GTFS.
    /// - Returns: An array of all agencies.
    func fetchAgencies() async throws -> [Foli.Agency] {
        try await resolveCached(
            for: .agencies,
            load: { [cache] in try await cache?.loadAgencies() },
            loadStale: { [cache] in try await cache?.loadStaleAgencies() },
            save: { [cache] agencies in try await cache?.saveAgencies(agencies) },
            fetch: { [self] in try await fetchAgenciesFromNetwork() },
            rebuildIndex: { [self] agencies in await rebuildAgencyIndex(using: agencies) }
        )
    }

    /// Fetch a specific agency by its ID.
    /// - Parameter agencyID: The ID of the agency.
    /// - Returns: The agency if found.
    func fetchAgency(id agencyID: String) async throws -> Foli.Agency? {
        _ = try await fetchAgencies()
        return await indexedAgency(for: agencyID)
    }
}
