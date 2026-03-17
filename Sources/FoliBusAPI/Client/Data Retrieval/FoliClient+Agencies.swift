import Foundation

// MARK: - Agencies (GTFS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    /// Fetch the complete list of agencies from GTFS.
    /// - Returns: An array of all agencies.
    func fetchAgenciesFromNetwork() async throws -> [Foli.Agency] {
        try await performDeduplicated(.agencies) { [self] in
            let agencyList = try await requestGTFS("/agency", as: Foli.AgencyList.self)
            return agencyList.agencies
        }
    }

    /// Fetch the complete list of agencies from GTFS.
    /// - Returns: An array of all agencies.
    func fetchAgencies() async throws -> [Foli.Agency] {
        switch self.cacheBehavior {
        case .cachedOrFetch:
            if let cached = try await cache?.loadAgencies() {
                rebuildAgencyIndex(using: cached)
                return cached
            }
            fallthrough

        case .staleWhileRevalidate:
            if let staleCached = try await cache?.loadStaleAgencies() {
                rebuildAgencyIndex(using: staleCached)
                refreshCacheInBackground(
                    for: .agencies,
                    fetch: { [self] in try await fetchAgenciesFromNetwork() },
                    save: { [cache] agencies in try await cache?.saveAgencies(agencies) }
                )
                return staleCached
            }
            fallthrough

        case .forceRefresh:
            let agencies = try await fetchAgenciesFromNetwork()
            rebuildAgencyIndex(using: agencies)
            try? await cache?.saveAgencies(agencies)
            return agencies

        case .cachedOnly:
            guard let cached = try await cache?.loadAgencies() else {
                throw Foli.APIError.noData
            }
            rebuildAgencyIndex(using: cached)
            return cached

        case .noCache:
            let agencies = try await fetchAgenciesFromNetwork()
            rebuildAgencyIndex(using: agencies)
            return agencies
        }
    }

    /// Fetch a specific agency by its ID.
    /// - Parameter agencyID: The ID of the agency.
    /// - Returns: The agency if found.
    func fetchAgency(id agencyID: String) async throws -> Foli.Agency? {
        _ = try await fetchAgencies()
        return indexedAgency(for: agencyID)
    }

    /// Fetch a specific agency by its ID.
    /// - Parameter agencyId: The ID of the agency.
    /// - Returns: The agency if found.
    @available(*, deprecated, renamed: "fetchAgency(id:)")
    func fetchAgency(forAgency agencyId: String) async throws -> Foli.Agency? {
        try await fetchAgency(id: agencyId)
    }
}
