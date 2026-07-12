import Foundation

extension Foli.DiskCache {
    /// - Parameter datasetId: The dataset ID to tag this entry with. If `nil`, falls
    ///   back to fetching the latest dataset ID via ``datasetIdFetcher`` (used by
    ///   revalidation-driven saves that don't have a pre-fetch snapshot).
    internal func saveResource<T: Codable & Sendable>(_ value: T, forKey key: Foli.Resource, datasetId: String?) async throws {
        let resolvedDatasetId: String
        if let datasetId {
            resolvedDatasetId = datasetId
        } else {
            resolvedDatasetId = try await fetchLatestDatasetId()
        }

        let metadata = DatasetMetadata(
            datasetId: resolvedDatasetId,
            cachedAt: Date()
        )

        let cachedData = CachedData(metadata: metadata, data: value)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(cachedData)

        let fileURL = try fileURL(for: key)
        try data.write(to: fileURL, options: .atomic)
    }
}
