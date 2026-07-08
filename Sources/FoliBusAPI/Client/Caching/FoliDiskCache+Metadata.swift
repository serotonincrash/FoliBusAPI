import Foundation

extension Foli.DiskCache {
    internal struct DatasetMetadata: Codable {
        let datasetId: String
        let cachedAt: Date
    }

    internal struct GTFSInfoResponse: Codable {
        let latest: String
        let datasets: [String]

        private enum CodingKeys: String, CodingKey {
            case latest
            case datasets
        }
    }

    internal struct CachedData<T: Codable>: Codable {
        let metadata: DatasetMetadata
        let data: T
    }

    internal func loadMetadata(for type: Foli.Resource) async throws -> DatasetMetadata? {
        let fileURL = try fileURL(for: type)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let metadataDict = json["metadata"] as? [String: Any],
           let metadataData = try? JSONSerialization.data(withJSONObject: metadataDict) {
            return try JSONDecoder().decode(DatasetMetadata.self, from: metadataData)
        }

        return nil
    }

    internal func refreshMetadataTimestamp(for type: Foli.Resource) async throws {
        let fileURL = try fileURL(for: type)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        let data = try Data(contentsOf: fileURL)
        guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var metadata = json["metadata"] as? [String: Any] else { return }

        // Update only the cachedAt timestamp; keep datasetId unchanged.
        // JSONEncoder encodes Date as Double (timeIntervalSinceReferenceDate).
        // Using the same representation here ensures JSONDecoder compatibility.
        metadata["cachedAt"] = Date().timeIntervalSinceReferenceDate
        json["metadata"] = metadata

        let updatedData = try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys, .prettyPrinted])
        try updatedData.write(to: fileURL, options: .atomic)
    }

    internal func loadMostRecentDatasetId() async throws -> String? {
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        )

        var mostRecentDatasetId: String?
        var mostRecentDate: Date?

        for url in contents {
            guard url.pathExtension == "json" else { continue }

            do {
                let metadata = try await loadMetadataFromURL(url)

                if mostRecentDate == nil || metadata.cachedAt > mostRecentDate! {
                    mostRecentDate = metadata.cachedAt
                    mostRecentDatasetId = metadata.datasetId
                }
            } catch {
                continue
            }
        }

        return mostRecentDatasetId
    }

    internal func loadMetadataFromURL(_ url: URL) async throws -> DatasetMetadata {
        let data = try Data(contentsOf: url)

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let metadataDict = json["metadata"] as? [String: Any],
           let metadataData = try? JSONSerialization.data(withJSONObject: metadataDict) {
            return try JSONDecoder().decode(DatasetMetadata.self, from: metadataData)
        }

        throw Foli.APIError.decodingError(CodingError.invalidMetadata)
    }

    internal enum CodingError: Error {
        case invalidMetadata
    }

    internal func isMetadataFresh(_ metadata: DatasetMetadata) -> Bool {
        let age = Date().timeIntervalSince(metadata.cachedAt)
        return age <= timeoutDuration.validityDuration
    }
}
