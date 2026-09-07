import Foundation

extension Foli.DiskCache {
    func clearAllCache() async throws {
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        )

        for url in contents {
            try fileManager.removeItem(at: url)
        }
    }

    func clearCache(for type: Foli.Resource) async throws {
        let fileURL = try fileURL(for: type)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    func hasValidCache(for type: Foli.Resource) async -> Bool {
        guard let metadata = try? await loadMetadata(for: type) else {
            return false
        }

        if Date().timeIntervalSince(metadata.cachedAt) <= timeoutDuration.validityDuration {
            return true
        }

        do {
            return try await revalidateCache(for: type)
        } catch {
            if Task.isCancelled { return false }
            return true
        }
    }

    func currentDatasetId(for type: Foli.Resource?) async throws -> String? {
        if let type = type {
            return try await loadMetadata(for: type)?.datasetId
        } else {
            return try await loadMostRecentDatasetId()
        }
    }

    var currentDatasetId: String? {
        get async throws {
            return try await currentDatasetId(for: nil)
        }
    }

    @discardableResult
    func revalidateCache(for type: Foli.Resource) async throws -> Bool {
        let latestDatasetId = try await fetchLatestDatasetId()

        guard let metadata = try await loadMetadata(for: type) else {
            return false
        }

        if latestDatasetId == metadata.datasetId {
            try? await refreshMetadataTimestamp(for: type)
            return true
        }

        return false
    }

    internal func fetchLatestDatasetId() async throws -> String {
        try await datasetIdFetcher()
    }
}
