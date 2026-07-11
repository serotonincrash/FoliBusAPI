import Foundation
import Testing
@testable import FoliBusAPI

@Suite("DiskCache Corruption Tests")
struct DiskCacheCorruptionTests {
    private func makeRoute() throws -> Foli.Route {
        let json = """
        {
          "route_id": "1",
          "agency_id": "FOLI",
          "route_short_name": "1",
          "route_long_name": "Satama - Lentoasema",
          "route_type": 3
        }
        """.data(using: .utf8)!
        return try JSONDecoder().decode(Foli.Route.self, from: json)
    }

    @Test("garbage bytes load as a miss and the file is removed")
    func garbageBytesAreSelfHealingMiss() async throws {
        let (cache, directory) = try makeTemporaryDiskCache()
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = try await cache.fileURL(for: .routes)
        try Data("not json".utf8).write(to: fileURL)

        let loaded = try await cache.loadResource([Foli.Route].self, forKey: .routes)
        #expect(loaded == nil)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path), "poisoned entry should be deleted")
    }

    @Test("schema-evolved payload loads as a miss and the file is removed")
    func schemaEvolvedPayloadIsSelfHealingMiss() async throws {
        let (cache, directory) = try makeTemporaryDiskCache()
        defer { try? FileManager.default.removeItem(at: directory) }

        // Valid JSON with an intact, fresh metadata block but a payload that no longer
        // decodes as [Foli.Route] — the case where hasValidCache says true while loads throw.
        let fileURL = try await cache.fileURL(for: .routes)
        let json = """
        {
          "metadata": {
            "datasetId": "test-dataset",
            "cachedAt": \(Date().timeIntervalSinceReferenceDate)
          },
          "data": { "unexpected": "shape" }
        }
        """
        try Data(json.utf8).write(to: fileURL)
        #expect(await cache.hasValidCache(for: .routes))

        let loaded = try await cache.loadResource([Foli.Route].self, forKey: .routes)
        #expect(loaded == nil)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path), "poisoned entry should be deleted")
    }

    @Test("stale-path load treats corrupt entries the same way")
    func staleLoadIsSelfHealingMiss() async throws {
        let (cache, directory) = try makeTemporaryDiskCache()
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = try await cache.fileURL(for: .routes)
        try Data("{]".utf8).write(to: fileURL)

        let loaded = try await cache.loadStaleResource([Foli.Route].self, forKey: .routes)
        #expect(loaded == nil)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test("well-formed entries still load and are not deleted")
    func wellFormedEntrySurvives() async throws {
        let (cache, directory) = try makeTemporaryDiskCache()
        defer { try? FileManager.default.removeItem(at: directory) }

        let route = try makeRoute()
        let cachedData = Foli.DiskCache.CachedData(
            metadata: Foli.DiskCache.DatasetMetadata(datasetId: "test-dataset", cachedAt: Date()),
            data: [route]
        )
        let fileURL = try await cache.fileURL(for: .routes)
        try JSONEncoder().encode(cachedData).write(to: fileURL)

        let loaded = try await cache.loadResource([Foli.Route].self, forKey: .routes)
        #expect(loaded == [route])
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }
}
