import Foundation

// MARK: - Agencies (GTFS)

public extension FoliClient {
    /// Fetch the complete list of agencies from GTFS.
    /// - Returns: An array of all agencies.
    internal func fetchAgenciesFromNetwork() async throws -> [Foli.Agency] {
        try await dedup.performDeduplicated(forKey: .resource(.agencies)) { [self] in
            let agencyList = try await requestGTFS("/agency", as: Foli.AgencyList.self)
            return agencyList.agencies
        }
    }

    /// Fetch the complete list of agencies from GTFS.
    /// - Returns: An array of all agencies.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func fetchAgencies() async throws -> [Foli.Agency] {
        try await resolveCached(
            for: .agencies,
            load: { [cache] in try await cache?.loadAgencies() },
            loadStale: { [cache] in try await cache?.loadStaleAgencies() },
            save: { [cache] agencies, datasetId in try await cache?.saveAgencies(agencies, datasetId: datasetId) },
            fetch: { [self] in try await fetchAgenciesFromNetwork() },
            rebuildIndex: { [self] agencies in await indexes.rebuildAgencies(using: agencies) }
        )
    }

    /// Fetch a specific agency by its ID.
    ///
    /// The Foli API does not support individual agency lookups — this method fetches all agencies
    /// (cached) and performs an O(1) dictionary lookup.
    /// The first call populates the cache; subsequent calls are instant.
    ///
    /// - Parameter agencyId: The ID of the agency.
    /// - Returns: The agency if found.
    /// - Throws: `Foli.APIError` if the network request or decoding fails.
    func agency(for agencyId: String) async throws -> Foli.Agency? {
        _ = try await fetchAgencies()
        return await indexes.agency(for: agencyId)
    }
}
