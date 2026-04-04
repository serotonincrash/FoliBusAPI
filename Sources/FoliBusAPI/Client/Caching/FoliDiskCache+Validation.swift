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

        if isMetadataFresh(metadata) {
            return true
        }

        do {
            return try await revalidateCache(for: type)
        } catch {
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
        guard let metadata = try await loadMetadata(for: type) else {
            return false
        }

        let latestDatasetId = try await fetchLatestDatasetId()

        if latestDatasetId == metadata.datasetId {
            try? await refreshMetadataTimestamp(for: type)
            return true
        }

        return false
    }

    internal func fetchLatestDatasetId() async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw Foli.APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Foli.APIError.invalidResponse
        }

        let gtfsInfo = try JSONDecoder().decode(GTFSInfoResponse.self, from: data)
        return gtfsInfo.latest
    }
}
