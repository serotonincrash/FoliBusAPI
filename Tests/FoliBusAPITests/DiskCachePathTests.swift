import Foundation
import Testing
@testable import FoliBusAPI

@Suite("DiskCache Path Tests")
struct DiskCachePathTests {
    @Test("resource IDs cannot escape the cache directory")
    func resourceIdsCannotEscapeCacheDirectory() async throws {
        let cache = try Foli.DiskCache()
        let cacheDirectory = await cache.cacheDirectory.standardizedFileURL.path

        let hostileResources: [Foli.Resource] = [
            .tripsForRoute("../../Preferences/victim"),
            .stopTimesForTrip("/etc/passwd"),
            .stopTimesForStop("..\\..\\windows"),
            .shapePointsForShape("a/b/c"),
            .geoJSONPOICategory("../escape"),
        ]

        for resource in hostileResources {
            let url = try await cache.fileURL(for: resource)
            let resolvedPath = url.standardizedFileURL.path
            #expect(resolvedPath.hasPrefix(cacheDirectory + "/"), "\(resource) resolved outside the cache directory: \(resolvedPath)")
            #expect(!url.lastPathComponent.contains("/"))
        }
    }

    @Test("distinct resource keys map to distinct filenames")
    func distinctResourceKeysMapToDistinctFilenames() async throws {
        let cache = try Foli.DiskCache()

        let first = try await cache.fileURL(for: .geoJSONBounds(resolution: "a_b", format: "c"))
        let second = try await cache.fileURL(for: .geoJSONBounds(resolution: "a", format: "b_c"))
        #expect(first != second)

        let plain = try await cache.fileURL(for: .tripsForRoute("1"))
        let alsoPlain = try await cache.fileURL(for: .tripsForRoute("1"))
        #expect(plain == alsoPlain)
        #expect(plain.lastPathComponent == "trips_route_1.json")
    }
}
