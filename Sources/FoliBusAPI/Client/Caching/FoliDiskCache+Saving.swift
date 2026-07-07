import Foundation

extension Foli.DiskCache {
    internal func saveResource<T: Codable & Sendable>(_ value: T, forKey key: Foli.Resource) async throws {
        let datasetId = try await fetchLatestDatasetId()

        let metadata = DatasetMetadata(
            datasetId: datasetId,
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
