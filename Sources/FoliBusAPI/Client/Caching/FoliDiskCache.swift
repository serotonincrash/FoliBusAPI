import Foundation

public extension Foli {
    /// File-based cache implementation for GTFS data
    ///
    /// Uses actor isolation to ensure thread-safe file operations.
    /// All methods are async to perform file I/O without blocking.
    actor DiskCache: Foli.Cache {
        internal let fileManager: FileManager
        internal let cacheDirectory: URL
        public let timeoutDuration: Foli.CacheTimeout
        internal let baseURL: String = "https://data.foli.fi/gtfs/v0"
        internal let session: URLSession

        public init(
            timeout: Foli.CacheTimeout = .default,
            fileManager: FileManager = .default
        ) throws {
            self.timeoutDuration = timeout
            self.fileManager = fileManager
            self.session = URLSession.shared

            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            self.cacheDirectory = appSupportURL
                .appendingPathComponent("FoliBusAPI", isDirectory: true)
                .appendingPathComponent("Cache", isDirectory: true)

            try fileManager.createDirectory(
                at: self.cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
