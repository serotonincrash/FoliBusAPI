import Foundation

extension Foli {
    /// File-based cache implementation for GTFS data.
    ///
    /// DiskCache is the package's internal default cache implementation. It stores
    /// serialized data under the app support directory and uses actor isolation to keep
    /// file-system operations safe across concurrent access.
    actor DiskCache: Foli.Cache {
        internal let fileManager: FileManager
        internal let cacheDirectory: URL
        let timeoutDuration: Foli.CacheTTL

        /// Fetches the latest dataset ID for save-tagging and revalidation.
        ///
        /// Injected by ``FoliClient`` so that all cache network traffic flows through
        /// the client's ``FoliTransport`` — the cache itself performs no networking.
        internal let datasetIdFetcher: @Sendable () async throws -> String

        /// Creates a disk-backed cache.
        /// - Parameters:
        ///   - timeout: The freshness policy applied to cached resources.
        ///   - fileManager: The file manager used to create and access cache files.
        ///   - directory: The directory to store cache files in. Pass `nil` (the default)
        ///     to use the standard application-support location; tests pass a temporary
        ///     directory for isolation.
        ///   - datasetIdFetcher: Returns the latest dataset ID, routed through the
        ///     owning client's transport.
        init(
            timeout: Foli.CacheTTL = .default,
            fileManager: FileManager = .default,
            directory: URL? = nil,
            datasetIdFetcher: @escaping @Sendable () async throws -> String
        ) throws {
            self.timeoutDuration = timeout
            self.fileManager = fileManager
            self.datasetIdFetcher = datasetIdFetcher

            if let directory {
                self.cacheDirectory = directory
            } else {
                let appSupportURL = try fileManager.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )

                self.cacheDirectory = appSupportURL
                    .appendingPathComponent("FoliBusAPI", isDirectory: true)
                    .appendingPathComponent("Cache", isDirectory: true)
            }

            try fileManager.createDirectory(
                at: self.cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
