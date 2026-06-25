import Foundation

extension Foli.DiskCache {
    internal struct DatasetMetadata: Codable {
        let datasetId: String
        let cachedAt: Date
    }

    internal struct GTFSInfoResponse: Codable {
        let latest: String
        let datasets: [String]

        enum CodingKeys: String, CodingKey {
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
        let decoder = JSONDecoder()

        let cachedData: any Codable
        switch type {
        case .routes:
            cachedData = try decoder.decode(CachedData<[Foli.Route]>.self, from: data)
        case .stops:
            cachedData = try decoder.decode(CachedData<[Foli.Stop]>.self, from: data)
        case .trips, .tripsForRoute:
            cachedData = try decoder.decode(CachedData<[Foli.Trip]>.self, from: data)
        case .stopTimes, .stopTimesForTrip, .stopTimesForStop:
            cachedData = try decoder.decode(CachedData<[Foli.StopTime]>.self, from: data)
        case .calendarDates:
            cachedData = try decoder.decode(CachedData<[Foli.CalendarDate]>.self, from: data)
        case .agencies:
            cachedData = try decoder.decode(CachedData<[Foli.Agency]>.self, from: data)
        case .calendars:
            cachedData = try decoder.decode(CachedData<[Foli.Calendar]>.self, from: data)
        case .shapeRouteIds:
            cachedData = try decoder.decode(CachedData<[String]>.self, from: data)
        case .shapePointsForShape:
            cachedData = try decoder.decode(CachedData<[Foli.ShapePoint]>.self, from: data)
        case .geoJSONLayers:
            cachedData = try decoder.decode(CachedData<[Foli.GeoJSONLayer]>.self, from: data)
        case .geoJSONPOI, .geoJSONPOICategory, .geoJSONBounds:
            cachedData = try decoder.decode(CachedData<Foli.FeatureCollection>.self, from: data)
        }

        let oldMetadata: DatasetMetadata
        let newData: any Codable

        switch cachedData {
        case let cached as CachedData<[Foli.Route]>:
            oldMetadata = cached.metadata
            newData = CachedData(metadata: DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date()), data: cached.data)
        case let cached as CachedData<[Foli.Stop]>:
            oldMetadata = cached.metadata
            newData = CachedData(metadata: DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date()), data: cached.data)
        case let cached as CachedData<[Foli.Trip]>:
            oldMetadata = cached.metadata
            newData = CachedData(metadata: DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date()), data: cached.data)
        case let cached as CachedData<[Foli.StopTime]>:
            oldMetadata = cached.metadata
            newData = CachedData(metadata: DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date()), data: cached.data)
        case let cached as CachedData<[Foli.CalendarDate]>:
            oldMetadata = cached.metadata
            newData = CachedData(metadata: DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date()), data: cached.data)
        case let cached as CachedData<[Foli.Agency]>:
            oldMetadata = cached.metadata
            newData = CachedData(metadata: DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date()), data: cached.data)
        case let cached as CachedData<[Foli.Calendar]>:
            oldMetadata = cached.metadata
            newData = CachedData(metadata: DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date()), data: cached.data)
        case let cached as CachedData<[String]>:
            oldMetadata = cached.metadata
            newData = CachedData(metadata: DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date()), data: cached.data)
        case let cached as CachedData<[Foli.ShapePoint]>:
            oldMetadata = cached.metadata
            newData = CachedData(metadata: DatasetMetadata(datasetId: oldMetadata.datasetId, cachedAt: Date()), data: cached.data)
        default:
            return
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let updatedData = try encoder.encode(newData)
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
