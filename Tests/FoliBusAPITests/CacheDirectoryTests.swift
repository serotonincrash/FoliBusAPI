import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Cache directory configuration")
struct CacheDirectoryTests {
    private static let routesPayload = #"""
    [{"route_id":"25","agency_id":"2","route_short_name":"L14","route_long_name":"Loukinainen-Avanti","route_desc":"","route_type":3,"route_url":"","route_color":"000000","route_text_color":"ffffff"}]
    """#.data(using: .utf8)!

    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "FoliBusAPITests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    @Test("client writes its cache into the supplied directory")
    func writesIntoSuppliedDirectory() async throws {
        let directory = tempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let transport = MockTransport { request in
            if request.url?.path.hasSuffix("/v0") == true {
                return try makeJSONResponse(for: request, jsonObject: ["latest": "dataset-1", "datasets": ["dataset-1"]])
            }
            return try makeDataResponse(for: request, data: Self.routesPayload)
        }
        let client = try FoliClient(transport: transport, cacheBehavior: .cachedOrFetch, cacheDirectory: directory)

        _ = try await client.fetchRoutes()

        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        #expect(!files.isEmpty, "cache files must be written to the supplied directory")
    }

    @Test("provider with an unusable directory exposes the error and works without cache")
    func providerFallsBackAndReportsError() async throws {
        let blocker = FileManager.default.temporaryDirectory
            .appending(path: "FoliBusAPITests-file-\(UUID().uuidString)")
        try Data("x".utf8).write(to: blocker)
        defer { try? FileManager.default.removeItem(at: blocker) }

        let provider = DefaultFoliClientProvider(
            configuration: FoliClientConfiguration(cacheDirectory: blocker.appending(path: "cache", directoryHint: .isDirectory))
        )

        #expect(provider.cacheInitializationError != nil)
        #expect(await provider.client().cacheBehavior == .noCache)
    }

    @Test("provider with a usable directory reports no error")
    func providerWithUsableDirectory() {
        let directory = tempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let provider = DefaultFoliClientProvider(configuration: FoliClientConfiguration(cacheDirectory: directory))
        #expect(provider.cacheInitializationError == nil)
    }
}
